// swift-tools-version:5.1

import PackageDescription

let package = Package(name: "Colorful",
                      platforms: [.iOS(.v10)],
                      products: [.library(name: "Colorful",
                                          targets: ["Colorful"])],
                      targets: [.target(name: "Colorful",
                                        path: "Colorful")],
                      swiftLanguageVersions: [.v5])
