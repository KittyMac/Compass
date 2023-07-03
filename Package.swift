// swift-tools-version:5.3.0

import PackageDescription

let package = Package(
    name: "Compass",
    products: [
        .library(name: "Compass", targets: ["Compass"]),
    ],
    dependencies: [
        .package(url: "https://github.com/KittyMac/Chronometer.git", from: "0.1.0"),
        .package(url: "https://github.com/KittyMac/Hitch.git", from: "0.4.0"),
        .package(url: "https://github.com/KittyMac/Spanker.git", from: "0.2.0"),
    ],
    targets: [
        .target(
            name: "Compass",
            dependencies: [
                "Hitch",
                "Spanker",
                "Chronometer"
            ]),
        .testTarget(
            name: "CompassTests",
            dependencies: ["Compass"]),
    ]
)
