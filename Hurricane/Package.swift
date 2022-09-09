// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "Hurricane",
  platforms: [
    .iOS(.v16),
    .macOS(.v13),
  ],
  products: [
    .executable(
      name: "Hurricane",
      targets: ["Hurricane"]),
  ],
  dependencies: [
    .package(url: "https://github.com/stephencelis/SQLite.swift.git", from: "0.13.3")
  ],
  targets: [
    .executableTarget(
      name: "Hurricane",
      dependencies: [
        .product(name: "SQLite", package: "SQLite.swift"),
        .targetItem(name: "HurricaneDB", condition: nil),
        .targetItem(name: "iTunesXML", condition: nil),
      ]),
    .target(
      name: "HurricaneDB",
      dependencies: [
        .product(name: "SQLite", package: "SQLite.swift"),
      ]),
    .target(name: "iTunesXML"),
    .testTarget(
      name: "HurricaneTests",
      dependencies: ["Hurricane"]),
  ]
)
