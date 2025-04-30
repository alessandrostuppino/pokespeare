// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "Pokespeare",
	platforms: [.iOS(.v17)],
	products: [
		.library(name: "Pokespeare", targets: ["Pokespeare"]),
	],
	targets: [
		.target(
			name: "Pokespeare",
			dependencies: []
		),
		.testTarget(
			name: "PokespeareTests",
			dependencies: ["Pokespeare"]
		),
	]
)
