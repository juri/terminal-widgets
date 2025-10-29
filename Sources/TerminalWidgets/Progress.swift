//
//  Progress.swift
//
//  Created by Juri Pakaste on 27.10.2025.
//

import Synchronization
import TerminalStyles

public final class Progress<
    CompleteStyler: PerCharacterStyler & Sendable,
    IncompleteStyler: PerCharacterStyler & Sendable
>: Sendable {
    private struct State {
        var completedUnitCount: Int
        var length: Int
        var needsUpdate: Bool
        var totalUnitCount: Int

        var fillLength: Int {
            Int(Double(self.completedUnitCount) / Double(self.totalUnitCount) * Double(self.length))
        }

        var percentage: Int {
            Int(Double(self.completedUnitCount) / Double(self.totalUnitCount) * 100.0)
        }
    }

    private let continuation: AsyncStream<String>.Continuation
    private let state: Mutex<State>

    public let stream: AsyncStream<String>

    let completeStyler: CompleteStyler
    let incompleteStyler: IncompleteStyler

    public init(
        completeStyler: CompleteStyler,
        incompleteStyler: IncompleteStyler,
        length: Int,
        totalUnitCount: Int,
    ) {
        self.completeStyler = completeStyler
        self.incompleteStyler = incompleteStyler
        self.state = Mutex(
            State(
                completedUnitCount: 0,
                length: length,
                needsUpdate: false,
                totalUnitCount: totalUnitCount,
            )
        )

        let (stream, continuation) = AsyncStream<String>.makeStream()
        self.stream = stream
        self.continuation = continuation
    }

    public func setState(
        completedUnitCount: Int? = nil,
        length: Int? = nil,
        totalUnitCount: Int? = nil,
    ) {
        guard completedUnitCount != nil || length != nil || totalUnitCount != nil else { return }

        self.setNeedsUpdate(
            completedUnitCount: completedUnitCount,
            length: length,
            totalUnitCount: totalUnitCount,
        )
    }

    private func setNeedsUpdate(
        completedUnitCount: Int? = nil,
        length: Int? = nil,
        totalUnitCount: Int? = nil,
    ) {
        let changed = self.state.withLock {
            var changed = false
            let oldFillLength = $0.fillLength
            let oldPercentage = $0.percentage

            if let completedUnitCount {
                changed = changed || $0.completedUnitCount != completedUnitCount
                $0.completedUnitCount = completedUnitCount
            }
            if let length {
                changed = changed || $0.length != length
                $0.length = length
            }
            if let totalUnitCount {
                changed = changed || $0.totalUnitCount != totalUnitCount
                $0.totalUnitCount = totalUnitCount
            }

            changed = changed || oldFillLength != $0.fillLength || oldPercentage != $0.percentage
            $0.needsUpdate = changed
            return changed
        }
        guard changed else { return }
        Task {
            let (needsUpdate, state) = self.state.withLock {
                let needsUpdate = $0.needsUpdate
                $0.needsUpdate = false
                return (needsUpdate, $0)
            }
            guard needsUpdate else { return }
            self.update(state: state)
        }
    }

    private func update(state: State) {
        let percentageString = state.percentage.formatted(.percent)

        let totalPadding = state.length - percentageString.count
        let frontPadding = String(repeating: " ", count: totalPadding / 2)
        let backPadding = String(repeating: " ", count: totalPadding / 2 + totalPadding % 2)

        let fullString = frontPadding + percentageString + backPadding

        let filledIndex = fullString.index(fullString.startIndex, offsetBy: state.fillLength)
        let filledString = fullString[..<filledIndex]
        let unfilledString = fullString[filledIndex...]

        let styledFilled = self.completeStyler.apply(line: filledString, lineIndex: 0, addNewline: false, reset: false)
        let styledUnfilled = self.incompleteStyler.apply(line: unfilledString, lineIndex: 0)

        self.continuation.yield(styledFilled + styledUnfilled)
    }
}
