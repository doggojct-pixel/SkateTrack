// [協作區] Tests/ActivityVisualizationTests/RouteDisplayFixtureTests.swift
// Purpose: Captures ActivityViz-002 route display fixture baselines before Shared route pipeline extraction.
// Delegates to: MotionSample route diagnostics, RouteQualitySummary, JSON fixture baselines, and future RouteDisplayPipeline parity tests.
import Foundation
import XCTest
@testable import SkateTrack_iOS

final class RouteDisplayFixtureTests: XCTestCase {
    func testFixtureCoverageMatchesActivityViz002Scope() throws {
        let manifest = try Self.loadManifest()
        XCTAssertEqual(
            manifest.fixtures.map(\.id),
            [
                "clean-gps-route",
                "startup-drift",
                "low-confidence-segment",
                "sparse-route",
                "duplicate-location-fixes",
                "large-jump",
                "too-few-points"
            ]
        )
        for entry in manifest.fixtures {
            XCTAssertTrue(Self.fixtureFileExists(entry.fileName), entry.fileName)
        }
    }

    func testFixtureJSONMetadataIsDisplayOnlyAndManifestConsistent() throws {
        let manifest = try Self.loadManifest()
        for fixture in try Self.loadScenarioFixtures() {
            let entry = try XCTUnwrap(manifest.entry(for: fixture.id), fixture.id)
            XCTAssertEqual(fixture.taskIdentifier, "task-031-prep-ActivityViz-002", fixture.id)
            XCTAssertEqual(fixture.fixtureVersion, 2, fixture.id)
            XCTAssertTrue(fixture.displayOnly, fixture.id)
            XCTAssertFalse(fixture.mutatesStoredRoute, fixture.id)
            XCTAssertFalse(fixture.mutatesTrustedMetrics, fixture.id)
            XCTAssertFalse(fixture.mutatesPackageSchema, fixture.id)
            XCTAssertEqual(fixture.rawSampleCount, fixture.samples.count, fixture.id)
            XCTAssertEqual(fixture.expectedDisplayPointCount, entry.displayPointCount, fixture.id)
            XCTAssertEqual(fixture.expectedSemanticDistribution, entry.semanticDistribution, fixture.id)
            XCTAssertEqual(fixture.expectedRouteQuality, entry.routeQuality, fixture.id)
        }
    }

    func testSemanticDistributionBaselinesMatchCurrentIOSRouteRules() throws {
        for fixture in try Self.loadScenarioFixtures() {
            let samples = Self.makeMotionSamples(from: fixture)
            let baseline = ExistingIOSRouteDisplayBaseline.makeBaseline(
                samples: samples,
                startDate: Self.startDate,
                policy: Self.routePolicy
            )
            XCTAssertEqual(baseline.semanticCounts, fixture.expectedSemanticDistribution, fixture.id)
            XCTAssertEqual(baseline.displayPointCount, fixture.expectedDisplayPointCount, fixture.id)
        }
    }


    func testSharedRouteDisplayPipelineMatchesActivityViz002Baselines() throws {
        let pipeline = RouteDisplayPipeline()
        for fixture in try Self.loadScenarioFixtures() {
            let result = pipeline.makeDisplayRoute(
                samples: Self.makeMotionSamples(from: fixture),
                startDate: Self.startDate,
                fidelityPolicy: Self.routePolicy
            )
            let semanticCounts = result.points.reduce(SemanticCounts.zero) { partial, point in
                partial.adding(point.semantic)
            }
            XCTAssertEqual(semanticCounts, fixture.expectedSemanticDistribution, fixture.id)
            XCTAssertEqual(result.summary.rawSampleCount, fixture.rawSampleCount, fixture.id)
            XCTAssertEqual(result.summary.displayPointCount, fixture.expectedDisplayPointCount, fixture.id)
            XCTAssertEqual(result.summary.segmentCount, result.segments.count, fixture.id)
            XCTAssertEqual(result.summary.hasStartupWarmup, semanticCounts.startupWarmup > 0, fixture.id)
            XCTAssertEqual(result.summary.hasLowConfidenceSegments, semanticCounts.lowConfidence > 0, fixture.id)
            XCTAssertEqual(result.points.count, fixture.expectedDisplayPointCount, fixture.id)
        }
    }

