// [協作區] SessionRouteMapView.swift
// 用途：呈現 Task-018b Session Summary 的 MapKit 路線預覽、起點與終點標記。
// 委派至：SessionSummaryView 提供 motion samples；Task-030c-b13-A-4 keeps post-record GPS lock guarding, approximate start semantics, and absolute-display metrics and updated warm-up / low-confidence route color semantics。

import MapKit
import SwiftUI

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

private extension ActivityRouteDisplayPoint {
    var isReliableRouteAnchor: Bool {
        semantic == .highConfidence
    }
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

    private static let approximateStartLockDelaySeconds: TimeInterval = 5

    private var routeDisplayResult: RouteDisplayResult {
        RouteDisplayPipeline().makeDisplayRoute(
            samples: samples,
            startDate: session.startDate,
            fidelityPolicy: fidelityPolicy
        )
    }

    private var rawRouteCoordinates: [CLLocationCoordinate2D] {
        samples.compactMap { validMapCoordinate(from: $0.gpsCoordinate) }
    }

    var body: some View {
        let routeResult = routeDisplayResult
        let displayPoints = routeResult.points
        let rawCoordinates = rawRouteCoordinates
        let coordinates = displayPoints.map { routeMapCoordinate(from: $0.displayCoordinate) }
        let reliableCoordinates = displayPoints.filter(\.isReliableRouteAnchor).map { routeMapCoordinate(from: $0.displayCoordinate) }
        let gpsLockCoordinates = gpsLockRouteCoordinates(from: routeResult)
        let regionCoordinates = primaryMapRegionCoordinates(
            displayPoints: displayPoints,
            displayCoordinates: coordinates,
            reliableCoordinates: reliableCoordinates,
            gpsLockCoordinates: gpsLockCoordinates
        )
        let startMarkerState = routeStartMarkerState(from: routeResult)
        let startCoordinate = startMarkerState?.coordinate
        let startIsApproximate = startMarkerState?.isApproximate ?? false
        let finishCoordinate = coordinates.last
        let segments = routeMapSegments(from: routeResult)

        VStack(alignment: .leading, spacing: 12) {
            header(coordinateCount: coordinates.count, rawCoordinateCount: rawCoordinates.count, routeResult: routeResult)

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

    private func header(coordinateCount: Int, rawCoordinateCount: Int, routeResult: RouteDisplayResult) -> some View {
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

            if let disclosure = routeAccuracyDisclosureText(routeResult: routeResult) {
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

    private func routeMapSegments(from result: RouteDisplayResult) -> [RouteMapSegment] {
        result.segments.map { segment in
            RouteMapSegment(
                id: segment.id,
                coordinates: segment.points.map { routeMapCoordinate(from: $0.displayCoordinate) },
                style: routeMapSegmentStyle(for: segment.semantic)
            )
        }
    }

    private func routeMapSegmentStyle(for semantic: RouteDisplaySemantic) -> RouteMapSegmentStyle {
        switch semantic {
        case .highConfidence:
            return .trusted
        case .lowConfidence:
            return .uncertain
        case .startupWarmup:
            return .startupWarmup
        }
    }

    private func validMapCoordinate(from coordinate: GeoCoordinate?) -> CLLocationCoordinate2D? {
        guard let coordinate,
              coordinate.latitude.isFinite,
              coordinate.longitude.isFinite,
              (-90.0...90.0).contains(coordinate.latitude),
              (-180.0...180.0).contains(coordinate.longitude) else {
            return nil
        }
        return routeMapCoordinate(from: coordinate)
    }

    private func routeMapCoordinate(from coordinate: GeoCoordinate) -> CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }

    private func gpsLockRouteCoordinates(from result: RouteDisplayResult) -> [CLLocationCoordinate2D] {
        guard let gpsLockPoint = gpsLockDisplayPoint(from: result) else { return [] }
        return result.points
            .filter { $0.timestamp >= gpsLockPoint.timestamp && $0.isReliableRouteAnchor }
            .map { routeMapCoordinate(from: $0.displayCoordinate) }
    }

    private func gpsLockDisplayPoint(from result: RouteDisplayResult) -> ActivityRouteDisplayPoint? {
        result.points
            .sorted(by: { $0.timestamp < $1.timestamp })
            .first { $0.elapsedSeconds >= 0 && $0.isReliableRouteAnchor }
    }

    private func recordingStartDisplayPoint(from result: RouteDisplayResult) -> ActivityRouteDisplayPoint? {
        let points = result.points.sorted(by: { $0.timestamp < $1.timestamp })
        return points.first(where: { $0.timestamp >= session.startDate }) ?? points.first
    }

    private func recordingStartCoordinate(from result: RouteDisplayResult) -> CLLocationCoordinate2D? {
        recordingStartDisplayPoint(from: result).map { routeMapCoordinate(from: $0.displayCoordinate) }
    }

    private func gpsLockElapsed(from result: RouteDisplayResult) -> TimeInterval? {
        gpsLockDisplayPoint(from: result)?.timestamp.timeIntervalSince(session.startDate)
    }

    private func gpsObservedMovementOnsetElapsed(from result: RouteDisplayResult) -> TimeInterval? {
        let points = result.points.sorted(by: { $0.timestamp < $1.timestamp })
        guard !points.isEmpty else { return nil }
        let movementSpeedThresholdKmh = gpsObservedMovementSpeedThresholdKmh()
        var consecutiveMovingCount = 0

        for point in points {
            let speed = point.speedKilometersPerHour ?? 0
            if speed >= movementSpeedThresholdKmh {
                consecutiveMovingCount += 1
                if consecutiveMovingCount >= 3 {
                    return point.timestamp.timeIntervalSince(session.startDate)
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

    private func isStartApproximate(routeResult: RouteDisplayResult) -> Bool {
        guard let point = recordingStartDisplayPoint(from: routeResult) else { return false }
        if point.semantic != .highConfidence { return true }
        if point.horizontalAccuracyMeters.map({ $0 > fidelityPolicy.preferredHorizontalAccuracyMeters }) == true { return true }
        if gpsLockElapsed(from: routeResult).map({ $0 > Self.approximateStartLockDelaySeconds }) == true { return true }
        if let gpsLockElapsed = gpsLockElapsed(from: routeResult),
           let gpsObservedMovementOnsetElapsed = gpsObservedMovementOnsetElapsed(from: routeResult),
           gpsLockElapsed > gpsObservedMovementOnsetElapsed + Self.approximateStartLockDelaySeconds {
            return true
        }
        return false
    }

    private func routeStartMarkerState(from result: RouteDisplayResult) -> RouteStartMarkerState? {
        guard let coordinate = recordingStartCoordinate(from: result) else { return nil }
        return RouteStartMarkerState(coordinate: coordinate, isApproximate: isStartApproximate(routeResult: result))
    }

    private func primaryMapRegionCoordinates(
        displayPoints: [ActivityRouteDisplayPoint],
        displayCoordinates: [CLLocationCoordinate2D],
        reliableCoordinates: [CLLocationCoordinate2D],
        gpsLockCoordinates: [CLLocationCoordinate2D]
    ) -> [CLLocationCoordinate2D] {
        if gpsLockCoordinates.count >= 2 { return gpsLockCoordinates }
        if reliableCoordinates.count >= 2 { return reliableCoordinates }

        let nonWarmupCoordinates = displayPoints
            .filter { $0.semantic != .startupWarmup }
            .map { routeMapCoordinate(from: $0.displayCoordinate) }
        if nonWarmupCoordinates.count >= 2 { return nonWarmupCoordinates }

        return displayCoordinates
    }

    private func routeAccuracyDisclosureText(routeResult: RouteDisplayResult) -> String? {
        guard !routeResult.points.isEmpty else { return nil }
        if routeResult.summary.hasStartupWarmup {
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

    private func routeSampleCountText(_ count: Int) -> String {
        let format = NSLocalizedString("summary.route.sampleCountFormat", comment: "")
        return String(format: format, locale: .autoupdatingCurrent, count)
    }
}
