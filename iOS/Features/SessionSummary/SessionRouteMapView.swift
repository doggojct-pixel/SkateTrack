// [協作區] SessionRouteMapView.swift
// 用途：呈現 Task-018b Session Summary 的 MapKit 路線預覽、起點與終點標記。
// 委派至：SessionSummaryView 提供 motion samples；Task-030c-b13-A-4 keeps post-record GPS lock guarding, approximate start semantics, and absolute-display metrics and updated warm-up / low-confidence route color semantics。

import MapKit
import SwiftUI

private struct RouteDisplayPoint: Identifiable {
    let id: Int
    let rawCoordinate: CLLocationCoordinate2D
    let displayCoordinate: CLLocationCoordinate2D
    let timestamp: Date
    let confidence: RouteSegmentConfidence
    let horizontalAccuracyMeters: Double?
    let isStartupWarmup: Bool

    var segmentStyle: RouteMapSegmentStyle {
        if isStartupWarmup { return .startupWarmup }
        return confidence == .low || confidence == .unavailable ? .uncertain : .trusted
    }

    var isReliableAnchor: Bool {
        !isStartupWarmup && segmentStyle == .trusted
    }
}

private enum RouteMapSegmentStyle {
    case trusted
    case uncertain
    case startupWarmup

    private static let fluorescentPink = Color(red: 1.0, green: 0.2, blue: 0.6)
    private static let brightOrange = Color(red: 1.0, green: 0.56, blue: 0.0)

    var lineWidth: CGFloat { 4 }
    var opacity: Double { 1 }
    var dash: [CGFloat] { [] }
    var color: Color {
        switch self {
        case .trusted:
            return SkateTrackSessionStartColors.teal
        case .uncertain:
            return Self.brightOrange
        case .startupWarmup:
            return Self.fluorescentPink
        }
    }
}

private struct RouteMapSegment: Identifiable {
    let id: Int
    let coordinates: [CLLocationCoordinate2D]
    let style: RouteMapSegmentStyle
}

private struct RouteStartMarkerState {
    let coordinate: CLLocationCoordinate2D
    let isApproximate: Bool
}

struct SessionRouteMapView: View {
    let session: SessionData
    let samples: [MotionSample]

    private var fidelityPolicy: ActivityFidelityPolicy {
        ActivityFidelityPolicy(
            profile: session.fidelityProfile
                ?? ActivityFidelityProfile.defaultProfile(for: session.sportMode, powerType: session.powerType)
        )
    }

    private var rawRouteCoordinates: [CLLocationCoordinate2D] {
        samples.compactMap(validCoordinate)
    }

    private static let startupStableAnchorHoldSeconds: TimeInterval = 12
    private static let startupStableAnchorClusterWindowSeconds: TimeInterval = 7
    private static let startupStableAnchorMinimumCandidateCount = 3
    private static let startupGPSLockSearchWindowSeconds: TimeInterval = 60
    private static let startupConvergenceWarmupSeconds: TimeInterval = 45
    private static let approximateStartLockDelaySeconds: TimeInterval = 5
    private static let startupRouteVisualSuppressionMaximumSeconds: TimeInterval = 45


    private var displayRoutePoints: [RouteDisplayPoint] {
        makeDisplayRoutePoints(from: samples)
    }

    private var displayRouteCoordinates: [CLLocationCoordinate2D] {
        displayRoutePoints.map(\.displayCoordinate)
    }

    private var displayRouteSegments: [RouteMapSegment] {
        makeRouteSegments(from: displayRoutePoints)
    }

    private var reliableDisplayRouteCoordinates: [CLLocationCoordinate2D] {
        displayRoutePoints.filter { $0.isReliableAnchor }.map(\.displayCoordinate)
    }