    func testRouteQualityBaselinesMatchMotionSampleSourceOfTruth() throws {
        for fixture in try Self.loadScenarioFixtures() {
            let summary = RouteQualitySummary.make(from: Self.makeMotionSamples(from: fixture))
            XCTAssertEqual(summary.sampleCount, fixture.expectedRouteQuality.sampleCount, fixture.id)
            XCTAssertEqual(summary.gpsSampleCount, fixture.expectedRouteQuality.gpsSampleCount, fixture.id)
            XCTAssertEqual(summary.uniqueCoordinateCount, fixture.expectedRouteQuality.uniqueCoordinateCount, fixture.id)
            XCTAssertEqual(summary.lowConfidenceSegmentCount, fixture.expectedRouteQuality.lowConfidenceSegmentCount, fixture.id)
            XCTAssertEqual(summary.staleLocationSampleCount, fixture.expectedRouteQuality.staleLocationSampleCount, fixture.id)
            XCTAssertEqual(summary.longLocationUpdateGapCount, fixture.expectedRouteQuality.longLocationUpdateGapCount, fixture.id)
            XCTAssertEqual(summary.longMotionSampleGapCount, fixture.expectedRouteQuality.longMotionSampleGapCount, fixture.id)
        }
    }

    func testBaselineFixturesDoNotCreateStoredDisplayDerivedTruth() throws {
        let manifestData = try Data(contentsOf: Self.fixturesDirectory().appendingPathComponent(Self.manifestFileName))
        let manifestText = String(decoding: manifestData, as: UTF8.self)
        XCTAssertFalse(manifestText.contains("displayDerived"))
        XCTAssertFalse(manifestText.contains("displayDerivedTotalAscentMeters"))
        for fixture in try Self.loadScenarioFixtures() {
            let data = try Data(contentsOf: Self.fixturesDirectory().appendingPathComponent(fixture.fileName))
            let text = String(decoding: data, as: UTF8.self)
            XCTAssertFalse(text.contains("displayDerived"), fixture.id)
            XCTAssertFalse(text.contains("displayDerivedTotalAscentMeters"), fixture.id)
        }
    }
}

private extension RouteDisplayFixtureTests {
    static let startDate = Date(timeIntervalSince1970: 1_800_000_000)
    static let routePolicy = ActivityFidelityPolicy(profile: .standardSkateboard)
    static let manifestFileName = "route_display_fixture_baselines.json"

    static func loadManifest() throws -> RouteFixtureManifest {
        let url = fixturesDirectory().appendingPathComponent(manifestFileName)
        return try decode(RouteFixtureManifest.self, from: url)
    }

    static func loadScenarioFixtures() throws -> [RouteFixtureScenario] {
        let manifest = try loadManifest()
        return try manifest.fixtures.map { entry in
            let scenario = try decode(RouteFixtureScenario.self, from: fixturesDirectory().appendingPathComponent(entry.fileName))
            guard scenario.id == entry.id else {
                throw FixtureError.idMismatch(expected: entry.id, actual: scenario.id)
            }
            return scenario
        }
    }

    static func decode<T: Decodable>(_ type: T.Type, from url: URL) throws -> T {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        return try decoder.decode(type, from: data)
    }

    static func fixturesDirectory(filePath: String = #filePath) -> URL {
        var cursor = URL(fileURLWithPath: filePath).deletingLastPathComponent()
        while cursor.path != "/" {
            let candidate = cursor.appendingPathComponent("Tests/Fixtures/ActivityVisualization")
            if fixtureManifestExists(in: candidate) { return candidate }
            cursor.deleteLastPathComponent()
        }
        return URL(fileURLWithPath: filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Fixtures/ActivityVisualization")
    }

    static func fixtureManifestExists(in directory: URL) -> Bool {
        FileManager.default.fileExists(atPath: directory.appendingPathComponent(manifestFileName).path)
    }

    static func fixtureFileExists(_ fileName: String) -> Bool {
        FileManager.default.fileExists(atPath: fixturesDirectory().appendingPathComponent(fileName).path)
    }

    static func makeMotionSamples(from fixture: RouteFixtureScenario) -> [MotionSample] {
        fixture.samples.map { sample in
            let timestamp = startDate.addingTimeInterval(sample.elapsedSeconds)
            let coordinate = sample.latitude.flatMap { latitude in
                sample.longitude.map { longitude in
                    GeoCoordinate(latitude: latitude, longitude: longitude)
                }
            }
            return MotionSample(
                timestamp: timestamp,
                timestampMillisecondsSince1970: timestamp.millisecondsSince1970,
                gpsCoordinate: coordinate,
                speedKmh: sample.speedKilometersPerHour,
                accelerometerG: ThreeAxisValue(x: 0, y: 0, z: 1),
                gyroscopeRadPS: ThreeAxisValue(x: 0, y: 0, z: 0),
                locationDiagnostics: Self.makeDiagnostics(from: sample, timestamp: timestamp, hasCoordinate: coordinate != nil),
                sampleSource: coordinate == nil ? .timerFusion : .locationFix
            )
        }
    }

    static func makeDiagnostics(from sample: RouteFixtureSample, timestamp: Date, hasCoordinate: Bool) -> LocationFixDiagnostics? {
        guard hasCoordinate else { return nil }
        return LocationFixDiagnostics(
            horizontalAccuracyMeters: sample.horizontalAccuracyMeters,
            rawLocationTimestamp: timestamp,
            rawLocationTimestampMillisecondsSince1970: timestamp.millisecondsSince1970,
            receivedAtTimestamp: timestamp,
            receivedAtTimestampMillisecondsSince1970: timestamp.millisecondsSince1970,
            gpsUpdateIntervalSeconds: sample.gpsUpdateIntervalSeconds,
            coordinateDerivedSpeedKmh: sample.coordinateDerivedSpeedKmh,
            speedSource: .coreLocation,
            freshnessState: sample.freshnessState.swiftValue,
            routeSegmentConfidence: sample.routeSegmentConfidence.swiftValue
        )
    }
}

private struct RouteFixtureManifest: Codable {
    let task: String
    let purpose: String
    let sourceOfTruth: [String]
    let doNotImplement: [String]
    let fixtures: [RouteFixtureManifestEntry]

