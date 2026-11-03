// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Swift6CallbackCrash",
    platforms: [.macOS(.v14)],
    targets: [
        .target(name: "OldAPI"),                          // Objective-C, like Apple's older frameworks
        .target(name: "Demo", dependencies: ["OldAPI"]),  // Swift 6 language mode
        .testTarget(name: "DemoTests", dependencies: ["Demo", "OldAPI"]),
    ]
)
