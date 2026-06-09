// [協作區] Shared/Models/MotionSample.swift
// 用途：定義 GPS、速度、加速度、陀螺儀與高度的單筆跨平台感測樣本。
// 委派至：SensorProvider、session recording、fall detection 與後續分析引擎。

import Foundation

struct GeoCoordinate: Codable, Sendable, Equatable {
    let latitude: Double
    let longitude: Double

    init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
}

struct ThreeAxisValue: Codable, Sendable, Equatable {
    let x: Double
    let y: Double
    let z: Double

    init(x: Double, y: Double, z: Double) {
        self.x = x
        self.y = y
        self.z = z
    }
}

struct MotionSample: Identifiable, Codable, Sendable, Equatable {
    let id: UUID
    let timestamp: Date
    let gpsCoordinate: GeoCoordinate?
    let speedKmh: Double
    let accelerometerG: ThreeAxisValue
    let gyroscopeRadPS: ThreeAxisValue
    let altitudeMeters: Double?

    init(
        id: UUID = UUID(),
        timestamp: Date,
        gpsCoordinate: GeoCoordinate? = nil,
        speedKmh: Double,
        accelerometerG: ThreeAxisValue,
        gyroscopeRadPS: ThreeAxisValue,
        altitudeMeters: Double? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.gpsCoordinate = gpsCoordinate
        self.speedKmh = speedKmh
        self.accelerometerG = accelerometerG
        self.gyroscopeRadPS = gyroscopeRadPS
        self.altitudeMeters = altitudeMeters
    }
}
