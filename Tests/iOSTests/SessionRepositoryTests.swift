import XCTest
@testable import SkateTrack_iOS

final class SessionRepositoryTests: XCTestCase {
    // Previous diagnostics build regression token: Task-030c-b11-r3-3.
    func testSaveFetchLoadExportAndDeleteCompletedSession() async throws {
        let rootDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("SkateTrackRepositoryTests_\(UUID().uuidString)", isDirectory: true)
        let sampleDirectory = rootDirectory.appendingPathComponent("samples", isDirectory: true)
        let exportDirectory = rootDirectory.appendingPathComponent("exports", isDirectory: true)
        let storeURL = rootDirectory.appendingPathComponent("SkateTrack.sqlite")
        defer { try? FileManager.default.removeItem(at: rootDirectory) }

        let persistenceController = PersistenceController(inMemory: false, storeURL: storeURL)
        let repository = SessionRepository(
            persistenceController: persistenceController,
            sampleStore: MotionSampleFileStore(rootDirectory: sampleDirectory),
            exportDirectory: exportDirectory
        )

        let session = try makeCompletedSession()
        try await repository.saveCompletedSession(session)

        let recentSessions = try await repository.fetchRecentSessions(limit: 10)
        XCTAssertEqual(recentSessions.count, 1)
        XCTAssertEqual(recentSessions.first?.id, session.id)

        let fetchedSession = try await repository.fetchSession(id: session.id)
        let fetchedSummaryMetrics = try XCTUnwrap(fetchedSession.summaryMetrics)
        XCTAssertEqual(fetchedSummaryMetrics.distanceKilometers, 0.42, accuracy: 0.001)
        XCTAssertEqual(fetchedSession.spotID, session.spotID)

        let fetchedSpotSnapshot = try XCTUnwrap(fetchedSession.spotSnapshot)
        let originalSpotSnapshot = try XCTUnwrap(session.spotSnapshot)
        XCTAssertEqual(fetchedSpotSnapshot.spotID, originalSpotSnapshot.spotID)
        XCTAssertEqual(fetchedSpotSnapshot.name, originalSpotSnapshot.name)
        XCTAssertEqual(fetchedSpotSnapshot.activityFamily, originalSpotSnapshot.activityFamily)
        XCTAssertEqual(fetchedSpotSnapshot.coordinate, originalSpotSnapshot.coordinate)
        XCTAssertEqual(fetchedSpotSnapshot.radiusMeters, originalSpotSnapshot.radiusMeters, accuracy: 0.001)
        XCTAssertEqual(
            fetchedSpotSnapshot.archivedAt.timeIntervalSince1970,
            originalSpotSnapshot.archivedAt.timeIntervalSince1970,
            accuracy: 1.0
        )

        XCTAssertEqual(
            fetchedSession.debugRecordingDiagnostics?.buildIdentity.debugBuildTaskID,
            RecordingDebugBuildIdentity.currentDebugBuildTaskID
        )
        XCTAssertEqual(fetchedSession.debugRecordingDiagnostics?.diagnosticsStatus, "enabled")

        let samples = try await repository.loadMotionSamples(for: session.id)
            .sorted { $0.timestamp < $1.timestamp }
        XCTAssertEqual(samples.count, 2)
        XCTAssertEqual(samples.map(\.speedKmh), [8, 12])

        let diagnosticsSamples = samples.compactMap(\.locationDiagnostics)
        XCTAssertEqual(diagnosticsSamples.count, 2)
        XCTAssertTrue(
            diagnosticsSamples.contains { $0.gpsGapDiagnostics?.classification == .normalCadence },
            "Expected persisted samples to retain r4 GPS gap diagnostics."
        )
        XCTAssertTrue(
            diagnosticsSamples.contains { $0.headingDiagnostics?.source == .coreLocationCourse },
            "Expected persisted samples to retain r4 heading diagnostics."
        )
        XCTAssertTrue(
            diagnosticsSamples.contains { $0.deadReckoningDiagnostics?.estimatedRouteActive == false },
            "Expected persisted samples to retain inactive r4 dead-reckoning diagnostics."
        )

        let altitudeDiagnostics = samples.compactMap(\.altitudeDiagnostics)
        XCTAssertEqual(altitudeDiagnostics.count, 2)
        XCTAssertTrue(
            altitudeDiagnostics.contains { $0.reason == .firstTrustedAnchor },
            "Expected persisted samples to retain b12 altitude diagnostics."
        )
        XCTAssertTrue(
            altitudeDiagnostics.allSatisfy { $0.trustClassification == .trusted },
            "Expected fixture samples to remain trusted after b12 persistence round-trip."
        )

        XCTAssertEqual(fetchedSession.fallEvents.count, 1)

        let exportURL = try await repository.exportSessionBundle(id: session.id)
        XCTAssertTrue(FileManager.default.fileExists(atPath: exportURL.appendingPathComponent("session.json").path))
        let exportedSamplesURL = exportURL.appendingPathComponent("motionSamples.json")
        XCTAssertTrue(FileManager.default.fileExists(atPath: exportedSamplesURL.path))
        let exportedSamplesJSON = try String(contentsOf: exportedSamplesURL)
        XCTAssertTrue(exportedSamplesJSON.contains("altitudeDiagnostics"))
        XCTAssertTrue(exportedSamplesJSON.contains("coreLocationAbsoluteAccepted"))

        try await repository.deleteSession(id: session.id)
        do {
            _ = try await repository.fetchSession(id: session.id)
            XCTFail("Expected deleted session to be unavailable")
        } catch let error as RepositoryError {
            XCTAssertEqual(error, .sessionNotFound)
        }
    }

