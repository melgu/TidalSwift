// swift-tools-version: 6.2

import PackageDescription

let package = Package(
	name: "TidalSwiftCLI",
	platforms: [
		.macOS(.v14)
	],
	products: [
		.executable(name: "tidal", targets: ["tidal"])
	],
	dependencies: [
		.package(path: "../TidalSwiftLib"),
		.package(url: "https://github.com/apple/swift-argument-parser", from: "1.5.0")
	],
	targets: [
		.executableTarget(
			name: "tidal",
			dependencies: [
				.product(name: "TidalSwiftLib", package: "TidalSwiftLib"),
				.product(name: "ArgumentParser", package: "swift-argument-parser")
			],
			swiftSettings: [
				.enableUpcomingFeature("InferIsolatedConformances"),
				.enableUpcomingFeature("NonisolatedNonsendingByDefault")
			]
		)
	]
)