    var body: some View {
        let rawCoordinates = rawRouteCoordinates
        let coordinates = displayRouteCoordinates
        let reliableCoordinates = reliableDisplayRouteCoordinates
        let gpsLockCoordinates = gpsLockRouteCoordinates
        let regionCoordinates = primaryMapRegionCoordinates(reliableCoordinates: reliableCoordinates, gpsLockCoordinates: gpsLockCoordinates)
        let startMarkerState = routeStartMarkerState()
        let startCoordinate = startMarkerState?.coordinate
        let startIsApproximate = startMarkerState?.isApproximate ?? false
        let finishCoordinate = coordinates.last
        let segments = displayRouteSegments

        VStack(alignment: .leading, spacing: 12) {
            header(coordinateCount: coordinates.count, rawCoordinateCount: rawCoordinates.count)

            if coordinates.count >= 2 {
                routeMap(
                    regionCoordinates: regionCoordinates,
                    startCoordinate: startCoordinate,
                    startIsApproximate: startIsApproximate,
                    finishCoordinate: finishCoordinate,
                    segments: segments
                )
            } else {
                emptyRouteState
            }
        }
        .padding(16)
        .background(SkateTrackSessionStartColors.card.opacity(0.78))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(SkateTrackSessionStartColors.border.opacity(0.85), lineWidth: 1))
        .accessibilityIdentifier("session-route-map-view")
    }

    private func header(coordinateCount: Int, rawCoordinateCount: Int) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 8) {
                Image(systemName: "map.fill")
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(SkateTrackSessionStartColors.teal)

                Text("summary.route.map.title")
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Spacer()

                Text(routeSampleCountText(coordinateCount))
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .foregroundStyle(SkateTrackSessionStartColors.textTertiary)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.06))
                    .clipShape(Capsule())
                    .accessibilityLabel("display route points: \(coordinateCount), raw route points: \(rawCoordinateCount)")
            }

            Text(LocalizedStringKey(coordinateCount >= 2 ? "summary.route.map.subtitle" : "summary.route.empty.subtitle"))
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            if let disclosure = routeAccuracyDisclosureText() {
                HStack(spacing: 6) {
                    Image(systemName: "scope")
                        .font(.system(size: 10, weight: .bold))
                    Text(disclosure)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                }
                .foregroundStyle(SkateTrackSessionStartColors.amber)
                .padding(.horizontal, 9)
                .padding(.vertical, 6)
                .background(SkateTrackSessionStartColors.amber.opacity(0.12))
                .clipShape(Capsule())
                .accessibilityIdentifier("session-route-accuracy-disclosure")
            }
        }
    }

    private func routeMap(
        regionCoordinates: [CLLocationCoordinate2D],
        startCoordinate: CLLocationCoordinate2D?,
        startIsApproximate: Bool,
        finishCoordinate: CLLocationCoordinate2D?,
        segments: [RouteMapSegment]
    ) -> some View {
        Map(initialPosition: .region(region(for: regionCoordinates))) {
            ForEach(segments) { segment in
                if segment.coordinates.count >= 2 {
                    MapPolyline(coordinates: segment.coordinates)
                        .stroke(
                            segment.style.color.opacity(segment.style.opacity),
                            style: StrokeStyle(lineWidth: segment.style.lineWidth, lineCap: .round, lineJoin: .round, dash: segment.style.dash)
                        )
                }
            }

            if let start = startCoordinate {
                Annotation(NSLocalizedString("summary.route.start", comment: ""), coordinate: start, anchor: .center) {
                    if startIsApproximate {
                        routePin(systemImage: "play.circle", color: SkateTrackSessionStartColors.teal.opacity(0.66))
                    } else {
                        routePin(systemImage: "play.fill", color: SkateTrackSessionStartColors.teal)
                    }
                }
            }

            if let finish = finishCoordinate {
                Annotation(NSLocalizedString("summary.route.finish", comment: ""), coordinate: finish, anchor: .center) {
                    routePin(systemImage: "flag.checkered", color: SkateTrackSessionStartColors.amber)
                }
            }
        }
        .frame(height: 214)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(SkateTrackSessionStartColors.border.opacity(0.72), lineWidth: 1))
        .accessibilityIdentifier("session-route-map-rendered")
    }

    private var emptyRouteState: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "location.slash.fill")
                .font(.system(size: 18, weight: .black))
                .foregroundStyle(SkateTrackSessionStartColors.textTertiary)
                .frame(width: 36, height: 36)
                .background(Color.white.opacity(0.06))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 5) {
                Text("summary.route.empty.title")
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Text("summary.route.empty.detail")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(Color.white.opacity(0.045))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .accessibilityIdentifier("session-route-map-empty")
    }

    private func routePin(systemImage: String, color: Color) -> some View {
        Image(systemName: systemImage)
            .font(.system(size: 12, weight: .black))
            .foregroundStyle(.white)
            .frame(width: 28, height: 28)
            .background(color)
            .clipShape(Circle())
            .shadow(color: color.opacity(0.45), radius: 10, x: 0, y: 0)
    }

    private func makeDisplayRoutePoints(from samples: [MotionSample]) -> [RouteDisplayPoint] {
        let candidates = deduplicatedTrustedLocationFixes(from: samples)
        guard !candidates.isEmpty else { return [] }

        let gpsLockAnchorTimestamp = firstGPSLockAnchorTimestamp(from: candidates)
        let stableStartupAnchorTimestamp = firstStableStartupAnchorTimestamp(
            from: candidates,
            gpsLockAnchorTimestamp: gpsLockAnchorTimestamp
        )
        var displayPoints: [RouteDisplayPoint] = []
        var previousDisplayCoordinate: CLLocationCoordinate2D?
        var previousRawCoordinate: CLLocationCoordinate2D?
        var pointID = 0

        for sample in candidates {
            guard let rawCoordinate = validCoordinate(from: sample) else { continue }
            let confidence = sample.locationDiagnostics?.routeSegmentConfidence ?? .medium
            let hasReliableAnchor = displayPoints.contains(where: { $0.isReliableAnchor })
            let isStartupWarmup = isStartupWarmupSample(
                sample,
                stableStartupAnchorTimestamp: stableStartupAnchorTimestamp,
                gpsLockAnchorTimestamp: gpsLockAnchorTimestamp,
                hasReliableAnchor: hasReliableAnchor
            )
            let isFirstReliableAnchor = !hasReliableAnchor
                && !isStartupWarmup
                && confidence != .low
                && confidence != .unavailable

            if !isFirstReliableAnchor,
               let previousDisplayCoordinate,
               let previousRawCoordinate,
               shouldSuppressSmallAreaJitter(
                   from: previousRawCoordinate,
                   previousDisplayCoordinate: previousDisplayCoordinate,
                   to: rawCoordinate,
                   sample: sample
               ) {
                continue
            }

            let displayCoordinate: CLLocationCoordinate2D
            if isFirstReliableAnchor {
                // Task-030c-b11-r3-3: reset display smoothing at the first stable
                // post-start anchor so red warm-up drift cannot pull the trusted start.
                displayCoordinate = rawCoordinate
            } else if let previousDisplayCoordinate {
                displayCoordinate = smoothDisplayCoordinate(
                    previous: previousDisplayCoordinate,
                    current: rawCoordinate,
                    sample: sample
                )
            } else {
                displayCoordinate = rawCoordinate
            }

            displayPoints.append(RouteDisplayPoint(
                id: pointID,
                rawCoordinate: rawCoordinate,
                displayCoordinate: displayCoordinate,
                timestamp: routeTimestamp(for: sample),
                confidence: confidence,
                horizontalAccuracyMeters: sample.locationDiagnostics?.horizontalAccuracyMeters,
                isStartupWarmup: isStartupWarmup
            ))
            previousRawCoordinate = rawCoordinate
            previousDisplayCoordinate = displayCoordinate
            pointID += 1
        }

        return displayPoints
    }

    private func deduplicatedTrustedLocationFixes(from samples: [MotionSample]) -> [MotionSample] {
        let primary = deduplicatedTrustedLocationFixes(from: samples, allowsTimerFusionFallback: false)
        if !primary.isEmpty { return primary }
        return deduplicatedTrustedLocationFixes(from: samples, allowsTimerFusionFallback: true)
    }

    private func deduplicatedTrustedLocationFixes(
        from samples: [MotionSample],
        allowsTimerFusionFallback: Bool
    ) -> [MotionSample] {
        var seenKeys = Set<String>()
        return samples
            .sorted(by: { routeTimestamp(for: $0) < routeTimestamp(for: $1) })
            .compactMap { sample -> MotionSample? in
                guard validCoordinate(from: sample) != nil,
                      isTrustedDisplayRouteSample(sample, allowsTimerFusionFallback: allowsTimerFusionFallback) else { return nil }
                let key = locationFixKey(for: sample)
                guard seenKeys.insert(key).inserted else { return nil }
                return sample
            }
    }

    private func isStartupWarmupSample(
        _ sample: MotionSample,
        stableStartupAnchorTimestamp: Date?,
        gpsLockAnchorTimestamp: Date?,
        hasReliableAnchor: Bool
    ) -> Bool {
        let timestamp = routeTimestamp(for: sample)
        let elapsed = timestamp.timeIntervalSince(session.startDate)

        // Task-030c-b11-r3-3: pre-start CoreLocation cached fixes stay visible as
        // approximate warm-up context but never become route anchors or primary region drivers.
        if elapsed < 0 {
            return elapsed >= -10
        }

        guard !hasReliableAnchor else { return false }
        guard elapsed <= Self.startupConvergenceWarmupSeconds else { return false }
        guard let diagnostics = sample.locationDiagnostics else { return elapsed <= 8 }

        let accuracy = diagnostics.horizontalAccuracyMeters ?? .infinity
        let warmupAccuracyLimit = max(fidelityPolicy.preferredHorizontalAccuracyMeters * 1.8, 18)
        if diagnostics.freshnessState == .stale { return true }
        if diagnostics.routeSegmentConfidence == .low || diagnostics.routeSegmentConfidence == .unavailable { return true }
        if accuracy > warmupAccuracyLimit { return true }

        // Task-030c-b11-r3-3: after the user presses Record, CoreLocation can still
        // need several seconds to converge, especially after the screen is locked and
        // the phone is placed in a pocket. Do not let medium convergence fixes become
        // green trusted route geometry before a real GPS-lock cluster exists.
        if startupAnchorGuardApplies() {
            guard let stableStartupAnchorTimestamp else {
                return elapsed <= Self.startupConvergenceWarmupSeconds && !isPreferredFreshAnchor(sample)
            }
            if timestamp < stableStartupAnchorTimestamp { return true }
            // Task-030c-b15-A: keep the first seconds after GPS lock visually
            // conservative if the session only just escaped startup convergence.
            // This is display-only and does not delete raw GPS samples or rewrite
            // distance, speed, altitude, route geometry, or exported diagnostics.
            return elapsed <= Self.startupRouteVisualSuppressionMaximumSeconds
                && timestamp.timeIntervalSince(stableStartupAnchorTimestamp) <= 3
                && !isPreferredFreshAnchor(sample)
        }

        if let gpsLockAnchorTimestamp {
            return timestamp < gpsLockAnchorTimestamp
        }

        // Before the first reliable anchor, recent/medium startup points remain solid
        // fluorescent-pink warm-up context instead of trusted anchors.
        let isEarlyStartupWindow = elapsed <= 10
        return isEarlyStartupWindow && !isPreferredFreshAnchor(sample)
    }

    private func firstStableStartupAnchorTimestamp(
        from candidates: [MotionSample],
        gpsLockAnchorTimestamp: Date?
    ) -> Date? {
        guard startupAnchorGuardApplies() else { return nil }
        return gpsLockAnchorTimestamp
    }

    private func startupAnchorGuardApplies() -> Bool {
        switch fidelityPolicy.profile {
        case .technicalSkateboard, .standardSkateboard, .electricSkateboard, .inlineRecreation:
            return true
        case .inlineSpeed, .snowReserved, .vehicleValidation:
            return fidelityPolicy.usesStrictSmallAreaLowSpeedGate
        }
    }

    private func firstGPSLockAnchorTimestamp(from candidates: [MotionSample]) -> Date? {
        let lockCandidates = candidates.filter { sample in
            let elapsed = routeTimestamp(for: sample).timeIntervalSince(session.startDate)
            return elapsed >= 0
                && elapsed <= Self.startupGPSLockSearchWindowSeconds
                && isPreferredFreshAnchor(sample)
        }
        guard lockCandidates.count >= Self.startupStableAnchorMinimumCandidateCount else { return nil }

        for candidate in lockCandidates {
            let anchorTime = routeTimestamp(for: candidate)
            let cluster = lockCandidates.filter { sample in
                let delta = routeTimestamp(for: sample).timeIntervalSince(anchorTime)
                return delta >= 0 && delta <= Self.startupStableAnchorClusterWindowSeconds
            }
            guard cluster.count >= Self.startupStableAnchorMinimumCandidateCount else { continue }
            // Offline summary rendering can use the first point in the confirmed cluster:
            // the later cluster points prove it was stable, but the route can begin at
            // the earliest confirmed GPS-lock coordinate instead of the third sample.
            return anchorTime
        }

        return nil
    }

    private func isPreferredFreshAnchor(_ sample: MotionSample) -> Bool {
        guard let diagnostics = sample.locationDiagnostics else { return false }
        let accuracy = diagnostics.horizontalAccuracyMeters ?? .infinity
        return diagnostics.freshnessState == .fresh
            && diagnostics.routeSegmentConfidence == .high
            && accuracy <= fidelityPolicy.preferredHorizontalAccuracyMeters
    }

    private func isTrustedDisplayRouteSample(_ sample: MotionSample, allowsTimerFusionFallback: Bool) -> Bool {
        guard allowsTimerFusionFallback || sample.sampleSource != .timerFusion || sample.locationDiagnostics?.rawLocationTimestampMillisecondsSince1970 == nil else {
            // Task-030c-b11-r3-3: prefer raw location fixes over timer-fusion repeats when the
            // underlying location timestamp is available. This keeps displayRoute distinct
            // from rawRoute while preserving raw samples in diagnostics/export.
            return false
        }

        guard let diagnostics = sample.locationDiagnostics else { return true }
        if diagnostics.freshnessState == .stale { return false }
        // Task-030c-b15-A: low-confidence fixes remain visible as bright-orange uncertain route segments; startup/warm-up fixes are restored to solid fluorescent-pink route context while staying separated from trusted GPS-lock geometry.
        if diagnostics.gpsUpdateIntervalSeconds.map({ $0 > max(12, fidelityPolicy.maximumTrustedUpdateIntervalSeconds + 4) }) == true { return false }
        if diagnostics.horizontalAccuracyMeters.map({ $0 > fidelityPolicy.displayRouteMaximumHorizontalAccuracyMeters }) == true { return false }
        if diagnostics.coordinateDerivedSpeedKmh.map({ $0 > fidelityPolicy.maximumTrustedImpliedSpeedKmh }) == true { return false }
        return true
    }

    private func makeRouteSegments(from points: [RouteDisplayPoint]) -> [RouteMapSegment] {
        var segments: [RouteMapSegment] = []
        var currentCoordinates: [CLLocationCoordinate2D] = []
        var currentStyle: RouteMapSegmentStyle?
        var segmentID = 0
        var previousPoint: RouteDisplayPoint?

        for point in points.sorted(by: { $0.timestamp < $1.timestamp }) {
            let pointStyle = point.segmentStyle
            // Task-030c-b15-A: startup warm-up geometry remains available as
            // solid fluorescent-pink context with full route-line weight. It stays
            // semantically separated from trusted teal geometry and does not bridge
            // into the first trusted GPS-lock segment.
            if let previousPoint, shouldStartNewRouteSegment(after: previousPoint, current: point) {
                appendSegmentIfNeeded(currentCoordinates, style: currentStyle ?? .trusted, id: segmentID, to: &segments)
                currentCoordinates = []
                currentStyle = pointStyle
                segmentID += 1
            } else if let previousPoint,
                      let existingStyle = currentStyle,
                      existingStyle != pointStyle {
                appendSegmentIfNeeded(currentCoordinates, style: existingStyle, id: segmentID, to: &segments)
                // Task-030c-b13-A-4: isolate warm-up/uncertain geometry from
                // the trusted route. Do not draw the first trusted segment from the
                // previous low-quality point, because that makes startup drift look
                // like confirmed route geometry.
                currentCoordinates = pointStyle == .trusted ? [] : [previousPoint.displayCoordinate]
                currentStyle = pointStyle
                segmentID += 1
            } else if currentStyle == nil {
                currentStyle = pointStyle
            }

            currentCoordinates.append(point.displayCoordinate)
            previousPoint = point
        }

        appendSegmentIfNeeded(currentCoordinates, style: currentStyle ?? .trusted, id: segmentID, to: &segments)
        return segments
    }

    private func validCoordinate(from sample: MotionSample) -> CLLocationCoordinate2D? {
        guard let coordinate = sample.gpsCoordinate,
              coordinate.latitude.isFinite,
              coordinate.longitude.isFinite,
              (-90.0...90.0).contains(coordinate.latitude),
              (-180.0...180.0).contains(coordinate.longitude) else {
            return nil
        }

        return CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }

    private func shouldStartNewRouteSegment(after previousPoint: RouteDisplayPoint, current point: RouteDisplayPoint) -> Bool {
        if point.timestamp.timeIntervalSince(previousPoint.timestamp) > 12 { return true }
        let rawDistance = distanceMeters(from: previousPoint.rawCoordinate, to: point.rawCoordinate)
        let displayDistance = distanceMeters(from: previousPoint.displayCoordinate, to: point.displayCoordinate)
        return rawDistance > 55 && displayDistance > 40
    }

    private func shouldSuppressSmallAreaJitter(
        from previousRawCoordinate: CLLocationCoordinate2D,
        previousDisplayCoordinate: CLLocationCoordinate2D,
        to rawCoordinate: CLLocationCoordinate2D,
        sample: MotionSample
    ) -> Bool {
        let rawDistance = distanceMeters(from: previousRawCoordinate, to: rawCoordinate)
        let displayDistance = distanceMeters(from: previousDisplayCoordinate, to: rawCoordinate)
        let horizontalAccuracy = sample.locationDiagnostics?.horizontalAccuracyMeters ?? 12
        let speed = max(sample.speedKmh, sample.locationDiagnostics?.coordinateDerivedSpeedKmh ?? 0)
        let jitterThreshold = min(max(horizontalAccuracy * 0.18, 1.25), 4.0)

        guard speed < 4.5 else { return false }
        return rawDistance < jitterThreshold && displayDistance < max(jitterThreshold, 1.75)
    }

    private func smoothDisplayCoordinate(
        previous: CLLocationCoordinate2D,
        current: CLLocationCoordinate2D,
        sample: MotionSample
    ) -> CLLocationCoordinate2D {
        let distance = distanceMeters(from: previous, to: current)
        guard distance.isFinite, distance > 0 else { return previous }

        let horizontalAccuracy = sample.locationDiagnostics?.horizontalAccuracyMeters ?? 12
        let confidence = sample.locationDiagnostics?.routeSegmentConfidence ?? .medium
        let speed = max(sample.speedKmh, sample.locationDiagnostics?.coordinateDerivedSpeedKmh ?? 0)

        let weight: Double
        if distance > 18 || speed > 12 {
            weight = 0.82
        } else if confidence == .high && horizontalAccuracy <= 6 {
            weight = 0.68
        } else if horizontalAccuracy <= 12 {
            weight = 0.52
        } else {
            weight = 0.34
        }

        return interpolatedCoordinate(from: previous, to: current, weight: weight)
    }

    private func interpolatedCoordinate(
        from previous: CLLocationCoordinate2D,
        to current: CLLocationCoordinate2D,
        weight: Double
    ) -> CLLocationCoordinate2D {
        let clampedWeight = min(max(weight, 0), 1)
        return CLLocationCoordinate2D(
            latitude: previous.latitude + (current.latitude - previous.latitude) * clampedWeight,
            longitude: previous.longitude + (current.longitude - previous.longitude) * clampedWeight
        )
    }

    private func appendSegmentIfNeeded(
        _ coordinates: [CLLocationCoordinate2D],
        style: RouteMapSegmentStyle,
        id: Int,
        to segments: inout [RouteMapSegment]
    ) {
        guard coordinates.count >= 2 else { return }
        segments.append(RouteMapSegment(id: id, coordinates: coordinates, style: style))
    }

    private var gpsLockRouteCoordinates: [CLLocationCoordinate2D] {
        guard let gpsLockTimestamp = firstGPSLockAnchorTimestamp(from: deduplicatedTrustedLocationFixes(from: samples)) else { return [] }
        return displayRoutePoints
            .filter { $0.timestamp >= gpsLockTimestamp && $0.isReliableAnchor }
            .map(\.displayCoordinate)
    }

    private var recordingStartDisplayPoint: RouteDisplayPoint? {
        let points = displayRoutePoints.sorted(by: { $0.timestamp < $1.timestamp })
        return points.first(where: { $0.timestamp >= session.startDate }) ?? points.first
    }

    private var recordingStartCoordinate: CLLocationCoordinate2D? {
        recordingStartDisplayPoint?.displayCoordinate
    }

    private var gpsLockCoordinate: CLLocationCoordinate2D? {
        guard let gpsLockTimestamp = firstGPSLockAnchorTimestamp(from: deduplicatedTrustedLocationFixes(from: samples)) else { return nil }
        return displayRoutePoints
            .first(where: { $0.timestamp >= gpsLockTimestamp && $0.isReliableAnchor })?
            .displayCoordinate
    }

    private var gpsLockElapsed: TimeInterval? {
        guard let gpsLockTimestamp = firstGPSLockAnchorTimestamp(from: deduplicatedTrustedLocationFixes(from: samples)) else { return nil }
        return gpsLockTimestamp.timeIntervalSince(session.startDate)
    }

    private var gpsObservedMovementOnsetElapsed: TimeInterval? {
        let fixes = deduplicatedTrustedLocationFixes(from: samples)
        guard !fixes.isEmpty else { return nil }
        let movementSpeedThresholdKmh = gpsObservedMovementSpeedThresholdKmh()
        var consecutiveMovingCount = 0

        for sample in fixes {
            let speed = max(sample.speedKmh, sample.locationDiagnostics?.coordinateDerivedSpeedKmh ?? 0)
            if speed >= movementSpeedThresholdKmh {
                consecutiveMovingCount += 1
                if consecutiveMovingCount >= 3 {
                    return routeTimestamp(for: sample).timeIntervalSince(session.startDate)
                }
            } else {
                consecutiveMovingCount = 0
            }
        }

        return nil
    }

    private func gpsObservedMovementSpeedThresholdKmh() -> Double {
        switch fidelityPolicy.profile {
        case .electricSkateboard, .inlineSpeed:
            return 8
        case .vehicleValidation:
            return 12
        default:
            return 3
        }
    }

    private var isStartApproximate: Bool {
        guard let point = recordingStartDisplayPoint else { return false }
        if point.isStartupWarmup || point.segmentStyle != .trusted { return true }
        if point.horizontalAccuracyMeters.map({ $0 > fidelityPolicy.preferredHorizontalAccuracyMeters }) == true { return true }
        if gpsLockElapsed.map({ $0 > Self.approximateStartLockDelaySeconds }) == true { return true }
        if let gpsLockElapsed, let gpsObservedMovementOnsetElapsed,
           gpsLockElapsed > gpsObservedMovementOnsetElapsed + Self.approximateStartLockDelaySeconds {
            return true
        }
        return false
    }

    private func routeStartMarkerState() -> RouteStartMarkerState? {
        guard let recordingStartCoordinate else { return nil }
        return RouteStartMarkerState(coordinate: recordingStartCoordinate, isApproximate: isStartApproximate)
    }

    private func primaryMapRegionCoordinates(
        reliableCoordinates: [CLLocationCoordinate2D],
        gpsLockCoordinates: [CLLocationCoordinate2D]
    ) -> [CLLocationCoordinate2D] {
        if gpsLockCoordinates.count >= 2 { return gpsLockCoordinates }
        if reliableCoordinates.count >= 2 { return reliableCoordinates }

        let nonWarmupCoordinates = displayRoutePoints
            .filter { !$0.isStartupWarmup }
            .map(\.displayCoordinate)
        if nonWarmupCoordinates.count >= 2 { return nonWarmupCoordinates }

        return displayRouteCoordinates
    }

    private func routeAccuracyDisclosureText() -> String? {
        let points = displayRoutePoints
        guard !points.isEmpty else { return nil }
        if points.contains(where: { $0.isStartupWarmup }) {
            return NSLocalizedString("summary.route.accuracy.startup", comment: "")
        }

        let accuracies = samples
            .compactMap { $0.locationDiagnostics?.horizontalAccuracyMeters }
            .filter { $0.isFinite && $0 > 0 }
            .sorted()
        guard !accuracies.isEmpty else { return nil }

        let medianAccuracy = accuracies[accuracies.count / 2]
        guard fidelityPolicy.usesStrictSmallAreaLowSpeedGate || medianAccuracy >= 8 else { return nil }
        let format = NSLocalizedString("summary.route.accuracy.approxFormat", comment: "")
        return String(format: format, locale: .autoupdatingCurrent, Int(ceil(medianAccuracy)))
    }

    private func region(for coordinates: [CLLocationCoordinate2D]) -> MKCoordinateRegion {
        let latitudes = coordinates.map(\.latitude)
        let longitudes = coordinates.map(\.longitude)
        let minLatitude = latitudes.min() ?? 0
        let maxLatitude = latitudes.max() ?? 0
        let minLongitude = longitudes.min() ?? 0
        let maxLongitude = longitudes.max() ?? 0

        let center = CLLocationCoordinate2D(
            latitude: (minLatitude + maxLatitude) / 2,
            longitude: (minLongitude + maxLongitude) / 2
        )
        let latitudeDelta = max((maxLatitude - minLatitude) * 1.55, 0.006)
        let longitudeDelta = max((maxLongitude - minLongitude) * 1.55, 0.006)

        return MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
        )
    }

    private func locationFixKey(for sample: MotionSample) -> String {
        if let timestamp = sample.locationDiagnostics?.rawLocationTimestampMillisecondsSince1970 {
            return "locationFix:\(timestamp)"
        }

        if let coordinate = sample.gpsCoordinate {
            let latitude = (coordinate.latitude * 100_000).rounded() / 100_000
            let longitude = (coordinate.longitude * 100_000).rounded() / 100_000
            let second = Int(sample.timestamp.timeIntervalSince1970.rounded())
            return "coordinate:\(latitude):\(longitude):\(second)"
        }

        return sample.id.uuidString
    }

    private func routeTimestamp(for sample: MotionSample) -> Date {
        sample.locationDiagnostics?.rawLocationTimestamp ?? sample.timestamp
    }

    private func distanceMeters(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D) -> Double {
        CLLocation(latitude: start.latitude, longitude: start.longitude)
            .distance(from: CLLocation(latitude: end.latitude, longitude: end.longitude))
    }

    private func routeSampleCountText(_ count: Int) -> String {
        let format = NSLocalizedString("summary.route.sampleCountFormat", comment: "")
        return String(format: format, locale: .autoupdatingCurrent, count)
    }
}
