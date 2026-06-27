// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "PilotFamilyKit",
    defaultLocalization: "de",
    platforms: [.iOS(.v17), .macCatalyst(.v17)],
    products: [
        .library(name: "PilotFamilyKit", targets: ["PilotFamilyKit"]),
    ],
    targets: [
        .target(name: "PilotFamilyKit"),
    ]
)
