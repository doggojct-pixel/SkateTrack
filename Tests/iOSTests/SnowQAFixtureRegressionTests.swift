// [協作區] SnowQAFixtureRegressionTests.swift
import Foundation
import XCTest
@testable import SkateTrack_iOS

final class SnowQAFixtureRegressionTests: XCTestCase {
    func testBasicRunFixtureDecodesWithVerticalDrop() throws {
        let payload = try decodeFixture(SkateTrackPackageSnowPayload.self, name: "qa_snow_basic_run.json")

        XCTAssertEqual(payload.payloadVersion, SkateTrackPackageSnowPayload.currentPayloadVersion)
        XCTAssertEqual(payload.runs.count, 1)
        XCTAssertEqual(payload.segments.count, 1)
        XCTAssertEqual(payload.distanceBreakdown.skiDistanceMeters, 1250, accuracy: 0.001)
        XCTAssertEqual(payload.distanceBreakdown.liftDistanceMeters, 0, accuracy: 0.001)
        XCTAssertEqual(payload.verticalMetrics.totalVerticalDropMeters, 230, accuracy: 0.001)
        XCTAssertEqual(payload.segments.first?.type, .downhillRun)
    }

    func testLiftExclusionFixturePreservesDistanceBreakdown() throws {
        let payload = try decodeFixture(SkateTrackPackageSnowPayload.self, name: "qa_snow_lift_exclusion.json")

        XCTAssertTrue(payload.segments.contains { $0.type == .liftAscent })
        XCTAssertEqual(payload.distanceBreakdown.skiDistanceMeters, 1260, accuracy: 0.001)
        XCTAssertEqual(payload.distanceBreakdown.liftDistanceMeters, 950, accuracy: 0.001)
        XCTAssertEqual(payload.distanceBreakdown.routeDistanceMeters, 2210, accuracy: 0.001)
        XCTAssertLessThan(payload.distanceBreakdown.skiDistanceMeters, payload.distanceBreakdown.routeDistanceMeters)
        XCTAssertEqual(payload.segments.first { $0.type == .liftAscent }?.countsTowardSkiDistance, false)
    }

    func testLowConfidenceFixtureMapsToSafeSnowState() throws {
        let payload = try decodeFixture(SkateTrackPackageSnowPayload.self, name: "qa_snow_low_confidence.json")
        let state = payload.makeSnowSessionState()
        let regenerated = try XCTUnwrap(SkateTrackPackageSnowPayload(snowState: state, generatedAt: payload.generatedAt))

        XCTAssertEqual(state.loadState, .loaded)
        XCTAssertEqual(payload.runs.count, 0)
        XCTAssertEqual(payload.segments.first?.type, .unknown)
        XCTAssertEqual(payload.segments.first?.confidence ?? 1, 0.35, accuracy: 0.001)
        XCTAssertEqual(payload.distanceBreakdown.unknownDistanceMeters, 80, accuracy: 0.001)
        XCTAssertEqual(regenerated.sessionID, payload.sessionID)
    }

    func testPackageV2WithSnowPayloadFixtureDecodesThroughReader() throws {
        let data = try fixtureData(named: "qa_snow_package_v2_with_payload.json")
        let package = try SkateTrackPackageReader().decodePackage(from: data)
        let session = try XCTUnwrap(package.primarySession)
        let snowPayload = try XCTUnwrap(session.snowPayload)

        XCTAssertEqual(package.manifest.schemaVersion, 2)
        XCTAssertEqual(package.manifest.capabilities, SkateTrackPackageSnowCapability.allRawValues)
        XCTAssertEqual(snowPayload.payloadVersion, SkateTrackPackageSnowPayload.currentPayloadVersion)
        XCTAssertEqual(snowPayload.sessionID, session.session.id)
        guard case .snow(.skiing) = session.session.sportMode else {
            XCTFail("Expected Snow skiing session in fixture")
            return
        }
    }

    func testPackageV2WithoutSnowPayloadFixtureRemainsSafe() throws {
        let data = try fixtureData(named: "qa_snow_package_v2_without_payload.json")
        let package = try SkateTrackPackageReader().decodePackage(from: data)
        let session = try XCTUnwrap(package.primarySession)

        XCTAssertEqual(package.manifest.schemaVersion, 2)
        XCTAssertNil(package.manifest.capabilities)
        XCTAssertNil(session.snowPayload)
        guard case .snow(.skiing) = session.session.sportMode else {
            XCTFail("Expected Snow skiing session without payload")
            return
        }
    }

