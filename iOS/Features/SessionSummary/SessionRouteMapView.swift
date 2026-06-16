// [協作區] SessionRouteMapView.swift
// 用途：呈現 Task-018b Session Summary 的 MapKit 路線預覽、起點與終點標記。
// 委派至：SessionSummaryView 提供 motion samples；後續 Task-030c-d 接手 route confidence rendering。

import MapKit
import SwiftUI

private struct RouteMapSegment: Identifiable {
    let id: Int
    let coordinates: [CLLocationCoordinate2D]
}

struct SessionRouteMapView: View {
    let samples: [MotionSample]

    private var routeSegments: [RouteMapSegment] {
        makeRouteSegments(from: samples)
    }

    private var routeCoordinates: [CLLocationCoordinate2D] {
        samples.compactMap(validCoordinate)
    }

    var body: some View {
        let coordinates = routeCoordinates
        let segments = routeSegments

        VStack(alignment: .leading, spacing: 12) {
            header(coordinateCount: coordinates.count)

            if coordinates.count >= 2 {
                routeMap(coordinates: coordinates, segments: segments)
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

    private func header(coordinateCount: Int) -> some View {
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
            }

            Text(LocalizedStringKey(coordinateCount >= 2 ? "summary.route.map.subtitle" : "summary.route.empty.subtitle"))
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func routeMap(coordinates: [CLLocationCoordinate2D], segments: [RouteMapSegment]) -> some View {
        Map(initialPosition: .region(region(for: coordinates))) {
            ForEach(segments) { segment in
                if segment.coordinates.count >= 2 {
                    MapPolyline(coordinates: segment.coordinates)
                        .stroke(SkateTrackSessionStartColors.teal, lineWidth: 4)
                }
            }

            if let start = coordinates.first {
                Annotation(NSLocalizedString("summary.route.start", comment: ""), coordinate: start, anchor: .center) {
                    routePin(systemImage: "play.fill", color: SkateTrackSessionStartColors.teal)
                }
            }

            if let finish = coordinates.last {
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

    private func makeRouteSegments(from samples: [MotionSample]) -> [RouteMapSegment] {
        var segments: [RouteMapSegment] = []
        var currentCoordinates: [CLLocationCoordinate2D] = []
        var segmentID = 0
        var previousTimestamp: Date?

        for sample in samples.sorted(by: { $0.timestamp < $1.timestamp }) {
            guard let coordinate = validCoordinate(from: sample) else { continue }

            if shouldStartNewRouteSegment(after: previousTimestamp, current: sample) {
                appendSegmentIfNeeded(currentCoordinates, id: segmentID, to: &segments)
                currentCoordinates = []
                segmentID += 1
            }

            currentCoordinates.append(coordinate)
            previousTimestamp = sample.timestamp
        }

        appendSegmentIfNeeded(currentCoordinates, id: segmentID, to: &segments)
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

    private func shouldStartNewRouteSegment(after previousTimestamp: Date?, current sample: MotionSample) -> Bool {
        if let previousTimestamp, sample.timestamp.timeIntervalSince(previousTimestamp) > 12 {
            return true
        }

        guard let diagnostics = sample.locationDiagnostics else { return false }
        if diagnostics.freshnessState == .stale { return true }
        if diagnostics.routeSegmentConfidence == .low { return true }
        if diagnostics.gpsUpdateIntervalSeconds.map({ $0 > 12 }) == true { return true }
        return false
    }

    private func appendSegmentIfNeeded(
        _ coordinates: [CLLocationCoordinate2D],
        id: Int,
        to segments: inout [RouteMapSegment]
    ) {
        guard coordinates.count >= 2 else { return }
        segments.append(RouteMapSegment(id: id, coordinates: coordinates))
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
