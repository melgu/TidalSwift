// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TidalSwiftLib",
	platforms: [
		.macOS(.v14),
		.iOS(.v17)
	],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "TidalSwiftLib",
            targets: ["TidalSwiftLib"]
        ),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "TidalSwiftLib",
			swiftSettings: [
				.defaultIsolation(MainActor.self),
				.enableUpcomingFeature("DisableOutwardActorInference"),
				.enableUpcomingFeature("GlobalActorIsolatedTypesUsability"),
				.enableUpcomingFeature("InferIsolatedConformances"),
				.enableUpcomingFeature("InferSendableFromCaptures"),
				.enableUpcomingFeature("NonisolatedNonsendingByDefault")
			]
		),

    ]
)