    func entry(for id: String) -> RouteFixtureManifestEntry? {
        fixtures.first { $0.id == id }
    }
}

private struct RouteFixtureManifestEntry: Codable {
    let id: String
    let fileName: String
    let semanticDistribution: SemanticCounts
    let displayPointCount: Int
    let routeQuality: RouteQualityExpectation
}

private struct RouteFixtureScenario: Codable {
    let id: String
    let fileName: String
    let taskIdentifier: String
    let fixtureVersion: Int
    let scenario: String
    let displayOnly: Bool
    let mutatesStoredRoute: Bool
    let mutatesTrustedMetrics: Bool
    let mutatesPackageSchema: Bool
    let rawSampleCount: Int
    let expectedDisplayPointCount: Int
    let expectedSegmentCount: Int
    let expectedQuality: ActivityVisualizationQuality
    let expectedSemanticDistribution: SemanticCounts
    let expectedRouteQuality: RouteQualityExpectation
    let samples: [RouteFixtureSample]
}

private struct RouteFixtureSample: Codable {
    let id: Int
    let elapsedSeconds: TimeInterval
    let latitude: Double?
    let longitude: Double?
    let speedKilometersPerHour: Double
    let horizontalAccuracyMeters: Double?
    let gpsUpdateIntervalSeconds: TimeInterval?
    let coordinateDerivedSpeedKmh: Double?
    let routeSegmentConfidence: RouteConfidenceToken
    let freshnessState: FreshnessToken
    let includedInDisplayBaseline: Bool
    let expectedSemantic: RouteDisplaySemantic?
}

private enum RouteConfidenceToken: String, Codable {
    case high
    case medium
    case low
    case unavailable

    var swiftValue: RouteSegmentConfidence {
        switch self {
        case .high: return .high
        case .medium: return .medium
        case .low: return .low
        case .unavailable: return .unavailable
        }
    }
}

private enum FreshnessToken: String, Codable {
    case fresh
    case recent
    case stale
    case unavailable

    var swiftValue: LocationFreshnessState {
        switch self {
        case .fresh: return .fresh
        case .recent: return .recent
        case .stale: return .stale
        case .unavailable: return .unavailable
        }
    }
}

private struct SemanticCounts: Codable, Equatable {
    let highConfidence: Int
    let lowConfidence: Int
    let startupWarmup: Int
    static let zero = SemanticCounts(highConfidence: 0, lowConfidence: 0, startupWarmup: 0)

