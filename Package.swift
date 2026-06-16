// swift-tools-version: 6.4
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Inverso",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .executable(name: "inverso", targets: ["Inverso"]),
        .library(name: "InversoKit", targets: ["InversoKit"]),
    ],
    targets: [
        .target(name: "InversoKit"),
        .executableTarget(
            name: "Inverso",
            dependencies: ["InversoKit"]
        ),
        .testTarget(
            name: "InversoKitTests",
            dependencies: ["InversoKit"]
        ),
    ],
    swiftLanguageModes: [.v5]
)
