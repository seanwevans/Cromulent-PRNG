// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "cromulent",
    targets: [
        .executableTarget(
            name: "cromulent",
            path: "Sources/cromulent"
        )
    ]
)
