// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "terminal-widgets",
    platforms: [.macOS(.v15)],
    products: [
        .executable(
            name: "run-terminal-widgets",
            targets: ["RunTerminalWidgets"],
        ),
        .library(
            name: "TerminalWidgets",
            targets: ["TerminalWidgets"],
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/juri/terminal-ansi.git", from: "0.3.0"),
        .package(url: "https://github.com/juri/terminal-styles.git", from: "0.2.2"),
    ],
    targets: [
        .executableTarget(
            name: "RunTerminalWidgets",
            dependencies: [
                "TerminalWidgets",
                .product(name: "TerminalANSI", package: "terminal-ansi"),
                .product(name: "TerminalStyles", package: "terminal-styles"),
            ],
        ),
        .target(
            name: "TerminalWidgets",
            dependencies: [
                .product(name: "TerminalANSI", package: "terminal-ansi"),
                .product(name: "TerminalStyles", package: "terminal-styles"),
            ],
        ),
        .testTarget(
            name: "TerminalWidgetsTests",
            dependencies: ["TerminalWidgets"],
        ),
    ]
)
