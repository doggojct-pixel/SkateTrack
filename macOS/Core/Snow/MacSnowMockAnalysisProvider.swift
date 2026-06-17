// [協作區] MacSnowMockAnalysisProvider.swift
// 用途：提供 macOS Snow viewer DEBUG-only fixture，不代表 package schema 或正式匯入資料。
// 委派至：MacSnowAnalysisViewModel DEBUG preview；Release 不可注入此 provider。

import Foundation

#if DEBUG
enum MacSnowMockScenario: String, CaseIterable, Identifiable, Sendable {
    case resortDay
    case limitedAltitude
    case packagePending

    var id: String { rawValue }
}

enum MacSnowMockAnalysisProvider {
    static func makeAvailability(
        scenario: MacSnowMockScenario = .resortDay
    ) -> MacSnowAnalysisAvailability {
        switch scenario {
        case .resortDay:
            return .available(makeResortDay(limitedAltitude: false))
        case .limitedAltitude:
            return .available(makeResortDay(limitedAltitude: true))
        case .packagePending:
            return .packageSchemaPending
        }
    }

    private static func makeResortDay(limitedAltitude: Bool) -> MacSnowSessionAnalysis {
        let sessionID = UUID(uuidString: "00000000-0000-0000-0000-000000070701")!
        let run1ID = UUID(uuidString: "00000000-0000-0000-0000-000000070711")!
        let run2ID = UUID(uuidString: "00000000-0000-0000-0000-000000070712")!
        let baseDate = Date(timeIntervalSince1970: 1_798_000_000)

        let samples = makeSamples(baseDate: baseDate, limitedAltitude: limitedAltitude)
        let segments = makeSegments(
            sessionID: sessionID,
            run1ID: run1ID,
            run2ID: run2ID,
            baseDate: baseDate,
            limitedAltitude: limitedAltitude,
            samples: samples
        )
        let runs = [
            SnowRun(
                id: run1ID,
                sessionID: sessionID,
                runNumber: 1,
                startDate: baseDate,
                endDate: baseDate.addingTimeInterval(220),
                skiDistanceMeters: 1180,
                verticalDropMeters: 312,
                topSpeedMetersPerSecond: 18.2,
                averageSpeedMetersPerSecond: 10.4,
                segmentIDs: [segments[0].id]
            ),
            SnowRun(
                id: run2ID,
                sessionID: sessionID,
                runNumber: 2,
                startDate: baseDate.addingTimeInterval(620),
                endDate: baseDate.addingTimeInterval(900),
                skiDistanceMeters: 1420,
                verticalDropMeters: 338,
                topSpeedMetersPerSecond: 20.6,
                averageSpeedMetersPerSecond: 11.8,
                segmentIDs: [segments[2].id]
            )
        ]
        let snowState = SnowSessionState(
            sessionID: sessionID,
            loadState: .loaded,
            runs: runs,
            segments: segments
        )
        let session = try! SessionData(
            id: sessionID,
            startDate: baseDate,
            endDate: baseDate.addingTimeInterval(1_100),
            sportMode: .snow(.skiing),
            motionSamples: samples
        )
        return MacSnowSessionAnalysisMapper.makeAnalysis(
            session: session,
            snowState: snowState,
            source: .debugMock
        )
    }

    private static func makeSamples(
        baseDate: Date,
        limitedAltitude: Bool
    ) -> [MotionSample] {
        (0..<24).map { index in
            let time = baseDate.addingTimeInterval(Double(index) * 45)
            let altitude: Double? = limitedAltitude ? nil : 1820 - Double(index * 18)
            return MotionSample(
                timestamp: time,
                gpsCoordinate: GeoCoordinate(
                    latitude: 46.5280 + Double(index) * 0.0009,
                    longitude: 7.9810 + sin(Double(index) / 3.0) * 0.0014
                ),
                speedKmh: speedKmh(for: index),
                accelerometerG: ThreeAxisValue(x: 0.01, y: 0.03, z: 1.0),
                gyroscopeRadPS: ThreeAxisValue(x: 0.0, y: 0.01, z: 0.0),
                altitudeMeters: altitude
            )
        }
    }

    private static func makeSegments(
        sessionID: UUID,
        run1ID: UUID,
        run2ID: UUID,
        baseDate: Date,
        limitedAltitude: Bool,
        samples: [MotionSample]
    ) -> [SnowSegment] {
        [
            SnowSegment(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000070721")!,
                sessionID: sessionID,
                runID: run1ID,
                type: .downhillRun,
                startDate: baseDate,
                endDate: baseDate.addingTimeInterval(220),
                distanceMeters: 1180,
                verticalDeltaMeters: -312,
                startAltitudeMeters: limitedAltitude ? nil : 1820,
                endAltitudeMeters: limitedAltitude ? nil : 1508,
                averageSpeedMetersPerSecond: 10.4,
                maxSpeedMetersPerSecond: 18.2,
                confidence: 0.91,
                sourceSampleIDs: samples.prefix(6).map(\.id)
            ),
            SnowSegment(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000070722")!,
                sessionID: sessionID,
                type: .gondolaAscent,
                startDate: baseDate.addingTimeInterval(240),
                endDate: baseDate.addingTimeInterval(600),
                distanceMeters: 860,
                verticalDeltaMeters: 305,
                startAltitudeMeters: limitedAltitude ? nil : 1508,
                endAltitudeMeters: limitedAltitude ? nil : 1813,
                averageSpeedMetersPerSecond: 2.4,
                maxSpeedMetersPerSecond: 3.1,
                confidence: 0.88,
                sourceSampleIDs: samples.dropFirst(6).prefix(8).map(\.id)
            ),
            SnowSegment(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000070723")!,
                sessionID: sessionID,
                runID: run2ID,
                type: .downhillRun,
                startDate: baseDate.addingTimeInterval(620),
                endDate: baseDate.addingTimeInterval(900),
                distanceMeters: 1420,
                verticalDeltaMeters: -338,
                startAltitudeMeters: limitedAltitude ? nil : 1813,
                endAltitudeMeters: limitedAltitude ? nil : 1475,
                averageSpeedMetersPerSecond: 11.8,
                maxSpeedMetersPerSecond: 20.6,
                confidence: 0.94,
                sourceSampleIDs: samples.dropFirst(14).prefix(7).map(\.id)
            ),
            SnowSegment(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000070724")!,
                sessionID: sessionID,
                type: .unknown,
                startDate: baseDate.addingTimeInterval(920),
                endDate: baseDate.addingTimeInterval(1_060),
                distanceMeters: 120,
                verticalDeltaMeters: nil,
                startAltitudeMeters: nil,
                endAltitudeMeters: nil,
                averageSpeedMetersPerSecond: 0.8,
                maxSpeedMetersPerSecond: 1.2,
                confidence: 0.42,
                sourceSampleIDs: samples.dropFirst(21).map(\.id)
            )
        ]
    }

    private static func speedKmh(for index: Int) -> Double {
        switch index {
        case 0...5:
            return 32 + Double(index) * 3.6
        case 6...13:
            return 8.0
        case 14...20:
            return 38 + Double(index - 14) * 2.4
        default:
            return 1.8
        }
    }
}
#endif
