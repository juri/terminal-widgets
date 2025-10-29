import TerminalANSI
public import TerminalStyles

/// Spinner is an indeterminate progress indicator.
///
/// Spinner fires off strings via an `AsyncStream` at a constant rate until its cancelled. There are a few different
/// ready-made variations or you can define your own.
public struct Spinner: Sendable {
    /// Frames of the spinner.
    ///
    /// This is a list of strings that is looped through as long as the spinner runs.
    public var frames: [String]

    /// Frequency of updates to the stream.
    public var frequency: Duration

    /// `dot` is a spinner consisting of characters `⣾`, `⣽`, `⣻`, `⢿`, `⡿`, `⣟`, `⣯`, and `⣷`.
    public static let dot = Spinner(
        frames: ["⣾", "⣽", "⣻", "⢿", "⡿", "⣟", "⣯", "⣷"],
        frequency: .milliseconds(100),
    )

    /// `jump` is a spinner consisting of characters `⢄`, `⢂`, `⢁`, `⡁`, `⡈`, `⡐`, and `⡠`.
    public static let jump = Spinner(
        frames: ["⢄", "⢂", "⢁", "⡁", "⡈", "⡐", "⡠"],
        frequency: .milliseconds(100),
    )

    /// `line` is a spinner consisting of characters `|`, `/`, `-`, and `\`.
    public static let line = Spinner(frames: ["|", "/", "–", #"\"#], frequency: .milliseconds(100))

    /// `miniDot` is a spinner consisting of characters `⠋`, `⠙`, `⠹`, `⠸`, `⠼`, `⠴`, `⠦`, `⠧`, `⠇`, and `⠏`.
    public static let miniDot = Spinner(
        frames: ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"],
        frequency: .milliseconds(100),
    )

    /// `points` creates a spinner where an "on" point moves through a sequence of "off" points.
    public static func points(length: Int, off: String = "∙", on: String = "●") -> Spinner {
        precondition(length > 0)
        let empty = String(repeating: off, count: length)
        let rest = (0..<length).map { pos in
            String(repeating: off, count: pos) + on + String(repeating: off, count: length - 1 - pos)
        }

        return Spinner(
            frames: [empty] + rest,
            frequency: .milliseconds(300),
        )
    }

    /// `miniDot` is a spinner consisting of characters `█`, `▓`, `▒`, `░`, `▒`, and `▓`.
    public static let pulse = Spinner(
        frames: ["█", "▓", "▒", "░", "▒", "▓"],
        frequency: .milliseconds(200),
    )

    /// `reverse` reverses the spinner.
    ///
    /// - SeeAlso: ``reversed()``
    public mutating func reverse() {
        self.frames.reverse()
    }

    /// `reversed` returns the spinner reversed.
    /// - SeeAlso: ``reverse()``
    public mutating func reversed() -> Spinner {
        var s = self
        s.reverse()
        return s
    }
}

extension Spinner {
    /// Run the spinner, applying `style` to the generated strings.
    public func run(style: Style) -> AsyncStream<String> {
        let (stream, continuation) = AsyncStream<String>.makeStream()
        let task = Task {
            var frameIndex = 0
            let frameCount = self.frames.count
            while true {
                try Task.checkCancellation()
                try await Task.sleep(for: self.frequency)
                let frame = self.frames[frameIndex % frameCount]
                frameIndex &+= 1

                continuation.yield(style.apply(to: frame))
            }
        }
        continuation.onTermination = { @Sendable _ in
            task.cancel()
        }
        return stream
    }
}