    func adding(_ semantic: RouteDisplaySemantic) -> SemanticCounts {
        switch semantic {
        case .highConfidence:
            return SemanticCounts(highConfidence: highConfidence + 1, lowConfidence: lowConfidence, startupWarmup: startupWarmup)
        case .lowConfidence:
            return SemanticCounts(highConfidence: highConfidence, lowConfidence: lowConfidence + 1, startupWarmup: startupWarmup)
        case .startupWarmup:
            return SemanticCounts(highConfidence: highConfidence, lowConfidence: lowConfidence, startupWarmup: startupWarmup + 1)
        }
    }
}

private struct RouteQualityExpectation: Codable, Equatable {
    let sampleCount: Int
    let gpsSampleCount: Int
    let uniqueCoordinateCount: Int
    let lowConfidenceSegmentCount: Int
    let staleLocationSampleCount: Int
    let longLocationUpdateGapCount: Int?
    let longMotionSampleGapCount: Int?
}

private struct RouteBaselineResult {
    let semanticCounts: SemanticCounts
    let displayPointCount: Int
}

private enum FixtureError: Error {
    case idMismatch(expected: String, actual: String)
}

private enum ExistingIOSRouteDisplayBaseline {
    private static let startupStableAnchorMinimumCandidateCount = 3
    private static let startupGPSLockSearchWindowSeconds: TimeInterval = 60
    private static let startupConvergenceWarmupSeconds: TimeInterval = 45
    private static let startupRouteVisualSuppressionMaximumSeconds: TimeInterval = 45
    private static let startupStableAnchorClusterWindowSeconds: TimeInterval = 7

    static func makeBaseline(samples: [MotionSample], startDate: Date, policy: ActivityFidelityPolicy) -> RouteBaselineResult {
        let candidates = deduplicatedTrustedLocationFixes(from: samples, policy: policy)
        let gpsLockAnchorTimestamp = firstGPSLockAnchorTimestamp(from: candidates, startDate: startDate, policy: policy)
        var counts = SemanticCounts.zero
        var displayPointCount = 0
        var hasReliableAnchor = false
        for sample in candidates where validCoordinate(from: sample) != nil {
            let confidence = sample.locationDiagnostics?.routeSegmentConfidence ?? .medium
            let isWarmup = isStartupWarmupSample(
                sample,
                startDate: startDate,
                policy: policy,
                stableStartupAnchorTimestamp: gpsLockAnchorTimestamp,
                gpsLockAnchorTimestamp: gpsLockAnchorTimestamp,
                hasReliableAnchor: hasReliableAnchor
            )
            let semantic: RouteDisplaySemantic = isWarmup ? .startupWarmup : ((confidence == .low || confidence == .unavailable) ? .lowConfidence : .highConfidence)
            counts = counts.adding(semantic)
            displayPointCount += 1
            if !isWarmup && semantic == .highConfidence { hasReliableAnchor = true }
        }
        return RouteBaselineResult(semanticCounts: counts, displayPointCount: displayPointCount)
    }

    private static func deduplicatedTrustedLocationFixes(from samples: [MotionSample], policy: ActivityFidelityPolicy) -> [MotionSample] {
        var seenKeys = Set<String>()
        return samples.sorted { routeTimestamp(for: $0) < routeTimestamp(for: $1) }.compactMap { sample in
            guard validCoordinate(from: sample) != nil,
                  isTrustedDisplayRouteSample(sample, policy: policy) else { return nil }
            let key = locationFixKey(for: sample)
            guard seenKeys.insert(key).inserted else { return nil }
            return sample
        }
    }

    private static func isStartupWarmupSample(
        _ sample: MotionSample,
        startDate: Date,
        policy: ActivityFidelityPolicy,
        stableStartupAnchorTimestamp: Date?,
        gpsLockAnchorTimestamp: Date?,
        hasReliableAnchor: Bool
    ) -> Bool {
        let timestamp = routeTimestamp(for: sample)
        let elapsed = timestamp.timeIntervalSince(startDate)
        if elapsed < 0 { return elapsed >= -10 }
        guard !hasReliableAnchor else { return false }
        guard elapsed <= startupConvergenceWarmupSeconds else { return false }
        guard let diagnostics = sample.locationDiagnostics else { return elapsed <= 8 }
        let accuracy = diagnostics.horizontalAccuracyMeters ?? .infinity
        let warmupAccuracyLimit = max(policy.preferredHorizontalAccuracyMeters * 1.8, 18)
        if diagnostics.freshnessState == .stale { return true }
        if diagnostics.routeSegmentConfidence == .low || diagnostics.routeSegmentConfidence == .unavailable { return true }
        if accuracy > warmupAccuracyLimit { return true }
        guard startupAnchorGuardApplies(policy: policy) else {
            return gpsLockAnchorTimestamp.map { timestamp < $0 } ?? (elapsed <= 10 && !isPreferredFreshAnchor(sample, policy: policy))
        }
        guard let stableStartupAnchorTimestamp else {
            return elapsed <= startupConvergenceWarmupSeconds && !isPreferredFreshAnchor(sample, policy: policy)
        }
        if timestamp < stableStartupAnchorTimestamp { return true }
        return elapsed <= startupRouteVisualSuppressionMaximumSeconds
            && timestamp.timeIntervalSince(stableStartupAnchorTimestamp) <= 3
            && !isPreferredFreshAnchor(sample, policy: policy)
    }

