// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Swift6CallbackCrash",
    platforms: [.macOS(.v14)],
    targets: [
        .target(name: "OldAPI"),                                         // Objective-C, like Apple's older frameworks
        .target(name: "Old5", swiftSettings: [.swiftLanguageMode(.v5)]), // A Swift library built in Swift 5 mode
        .target(name: "New6"),                                           // A Swift library built in Swift 6 mode
        .target(name: "Demo", dependencies: ["OldAPI", "Old5", "New6"]),
        .testTarget(name: "DemoTests", dependencies: ["Demo", "OldAPI"]),
    ]
)
