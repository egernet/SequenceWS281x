// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let argumentParser: Target.Dependency = .product(name: "ArgumentParser", package: "swift-argument-parser")

let plugins: [Target.PluginUsage]? = {
#if os(OSX)
    let swiftGenPlugin: Target.PluginUsage = .plugin(name: "SwiftLintPlugin", package: "SwiftLint")
    return [swiftGenPlugin]
#else
    return nil
#endif
}()

let platforms: [SupportedPlatform]? = {
#if os(OSX)
    return [.macOS(.v12)]
#else
    return nil
#endif
}()


let package = Package(
  name: "SequenceWS281x",
  platforms: platforms,
  products: [
    .executable(name: "SequenceWS281x", targets: ["SequenceWS281x"]),
    .library(name: "rpi-ws281x-swift", targets: ["rpi-ws281x-swift"]),
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.1.3"),
    .package(url: "https://github.com/realm/SwiftLint", from: "0.52.2")
  ],
  targets: [
    .target(
        name: "rpi-ws281x"
    ),
    .target(
        name: "rpi-ws281x-swift",
        dependencies: ["rpi-ws281x"],
        plugins: plugins
    ),

    .executableTarget(
        name: "SequenceWS281x",
        dependencies: [
            argumentParser,
            "rpi-ws281x-swift"
        ],
        plugins: plugins
    )
  ]
)
