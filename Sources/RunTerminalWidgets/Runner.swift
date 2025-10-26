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
        let spinner = Spinner.line
        let style = Style(foreground: [.colorRGB(RGBColor8(hexString: "f00")!), .bold])
        let terminal = Terminal()!
        for await spinnerFrame in spinner.run(style: style) {
            terminal.writeCodes([
                ANSIControlCode.clearLine,
                ANSIControlCode.moveCursorToColumn(n: 0),
                .literal(spinnerFrame),
                .literal(" spinning!"),
            ])
        }
    }
}
