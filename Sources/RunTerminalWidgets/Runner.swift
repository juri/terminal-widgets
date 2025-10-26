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
        ]

        for (index, spinner) in spinners.enumerated() {
            Task {
                for await spinnerFrame in spinner.run(style: style) {
                    draw(string: spinnerFrame, onLine: index, of: terminal)
                }
            }
        }

        try await Task.sleep(for: .seconds(5))
    }
}

@MainActor
private func draw(string: String, onLine line: Int, of terminal: Terminal) {
    terminal.writeCodes([
        ANSIControlCode.moveCursor(x: 0, y: line),
        ANSIControlCode.clearLine,
        .literal(string),
        .literal(" spinning!"),
    ])
}