    func testBackupV1LegacyFixtureDecodesWithoutSnowSessions() throws {
        let data = try fixtureData(named: "qa_snow_backup_v1_legacy.json")
        let payload = try decodeBackupPayload(from: data)
        let preview = try BackupPackageDecoder().preview(from: data, sourceFileName: "qa_snow_backup_v1_legacy.json")

        XCTAssertEqual(payload.manifest.schemaVersion, 1)
        XCTAssertNil(payload.manifest.storeCounts.snowSessions)
        XCTAssertNil(payload.snowSessions)
        XCTAssertNil(preview.snowSessionCount)
        XCTAssertFalse(preview.isSnowAwareBackup)
        XCTAssertFalse(preview.hasValidationIssues)
    }

    func testBackupV2EmptySnowSessionsFixtureDecodes() throws {
        let data = try fixtureData(named: "qa_snow_backup_v2_empty_snow_sessions.json")
        let payload = try decodeBackupPayload(from: data)
        let preview = try BackupPackageDecoder().preview(from: data, sourceFileName: "qa_snow_backup_v2_empty_snow_sessions.json")

        XCTAssertEqual(payload.manifest.schemaVersion, 2)
        XCTAssertEqual(payload.manifest.storeCounts.snowSessions, 0)
        XCTAssertEqual(payload.snowSessions, [])
        XCTAssertEqual(preview.snowSessionCount, 0)
        XCTAssertTrue(preview.isSnowAwareBackup)
        XCTAssertFalse(preview.hasValidationIssues)
    }

    func testBackupV2PopulatedSnowSessionsFixtureDecodes() throws {
        let data = try fixtureData(named: "qa_snow_backup_v2_with_snow_sessions.json")
        let payload = try decodeBackupPayload(from: data)
        let snowSession = try XCTUnwrap(payload.snowSessions?.first)
        let preview = try BackupPackageDecoder().preview(from: data, sourceFileName: "qa_snow_backup_v2_with_snow_sessions.json")
        let state = snowSession.makeSnowSessionState()

        XCTAssertEqual(payload.manifest.schemaVersion, 2)
        XCTAssertEqual(payload.manifest.storeCounts.snowSessions, 1)
        XCTAssertEqual(payload.snowSessions?.count, 1)
        XCTAssertEqual(snowSession.schemaVersion, SnowBackupSession.currentSchemaVersion)
        XCTAssertEqual(snowSession.distanceBreakdown.skiDistanceMeters, 1250, accuracy: 0.001)
        XCTAssertEqual(state.loadState, .loaded)
        XCTAssertEqual(preview.snowSessionCount, 1)
        XCTAssertFalse(preview.hasValidationIssues)
    }

    func testHealthBoundaryRegressionRemainsNoOpOrDebugOnly() async throws {
        let payload = try decodeFixture(SkateTrackPackageSnowPayload.self, name: "qa_snow_basic_run.json")
        let request = SnowHealthExportRequest(
            sessionID: payload.sessionID,
            state: payload.makeSnowSessionState(),
            startedAt: payload.segments.first?.startDate,
            endedAt: payload.segments.first?.endDate,
            metadata: ["fixture": "qa_snow_basic_run"]
        )

        let disabledResult = try await DisabledSnowHealthExporter().exportSnowSession(request)
        XCTAssertEqual(disabledResult.status, .unavailable)
        XCTAssertEqual(disabledResult.sampleCount, 0)

        #if DEBUG
        let mockResult = try await MockSnowHealthExporter(sampleCount: payload.segments.count).exportSnowSession(request)
        XCTAssertEqual(mockResult.status, .prepared)
        XCTAssertEqual(mockResult.sampleCount, payload.segments.count)
        #endif
    }

    private func decodeFixture<T: Decodable>(_ type: T.Type, name: String) throws -> T {
        let data = try fixtureData(named: name)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(T.self, from: data)
    }

    private func decodeBackupPayload(from data: Data) throws -> BackupPackagePayload {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(BackupPackagePayload.self, from: data)
    }

    private func fixtureData(named name: String) throws -> Data {
        let testFile = URL(fileURLWithPath: #filePath)
        let fixtureURL = testFile
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Fixtures")
            .appendingPathComponent("Snow")
            .appendingPathComponent(name)
        return try Data(contentsOf: fixtureURL)
    }
}