    func testR4GPSGapClassificationThresholds() {
        XCTAssertEqual(GPSGapDiagnostics.classification(for: 1.0), .normalCadence)
        XCTAssertEqual(GPSGapDiagnostics.classification(for: 3.0), .shortGap)
        XCTAssertEqual(GPSGapDiagnostics.classification(for: 15.0), .backgroundLocationGap)
        XCTAssertEqual(GPSGapDiagnostics.classification(for: 31.0), .extendedSignalLoss)
        XCTAssertNil(GPSGapDiagnostics.classification(for: nil))
    }

    func testLegacyLocationFixDiagnosticsDecodesWithoutR4Fields() throws {
        let legacyJSON = #"""
        {
          "horizontalAccuracyMeters": 5.0,
          "verticalAccuracyMeters": 8.0,
          "speedAccuracyMetersPerSecond": 1.5,
          "courseAccuracyDegrees": 12.0,
          "gpsUpdateIntervalSeconds": 1.0,
          "gpsSegmentDistanceMeters": 4.0,
          "coordinateDerivedSpeedKmh": 14.4,
          "speedSource": "coordinateDerived",
          "freshnessState": "fresh",
          "routeSegmentConfidence": "high"
        }
        """#.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(LocationFixDiagnostics.self, from: legacyJSON)
        XCTAssertEqual(decoded.routeSegmentConfidence, .high)
        XCTAssertNil(decoded.headingDiagnostics)
        XCTAssertNil(decoded.gpsGapDiagnostics)
        XCTAssertNil(decoded.deadReckoningDiagnostics)
    }

    func testLegacyMotionSampleDecodesWithoutB12AltitudeDiagnostics() throws {
        let legacyJSON = #"""
        {
          "id": "11111111-1111-1111-1111-111111111111",
          "timestamp": 700000000,
          "timestampMillisecondsSince1970": 700000000000,
          "gpsCoordinate": { "latitude": 25.033, "longitude": 121.565 },
          "speedKmh": 8.0,
          "accelerometerG": { "x": 0.0, "y": 0.0, "z": 1.0 },
          "gyroscopeRadPS": { "x": 0.0, "y": 0.0, "z": 0.0 },
          "altitudeMeters": 12.0,
          "altitudeSource": "coreLocationAbsolute",
          "sampleSource": "locationFix"
        }
        """#.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        let decoded = try decoder.decode(MotionSample.self, from: legacyJSON)
        XCTAssertEqual(decoded.altitudeSource, .coreLocationAbsolute)
        XCTAssertNil(decoded.altitudeDiagnostics)
    }

    func testAltitudeDiagnosticsPressureDiagnosticsCodableRoundTrip() throws {
        let diagnostics = AltitudeDiagnostics(
            source: .barometerRelative,
            trustClassification: .trusted,
            reason: .barometerRelativeAccepted,
            rawAltitudeMeters: 2.5,
            trustedAltitudeMeters: 2.5,
            updatesTrustedAltitudeAnchor: true,
            pressureDiagnostics: AltitudePressureDiagnostics(
                rawPressureKilopascals: 101.30,
                smoothedPressureKilopascals: 101.28,
                previousSmoothedPressureKilopascals: 101.25,
                pressureDeltaKilopascals: 0.05,
                filterAlpha: 0.20,
                spikeSuppressed: true
            )
        )

        let encoded = try JSONEncoder().encode(diagnostics)
        let json = String(data: encoded, encoding: .utf8) ?? ""
        XCTAssertTrue(json.contains("pressureDiagnostics"))
        XCTAssertTrue(json.contains("smoothedPressureKilopascals"))

        let decoded = try JSONDecoder().decode(AltitudeDiagnostics.self, from: encoded)
        XCTAssertEqual(decoded.pressureDiagnostics?.rawPressureKilopascals ?? .nan, 101.30, accuracy: 0.0001)
        XCTAssertEqual(decoded.pressureDiagnostics?.smoothedPressureKilopascals ?? .nan, 101.28, accuracy: 0.0001)
        XCTAssertEqual(decoded.pressureDiagnostics?.spikeSuppressed, true)
    }


    func testB13BHeadingDiagnosticsCodableRoundTrip() throws {
        let timestamp = Date(timeIntervalSince1970: 1_700_000_123)
        let diagnostics = HeadingDiagnostics(
            source: .courseAndDeviceMagnetometer,
            headingAvailable: true,
            courseOverGroundDegrees: 184,
            courseAccuracyDegrees: 12,
            coreLocationSpeedKmh: 7.2,
            courseReliableForRouteContinuity: true,
            deviceHeadingDeferred: false,
            deviceHeadingDegrees: 190,
            deviceHeadingAccuracyDegrees: 8,
            deviceHeadingTimestamp: timestamp,
            deviceHeadingTimestampMillisecondsSince1970: Int64((timestamp.timeIntervalSince1970 * 1_000).rounded()),
            deviceHeadingAgeSeconds: 0.4,
            deviceHeadingReliableForRouteContinuity: true,
            courseDeviceHeadingDeltaDegrees: 6,
            courseDeviceHeadingAgreement: true
        )

        let encoded = try JSONEncoder().encode(diagnostics)
        let json = String(data: encoded, encoding: .utf8) ?? ""
        XCTAssertTrue(json.contains("deviceHeadingDegrees"))
        XCTAssertTrue(json.contains("courseAndDeviceMagnetometer"))
        XCTAssertTrue(json.contains("courseDeviceHeadingAgreement"))

        let decoded = try JSONDecoder().decode(HeadingDiagnostics.self, from: encoded)
        XCTAssertEqual(decoded.source, .courseAndDeviceMagnetometer)
        XCTAssertEqual(decoded.deviceHeadingDegrees ?? .nan, 190, accuracy: 0.001)
        XCTAssertEqual(decoded.deviceHeadingReliableForRouteContinuity, true)
        XCTAssertEqual(decoded.hasReliableHeadingForRouteContinuity, true)
    }

    func testB13B1HeadingDiagnosticsDecodesLegacyB13BPayload() throws {
        let legacyJSON = Data("""
        {
          "source": "coreLocationCourse",
          "headingAvailable": true,
          "courseOverGroundDegrees": 92.5,
          "courseAccuracyDegrees": 14.0,
          "coreLocationSpeedKmh": 6.4,
          "courseReliableForRouteContinuity": true,
          "deviceHeadingDeferred": true
        }
        """.utf8)

        let decoded = try JSONDecoder().decode(HeadingDiagnostics.self, from: legacyJSON)

        XCTAssertEqual(decoded.source, .coreLocationCourse)
        XCTAssertEqual(decoded.courseOverGroundDegrees ?? .nan, 92.5, accuracy: 0.001)
        XCTAssertEqual(decoded.courseReliableForRouteContinuity, true)
        XCTAssertEqual(decoded.deviceHeadingDeferred, true)
        XCTAssertEqual(decoded.deviceHeadingReliableForRouteContinuity, false)
        XCTAssertNil(decoded.deviceHeadingDegrees)
        XCTAssertNil(decoded.courseDeviceHeadingAgreement)
        XCTAssertEqual(decoded.hasReliableHeadingForRouteContinuity, true)
    }

    private func makeCompletedSession() throws -> SessionData {
        let startDate = Date(timeIntervalSince1970: 1_700_000_000)

        func makeLocationDiagnostics(
            speedKmh: Double,
            timestamp: Date,
            courseDegrees: Double
        ) -> LocationFixDiagnostics {
            let headingDiagnostics = HeadingDiagnostics(
                source: .coreLocationCourse,
                headingAvailable: true,
                courseOverGroundDegrees: courseDegrees,
                courseAccuracyDegrees: 10,
                coreLocationSpeedKmh: speedKmh,
                courseReliableForRouteContinuity: true,
                deviceHeadingDeferred: true
            )

            let gpsGapDiagnostics = GPSGapDiagnostics(
                classification: .normalCadence,
                gapSeconds: 1.0,
                isTimerFusionRepeat: false,
                rawLocationAvailable: true
            )

            let deadReckoningDiagnostics = DeadReckoningDiagnostics(
                estimatedRouteActive: false,
                eligibleForFutureEstimation: false,
                anchorAvailable: true,
                gapSeconds: 1.0,
                headingAvailable: true,
                reason: .normalCadence
            )

            return LocationFixDiagnostics(
                horizontalAccuracyMeters: 5,
                verticalAccuracyMeters: 8,
                speedAccuracyMetersPerSecond: 1,
                courseAccuracyDegrees: 10,
                rawLocationTimestamp: timestamp,
                receivedAtTimestamp: timestamp,
                gpsUpdateIntervalSeconds: 1.0,
                gpsSegmentDistanceMeters: 6,
                coordinateDerivedSpeedKmh: speedKmh,
                speedSource: .coreLocation,
                freshnessState: .fresh,
                routeSegmentConfidence: .high,
                headingDiagnostics: headingDiagnostics,
                gpsGapDiagnostics: gpsGapDiagnostics,
                deadReckoningDiagnostics: deadReckoningDiagnostics
            )
        }

        let firstSampleTimestamp = startDate.addingTimeInterval(1)
        let secondSampleTimestamp = startDate.addingTimeInterval(2)

        let samples = [
            MotionSample(
                timestamp: firstSampleTimestamp,
                gpsCoordinate: GeoCoordinate(latitude: 25.033, longitude: 121.565),
                speedKmh: 8,
                accelerometerG: ThreeAxisValue(x: 0, y: 0, z: 1),
                gyroscopeRadPS: ThreeAxisValue(x: 0, y: 0, z: 0),
                altitudeMeters: 12,
                altitudeSource: .coreLocationAbsolute,
                altitudeDiagnostics: AltitudeDiagnostics(
                    source: .coreLocationAbsolute,
                    trustClassification: .trusted,
                    reason: .firstTrustedAnchor,
                    rawAltitudeMeters: 12,
                    trustedAltitudeMeters: 12,
                    verticalAccuracyMeters: 8,
                    updatesTrustedAltitudeAnchor: true
                ),
                locationDiagnostics: makeLocationDiagnostics(
                    speedKmh: 8,
                    timestamp: firstSampleTimestamp,
                    courseDegrees: 90
                )
            ),
            MotionSample(
                timestamp: secondSampleTimestamp,
                gpsCoordinate: GeoCoordinate(latitude: 25.034, longitude: 121.566),
                speedKmh: 12,
                accelerometerG: ThreeAxisValue(x: 0.1, y: 0, z: 1),
                gyroscopeRadPS: ThreeAxisValue(x: 0, y: 0.1, z: 0),
                altitudeMeters: 13,
                altitudeSource: .coreLocationAbsolute,
                altitudeDiagnostics: AltitudeDiagnostics(
                    source: .coreLocationAbsolute,
                    trustClassification: .trusted,
                    reason: .coreLocationAbsoluteAccepted,
                    rawAltitudeMeters: 13,
                    trustedAltitudeMeters: 13,
                    previousTrustedAltitudeMeters: 12,
                    verticalAccuracyMeters: 8,
                    altitudeDeltaMeters: 1,
                    timeDeltaSeconds: 1,
                    verticalSpeedMetersPerSecond: 1,
                    updatesTrustedAltitudeAnchor: true
                ),
                locationDiagnostics: makeLocationDiagnostics(
                    speedKmh: 12,
                    timestamp: secondSampleTimestamp,
                    courseDegrees: 92
                )
            )
        ]

        let fallEvent = FallEvent(
            timestamp: secondSampleTimestamp,
            peakImpactGForce: 4.2,
            locationCoordinate: samples.last?.gpsCoordinate,
            recoveryDurationSeconds: 3,
            sportMode: .skateboard(.streetPark),
            userConfirmed: false
        )
        let spotID = UUID()
        let spotSnapshot = SpotSessionSnapshot(
            spotID: spotID,
            name: "Test Skate Park",
            activityFamily: .mixed,
            coordinate: samples.last?.gpsCoordinate,
            radiusMeters: 150
        )
        let debugDiagnostics = RecordingDebugDiagnostics(
            buildIdentity: RecordingDebugBuildIdentity(
                debugBuildTaskID: RecordingDebugBuildIdentity.currentDebugBuildTaskID
            ),
            testContext: RecordingDebugTestContext(label: .handheldScreenOn),
            diagnosticsStartedAt: startDate,
            diagnosticsEndedAt: startDate.addingTimeInterval(60),
            diagnosticsStatus: "enabled",
            appLifecycleEvents: [
                RecordingDebugLifecycleEvent(
                    timestamp: startDate,
                    eventType: "testSessionStarted"
                )
            ],
            recordingHeartbeats: [],
            authorizationSnapshots: [],
            locationManagerSnapshots: [],
            locationCallbackEvents: [],
            gapEvents: [],
            recoveryEvents: [],
            filterDecisionSummary: RecordingDebugFilterDecisionSummary(acceptedLocationFixCount: 2),
            altitudeDiagnostics: RecordingDebugAltitudeDiagnostics(
                altitudeSourceCounts: ["coreLocationAbsolute": 2],
                coreLocationAltitudeAcceptedCount: 2
            )
        )

        return try SessionData(
            startDate: startDate,
            endDate: startDate.addingTimeInterval(60),
            sportMode: .skateboard(.streetPark),
            powerType: .humanPowered,
            motionSamples: samples,
            fallEvents: [fallEvent],
            summaryMetrics: SessionSummaryMetrics(
                distanceKilometers: 0.42,
                maxSpeedKilometersPerHour: 12,
                averageSpeedKilometersPerHour: 10,
                elevationGainMeters: 1,
                movingRatio: 0.8
            ),
            debugRecordingDiagnostics: debugDiagnostics,
            spotID: spotID,
            spotSnapshot: spotSnapshot
        )
    }
}
