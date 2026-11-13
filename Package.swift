// swift-tools-version: 5.6

import PackageDescription

let package = Package(
    name: "Organisationsnummer",
    products: [
        .library(name: "Organisationsnummer", targets: ["Organisationsnummer"]),
    ],
    dependencies: [
        .package(url: "https://github.com/personnummer/swift.git", branch: "main"),
    ],
    targets: [
        .target(
            name: "Organisationsnummer",
            dependencies: [
                .product(name: "Personnummer", package: "swift"),
            ],
            path: "source"
        ),
        .testTarget(
            name: "OrganisationsnummerTests",
            dependencies: ["Organisationsnummer"],
            path: "Tests/OrganisationsnummerTests"
        ),
    ]
)
