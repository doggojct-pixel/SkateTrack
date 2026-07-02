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


    func testB14ADeadReckoningReadinessAnalyzerClassifiesReplayEligibleGap() {
        let samples = makeB14AReadinessSamples(headingDiagnostics: makeB14AReliableHeadingDiagnostics())
        let summary = DeadReckoningReadinessAnalyzer.analyze(samples: samples)

        XCTAssertEqual(summary.totalSamples, samples.count)
        XCTAssertEqual(summary.locationFixSampleCount, 2)
        XCTAssertEqual(summary.timerFusionSampleCount, 50)
        XCTAssertEqual(summary.gapCandidateCount, 1)
        XCTAssertEqual(summary.replayEligibleGapCount, 1)
        XCTAssertEqual(summary.blockedGapCount, 0)
        XCTAssertEqual(summary.candidates.first?.blockingReason, .noBlockingReason)
        XCTAssertEqual(summary.candidates.first?.eligibleForReplay, true)
        XCTAssertEqual(summary.candidates.first?.imuSampleCount, 50)
        XCTAssertEqual(summary.candidates.first?.imuCadenceHz ?? 0, 10, accuracy: 0.01)
    }

    func testB14ADeadReckoningReadinessAnalyzerBlocksMissingHeading() {
        let samples = makeB14AReadinessSamples(headingDiagnostics: nil)
        let summary = DeadReckoningReadinessAnalyzer.analyze(samples: samples)

        XCTAssertEqual(summary.gapCandidateCount, 1)
        XCTAssertEqual(summary.replayEligibleGapCount, 0)
        XCTAssertEqual(summary.blockedGapCount, 1)
        XCTAssertEqual(summary.candidates.first?.blockingReason, .headingUnavailable)
        XCTAssertEqual(summary.blockingReasonCounts[.headingUnavailable], 1)
    }

    func testB14ADeadReckoningReadinessAnalyzerDoesNotMutateSamplesOrEnableRouteEstimation() {
        let samples = makeB14AReadinessSamples(headingDiagnostics: makeB14AReliableHeadingDiagnostics())
        let originalSamples = samples
        let summary = DeadReckoningReadinessAnalyzer.analyze(samples: samples)

        XCTAssertEqual(samples, originalSamples)
        XCTAssertEqual(summary.replayEligibleGapCount, 1)
        XCTAssertFalse(
            samples.contains { $0.locationDiagnostics?.deadReckoningDiagnostics?.estimatedRouteActive == true },
            "Task-030c-b14-A must remain replay-only and must not enable estimated route geometry."
        )
    }


    func testB14BCandidateInterpolationProducesDebugOnlyPoints() {
        let samples = makeB14AReadinessSamples(headingDiagnostics: makeB14AReliableHeadingDiagnostics())
        let originalSamples = samples
        let summary = DeadReckoningCandidateInterpolationAnalyzer.analyze(samples: samples)

        XCTAssertEqual(samples, originalSamples)
        XCTAssertEqual(summary.totalReadinessCandidateCount, 1)
        XCTAssertEqual(summary.debugCandidateCount, 1)
        XCTAssertEqual(summary.blockedCandidateCount, 0)
        XCTAssertEqual(summary.results.first?.status, .debugCandidateOnly)
        XCTAssertNotEqual(summary.results.first?.confidence, .blocked)
        XCTAssertEqual(summary.results.first?.readinessBlockingReason, .noBlockingReason)
        XCTAssertGreaterThan(summary.results.first?.candidatePointCount ?? 0, 0)
        XCTAssertFalse(
            samples.contains { $0.locationDiagnostics?.deadReckoningDiagnostics?.estimatedRouteActive == true },
            "Task-030c-b15-B-3 must remain replay-only and must not enable production estimated route geometry."
        )
    }

    func testB14BCandidateInterpolationBlocksMissingHeading() {
        let samples = makeB14AReadinessSamples(headingDiagnostics: nil)
        let summary = DeadReckoningCandidateInterpolationAnalyzer.analyze(samples: samples)

        XCTAssertEqual(summary.totalReadinessCandidateCount, 1)
        XCTAssertEqual(summary.debugCandidateCount, 0)
        XCTAssertEqual(summary.blockedCandidateCount, 1)
        XCTAssertEqual(summary.results.first?.status, .blockedByReadiness)
        XCTAssertEqual(summary.results.first?.confidence, .blocked)
        XCTAssertEqual(summary.results.first?.readinessBlockingReason, .headingUnavailable)
        XCTAssertEqual(summary.results.first?.candidatePointCount, 0)
    }

    func testB14BCandidateInterpolationBlocksLargeAnchorClosure() {
        let samples = makeB14AReadinessSamples(headingDiagnostics: makeB14AReliableHeadingDiagnostics())
        let summary = DeadReckoningCandidateInterpolationAnalyzer.analyze(
            samples: samples,
            interpolationConfig: DeadReckoningCandidateInterpolationConfig(maximumAnchorClosureDistanceMeters: 1)
        )

        XCTAssertEqual(summary.totalReadinessCandidateCount, 1)
        XCTAssertEqual(summary.debugCandidateCount, 0)
        XCTAssertEqual(summary.blockedCandidateCount, 1)
        XCTAssertEqual(summary.results.first?.status, .anchorClosureTooLarge)
        XCTAssertEqual(summary.results.first?.confidence, .blocked)
        XCTAssertEqual(summary.results.first?.candidatePointCount, 0)
    }

    func testB14B1DisplayElevationGainPrefersTrustedBarometerOverCoreLocationJitter() throws {
        let start = Date(timeIntervalSince1970: 1_700_300_000)
        let samples = [
            makeB14B1AltitudeSample(start: start, offset: 0, altitude: 0.00, source: .barometerRelative),
            makeB14B1AltitudeSample(start: start, offset: 1, altitude: 10.0, source: .coreLocationAbsolute),
            makeB14B1AltitudeSample(start: start, offset: 2, altitude: 0.25, source: .barometerRelative),
            makeB14B1AltitudeSample(start: start, offset: 3, altitude: 11.0, source: .coreLocationAbsolute),
            makeB14B1AltitudeSample(start: start, offset: 4, altitude: 0.45, source: .barometerRelative),
            makeB14B1AltitudeSample(start: start, offset: 5, altitude: 10.0, source: .coreLocationAbsolute),
            makeB14B1AltitudeSample(start: start, offset: 6, altitude: 0.55, source: .barometerRelative),
            makeB14B1AltitudeSample(start: start, offset: 7, altitude: 11.0, source: .coreLocationAbsolute)
        ]
        let session = try makeB14B1SummaryDisplaySession(
            start: start,
            samples: samples,
            persistedElevationGainMeters: 35
        )

        let metrics = SessionSummaryDisplayMetrics.make(session: session, samples: samples)

        XCTAssertEqual(metrics.elevationGainMeters, 0.55, accuracy: 0.001)
        XCTAssertLessThan(metrics.elevationGainMeters, 1)
    }

    func testB14B1DisplayElevationGainCanReturnZeroInsteadOfPersistedInflatedFallback() throws {
        let start = Date(timeIntervalSince1970: 1_700_300_100)
        let samples = [
            makeB14B1AltitudeSample(start: start, offset: 0, altitude: 0.0, source: .barometerRelative),
            makeB14B1AltitudeSample(start: start, offset: 1, altitude: 12.0, source: .coreLocationAbsolute),
            makeB14B1AltitudeSample(start: start, offset: 2, altitude: 0.0, source: .barometerRelative),
            makeB14B1AltitudeSample(start: start, offset: 3, altitude: 13.0, source: .coreLocationAbsolute),
            makeB14B1AltitudeSample(start: start, offset: 4, altitude: 0.0, source: .barometerRelative)
        ]
        let session = try makeB14B1SummaryDisplaySession(
            start: start,
            samples: samples,
            persistedElevationGainMeters: 23
        )

        let metrics = SessionSummaryDisplayMetrics.make(session: session, samples: samples)

        XCTAssertEqual(metrics.elevationGainMeters, 0, accuracy: 0.001)
    }

    private func makeB14B1SummaryDisplaySession(
        start: Date,
        samples: [MotionSample],
        persistedElevationGainMeters: Double
    ) throws -> SessionData {
        try SessionData(
            startDate: start,
            endDate: start.addingTimeInterval(120),
            sportMode: .skateboard(.streetPark),
            powerType: .humanPowered,
            motionSamples: samples,
            summaryMetrics: SessionSummaryMetrics(
                distanceKilometers: 0.13,
                maxSpeedKilometersPerHour: 8.6,
                averageSpeedKilometersPerHour: 3.5,
                elevationGainMeters: persistedElevationGainMeters,
                movingRatio: 0.96
            )
        )
    }

    private func makeB14B1AltitudeSample(
        start: Date,
        offset: TimeInterval,
        altitude: Double,
        source: AltitudeSampleSource
    ) -> MotionSample {
        MotionSample(
            timestamp: start.addingTimeInterval(offset),
            speedKmh: 3.5,
            accelerometerG: ThreeAxisValue(x: 0, y: 0, z: 1),
            gyroscopeRadPS: ThreeAxisValue(x: 0, y: 0, z: 0),
            altitudeMeters: altitude,
            altitudeSource: source,
            altitudeDiagnostics: AltitudeDiagnostics(
                source: source,
                trustClassification: .trusted,
                reason: source == .barometerRelative ? .barometerRelativeAccepted : .coreLocationAbsoluteAccepted,
                rawAltitudeMeters: altitude,
                trustedAltitudeMeters: altitude,
                verticalAccuracyMeters: source == .coreLocationAbsolute ? 4 : nil,
                updatesTrustedAltitudeAnchor: true
            )
        )
    }

    private func makeB14AReliableHeadingDiagnostics() -> HeadingDiagnostics {
        HeadingDiagnostics(
            source: .deviceMagnetometer,
            headingAvailable: true,
            courseOverGroundDegrees: nil,
            courseAccuracyDegrees: nil,
            coreLocationSpeedKmh: nil,
            courseReliableForRouteContinuity: false,
            deviceHeadingDeferred: false,
            deviceHeadingDegrees: 178,
            deviceHeadingAccuracyDegrees: 12,
            deviceHeadingTimestamp: Date(timeIntervalSince1970: 1_700_100_004),
            deviceHeadingTimestampMillisecondsSince1970: 1_700_100_004_000,
            deviceHeadingAgeSeconds: 0.2,
            deviceHeadingReliableForRouteContinuity: true,
            courseDeviceHeadingDeltaDegrees: nil,
            courseDeviceHeadingAgreement: nil
        )
    }

    private func makeB14AReadinessSamples(
        headingDiagnostics: HeadingDiagnostics?
    ) -> [MotionSample] {
        let startDate = Date(timeIntervalSince1970: 1_700_100_000)

        func locationDiagnostics(
            at timestamp: Date,
            gapSeconds: TimeInterval? = nil,
            gapClassification: GPSGapClassification = .normalCadence,
            headingDiagnostics: HeadingDiagnostics? = nil
        ) -> LocationFixDiagnostics {
            LocationFixDiagnostics(
                horizontalAccuracyMeters: 6,
                verticalAccuracyMeters: 10,
                speedAccuracyMetersPerSecond: 1,
                courseAccuracyDegrees: 10,
                rawLocationTimestamp: startDate,
                receivedAtTimestamp: timestamp,
                gpsUpdateIntervalSeconds: gapSeconds,
                gpsSegmentDistanceMeters: 0,
                coordinateDerivedSpeedKmh: 0,
                speedSource: .unavailable,
                freshnessState: .fresh,
                routeSegmentConfidence: .high,
                headingDiagnostics: headingDiagnostics,
                gpsGapDiagnostics: gapSeconds.map {
                    GPSGapDiagnostics(
                        classification: gapClassification,
                        gapSeconds: $0,
                        isTimerFusionRepeat: gapClassification != .normalCadence,
                        rawLocationAvailable: true
                    )
                },
                deadReckoningDiagnostics: DeadReckoningDiagnostics(
                    estimatedRouteActive: false,
                    eligibleForFutureEstimation: false,
                    anchorAvailable: true,
                    gapSeconds: gapSeconds,
                    headingAvailable: headingDiagnostics?.hasReliableHeadingForRouteContinuity == true,
                    reason: .r4RouteReconstructionDeferred
                )
            )
        }

        var samples: [MotionSample] = [
            MotionSample(
                timestamp: startDate,
                gpsCoordinate: GeoCoordinate(latitude: 25.0330, longitude: 121.5650),
                speedKmh: 0,
                accelerometerG: ThreeAxisValue(x: 0, y: 0, z: 1),
                gyroscopeRadPS: ThreeAxisValue(x: 0, y: 0, z: 0),
                locationDiagnostics: locationDiagnostics(
                    at: startDate,
                    gapSeconds: 0.5,
                    gapClassification: .normalCadence,
                    headingDiagnostics: headingDiagnostics
                ),
                sampleSource: .locationFix
            )
        ]

        for index in 1...50 {
            let timestamp = startDate.addingTimeInterval(Double(index) * 0.1)
            let isGapCandidate = index == 50
            samples.append(
                MotionSample(
                    timestamp: timestamp,
                    gpsCoordinate: GeoCoordinate(latitude: 25.0330, longitude: 121.5650),
                    speedKmh: 0,
                    accelerometerG: ThreeAxisValue(x: 0.01, y: 0.02, z: 1.0),
                    gyroscopeRadPS: ThreeAxisValue(x: 0.01, y: 0, z: 0),
                    locationDiagnostics: isGapCandidate ? locationDiagnostics(
                        at: timestamp,
                        gapSeconds: 5.0,
                        gapClassification: .shortGap,
                        headingDiagnostics: headingDiagnostics
                    ) : nil,
                    sampleSource: .timerFusion
                )
            )
        }

        samples.append(
            MotionSample(
                timestamp: startDate.addingTimeInterval(6),
                gpsCoordinate: GeoCoordinate(latitude: 25.0331, longitude: 121.5651),
                speedKmh: 2,
                accelerometerG: ThreeAxisValue(x: 0, y: 0, z: 1),
                gyroscopeRadPS: ThreeAxisValue(x: 0, y: 0, z: 0),
                locationDiagnostics: locationDiagnostics(
                    at: startDate.addingTimeInterval(6),
                    gapSeconds: 1.0,
                    gapClassification: .normalCadence,
                    headingDiagnostics: headingDiagnostics
                ),
                sampleSource: .locationFix
            )
        )

        return samples
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
