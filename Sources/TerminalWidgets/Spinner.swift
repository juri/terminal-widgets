import TerminalANSI
public import TerminalStyles

public struct Spinner: Sendable {
    public var frames: [String]
    public var frequency: Duration

    public static let dot = Spinner(
        frames: ["⣾", "⣽", "⣻", "⢿", "⡿", "⣟", "⣯", "⣷"],
        frequency: .milliseconds(100),
    )

    public static let jump = Spinner(
        frames: ["⢄", "⢂", "⢁", "⡁", "⡈", "⡐", "⡠"],
        frequency: .milliseconds(100),
    )

    public static let line = Spinner(frames: ["|", "/", "–", #"\"#], frequency: .milliseconds(100))

    public static let miniDot = Spinner(
        frames: ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"],
        frequency: .milliseconds(100),
    )

    public static let pulse = Spinner(
        frames: ["█", "▓", "▒", "░", "▒", "▓"],
        frequency: .milliseconds(200),
    )

    public mutating func reverse() {
        self.frames.reverse()
    }

    public mutating func reversed() -> Spinner {
        var s = self
        s.reverse()
        return s
    }
}

extension Spinner {
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
