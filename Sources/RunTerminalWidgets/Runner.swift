//
//  Runner.swift
//
//  Created by Juri Pakaste on 26.10.2025.
//

import TerminalANSI
import TerminalStyles
import TerminalWidgets

@main
struct Runner {
    static func main() async throws {
        let style = Style(foreground: [.colorRGB(RGBColor8(hexString: "f00")!), .bold])
        let terminal = Terminal()!

        terminal.writeCodes([
            .clearScreen,
            .setCursorHidden(true),
        ])
        defer {
            terminal.writeCodes([
                .setCursorHidden(false)
            ])
        }

        let spinners: [Spinner] = [
            .line,
            .dot,
            .miniDot,
            .jump,
            .pulse,
            .points(length: 4),
        ]

        for (index, spinner) in spinners.enumerated() {
            Task {
                for await spinnerFrame in spinner.run(style: style) {
                    drawSpinner(string: spinnerFrame, onLine: index, of: terminal)
                }
            }
        }

        let progressLength = try terminal.size().width - 20
        let progressForegroundColor = RGBColor8(hexString: "#002")!
        let progressForeground = Style(foreground: [.colorRGB(progressForegroundColor)])
        let progressForegroundStyler = ConstantPerCharacterStyler(style: progressForeground)
        let progressFilledBackgroundStyler = HorizontalBackgroundPerCharacterStyler(
            linearGradientLength: progressLength,
            stops: [
                (0.0, RGBColor8(hexString: "#8080ff")!),
                (1.0, RGBColor8(hexString: "#80ff80")!),
            ],
        )!
        let progressUnfilledBackgroundStyler = ConstantPerCharacterStyler(
            style: Style(
                background: .colorRGB(RGBColor8(hexString: "#CCC")!),
            )
        )
        let progressFilledStyler = JoinedPerCharacterStyler(
            styler1: progressForegroundStyler,
            styler2: progressFilledBackgroundStyler,
        )
        let progressUnfilledStyler = JoinedPerCharacterStyler(
            styler1: progressForegroundStyler,
            styler2: progressUnfilledBackgroundStyler,
        )
        let progress = Progress(
            completeStyler: progressFilledStyler,
            incompleteStyler: progressUnfilledStyler,
            length: progressLength,
            totalUnitCount: 100,
        )
        Task {
            for await progressFrame in progress.stream {
                terminal.writeCodes([
                    ANSIControlCode.moveCursor(x: 10, y: 10),
                    .literal(progressFrame),
                ])
            }
        }

        Task {
            for i in 1...100 {
                progress.setState(completedUnitCount: i)
                try await Task.sleep(for: .milliseconds(75))
            }
        }

        try await Task.sleep(for: .seconds(10))
    }
}

@MainActor
private func drawSpinner(string: String, onLine line: Int, of terminal: Terminal) {
    terminal.writeCodes([
        ANSIControlCode.moveCursor(x: 0, y: line),
        ANSIControlCode.clearLine,
        .literal(string),
        .literal(" spinning!"),
    ])
}
