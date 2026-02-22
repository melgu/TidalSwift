// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TidalSwiftLib",
	platforms: [
		.macOS(.v13),
		.iOS(.v16)
	],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "TidalSwiftLib",
            targets: ["TidalSwiftLib"]
        ),
    ],
	dependencies: [
		.package(url: "git@github.com:NCrusher74/SwiftTagger.git", from: "1.7.0"),
	],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "TidalSwiftLib",
			dependencies: ["SwiftTagger"]
        ),

    ]
)
