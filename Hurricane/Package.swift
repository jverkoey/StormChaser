// swift-tools-version: 5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "Hurricane",
  platforms: [
    .iOS(.v15),
    .macOS(.v12),
  ],
  products: [
    .executable(
      name: "Hurricane",
      targets: ["Hurricane"]),
    .library(
      name: "HurricaneDB",
      targets: ["HurricaneDB"]),
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