    private static func startupAnchorGuardApplies(policy: ActivityFidelityPolicy) -> Bool {
        switch policy.profile {
        case .technicalSkateboard, .standardSkateboard, .electricSkateboard, .inlineRecreation:
            return true
        case .inlineSpeed, .snowReserved, .vehicleValidation:
            return policy.usesStrictSmallAreaLowSpeedGate
        }
    }

    private static func firstGPSLockAnchorTimestamp(from candidates: [MotionSample], startDate: Date, policy: ActivityFidelityPolicy) -> Date? {
        let lockCandidates = candidates.filter { sample in
            let elapsed = routeTimestamp(for: sample).timeIntervalSince(startDate)
            return elapsed >= 0 && elapsed <= startupGPSLockSearchWindowSeconds && isPreferredFreshAnchor(sample, policy: policy)
        }
        guard lockCandidates.count >= startupStableAnchorMinimumCandidateCount else { return nil }
        for candidate in lockCandidates {
            let anchorTime = routeTimestamp(for: candidate)
            let cluster = lockCandidates.filter { sample in
                let delta = routeTimestamp(for: sample).timeIntervalSince(anchorTime)
                return delta >= 0 && delta <= startupStableStartupAnchorClusterWindowSecondsShim
            }
            if cluster.count >= startupStableAnchorMinimumCandidateCount { return anchorTime }
        }
        return nil
    }

    private static var startupStableStartupAnchorClusterWindowSecondsShim: TimeInterval {
        startupStableAnchorClusterWindowSeconds
    }

    private static func isPreferredFreshAnchor(_ sample: MotionSample, policy: ActivityFidelityPolicy) -> Bool {
        guard let diagnostics = sample.locationDiagnostics else { return false }
        let accuracy = diagnostics.horizontalAccuracyMeters ?? .infinity
        return diagnostics.freshnessState == .fresh && diagnostics.routeSegmentConfidence == .high && accuracy <= policy.preferredHorizontalAccuracyMeters
    }

    private static func isTrustedDisplayRouteSample(_ sample: MotionSample, policy: ActivityFidelityPolicy) -> Bool {
        guard sample.sampleSource != .timerFusion || sample.locationDiagnostics?.rawLocationTimestampMillisecondsSince1970 == nil else { return false }
        guard let diagnostics = sample.locationDiagnostics else { return true }
        if diagnostics.freshnessState == .stale { return false }
        if diagnostics.gpsUpdateIntervalSeconds.map({ $0 > max(12, policy.maximumTrustedUpdateIntervalSeconds + 4) }) == true { return false }
        if diagnostics.horizontalAccuracyMeters.map({ $0 > policy.displayRouteMaximumHorizontalAccuracyMeters }) == true { return false }
        if diagnostics.coordinateDerivedSpeedKmh.map({ $0 > policy.maximumTrustedImpliedSpeedKmh }) == true { return false }
        return true
    }

    private static func validCoordinate(from sample: MotionSample) -> GeoCoordinate? {
        guard let coordinate = sample.gpsCoordinate,
              coordinate.latitude.isFinite,
              coordinate.longitude.isFinite,
              (-90.0...90.0).contains(coordinate.latitude),
              (-180.0...180.0).contains(coordinate.longitude) else { return nil }
        return coordinate
    }

    private static func routeTimestamp(for sample: MotionSample) -> Date {
        sample.locationDiagnostics?.rawLocationTimestamp ?? sample.timestamp
    }

    private static func locationFixKey(for sample: MotionSample) -> String {
        if let timestamp = sample.locationDiagnostics?.rawLocationTimestampMillisecondsSince1970,
           let coordinate = sample.gpsCoordinate {
            return "\(timestamp)-\(coordinateKey(for: coordinate))"
        }
        if let coordinate = sample.gpsCoordinate {
            return "\(sample.timestampMillisecondsSince1970 ?? sample.timestamp.millisecondsSince1970)-\(coordinateKey(for: coordinate))"
        }
        return sample.id.uuidString
    }

    private static func coordinateKey(for coordinate: GeoCoordinate) -> String {
        "\(coordinate.latitude.rounded(toPlaces: 7)),\(coordinate.longitude.rounded(toPlaces: 7))"
    }
}

private extension Date {
    var millisecondsSince1970: Int64 { Int64((timeIntervalSince1970 * 1_000).rounded()) }
}

private extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
