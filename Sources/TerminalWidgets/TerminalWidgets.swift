import TerminalANSI
public import TerminalStyles

public struct Spinner: Sendable {
    public let frames: [String]
    public let frequency: Duration

    public static let line = Spinner(frames: ["|", "/", "–", #"\"#], frequency: .milliseconds(100))
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
