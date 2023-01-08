// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "SequenceWS281x",
  products: [
    .executable(name: "SequenceWS281x", targets: ["SequenceWS281x"]),
    .library(name: "rpi-ws281x-swift", targets: ["rpi-ws281x-swift"])
  ],
  dependencies: [
  ],
  targets: [
    .target(name: "rpi-ws281x", path: "Sources/rpi-ws281x"),
    .target(name: "rpi-ws281x-swift", dependencies: ["rpi-ws281x"], path: "Sources/rpi-ws281x-swift"),

    .executableTarget(name: "SequenceWS281x", dependencies: ["rpi-ws281x-swift"], path: "Sources/SequenceWS281x")
  ]
)
