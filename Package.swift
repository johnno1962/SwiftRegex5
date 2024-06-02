// swift-tools-version:5.0
//
//  Created by John Holdsworth on 26/11/2017.
//

import PackageDescription

let package = Package(
    name: "SwiftRegex",
    platforms: [.macOS("10.10"), .iOS("10.0"), .tvOS("10.0")],
    products: [
        .library(name: "SwiftRegex", targets: ["SwiftRegex"]),
        .library(name: "SwiftRegexD", targets: ["SwiftRegexD"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "SwiftRegex"),
        .target(
            name: "SwiftRegexD",
            swiftSettings: [.define("DEBUG_ONLY")]),
        .testTarget(name: "SwiftRegexTests", dependencies: [
            "SwiftRegex"], path: "SwiftRegex5Tests/"),
    ]
)
