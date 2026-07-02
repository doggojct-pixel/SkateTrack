// [自主區] iOS/Core/SensorEngine/LocalTangentPlane.swift
// 用途：提供 b17-A replay-only IMU gap interpolation 的局部 ENU 公尺座標轉換基礎。
// 委派至：DeadReckoningEngine replay analysis 與後續 closure diagnostics。

import Foundation

struct LocalTangentMeters: Codable, Sendable, Equatable {
    let eastMeters: Double
    let northMeters: Double

    init(eastMeters: Double, northMeters: Double) {
        self.eastMeters = eastMeters
        self.northMeters = northMeters
    }
}

struct LocalTangentPlane: Sendable, Equatable {
    private static let earthRadiusMeters = 6_378_137.0

    let anchorCoordinate: GeoCoordinate
    private let anchorLatitudeRadians: Double
    private let anchorLongitudeRadians: Double
    private let anchorCosineLatitude: Double

    init(anchorCoordinate: GeoCoordinate) {
        self.anchorCoordinate = anchorCoordinate
        self.anchorLatitudeRadians = Self.radians(fromDegrees: anchorCoordinate.latitude)
        self.anchorLongitudeRadians = Self.radians(fromDegrees: anchorCoordinate.longitude)
        self.anchorCosineLatitude = max(0.000_001, cos(anchorLatitudeRadians))
    }

    func localMeters(for coordinate: GeoCoordinate) -> LocalTangentMeters {
        let latitudeRadians = Self.radians(fromDegrees: coordinate.latitude)
        let longitudeRadians = Self.radians(fromDegrees: coordinate.longitude)
        let eastMeters = (longitudeRadians - anchorLongitudeRadians) * anchorCosineLatitude * Self.earthRadiusMeters
        let northMeters = (latitudeRadians - anchorLatitudeRadians) * Self.earthRadiusMeters
        return LocalTangentMeters(eastMeters: eastMeters, northMeters: northMeters)
    }

    func coordinate(for localMeters: LocalTangentMeters) -> GeoCoordinate {
        let latitudeRadians = anchorLatitudeRadians + localMeters.northMeters / Self.earthRadiusMeters
        let longitudeRadians = anchorLongitudeRadians + localMeters.eastMeters / (anchorCosineLatitude * Self.earthRadiusMeters)
        return GeoCoordinate(
            latitude: Self.degrees(fromRadians: latitudeRadians),
            longitude: Self.degrees(fromRadians: longitudeRadians)
        )
    }

    func coordinate(eastMeters: Double, northMeters: Double) -> GeoCoordinate {
        coordinate(for: LocalTangentMeters(eastMeters: eastMeters, northMeters: northMeters))
    }

    private static func radians(fromDegrees degrees: Double) -> Double {
        degrees * .pi / 180
    }

    private static func degrees(fromRadians radians: Double) -> Double {
        radians * 180 / .pi
    }
}
