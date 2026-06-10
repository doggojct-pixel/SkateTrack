// [協作區] MiniRouteMapView.swift
// 用途：在 Live HUD 中呈現最近路線的迷你地圖視覺，無座標時顯示 graceful placeholder。
// 委派至：LiveHUDView 依 SessionRecordingState.recentRouteCoordinates 提供路線點。

import SwiftUI

struct MiniRouteMapView: View {
    let coordinates: [GeoCoordinate]
    let accentColor: Color

    var body: some View {
        ZStack {
            mapBackground

            if coordinates.count >= 2 {
                RouteLineShape(coordinates: coordinates)
                    .stroke(accentColor.opacity(0.35), style: StrokeStyle(lineWidth: 8, lineCap: .round, lineJoin: .round))
                    .blur(radius: 4)
                    .padding(28)

                RouteLineShape(coordinates: coordinates)
                    .stroke(accentColor, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                    .padding(28)

                currentPositionMarker
            } else {
                emptyState
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 30))
        .overlay(
            RoundedRectangle(cornerRadius: 30)
                .stroke(SkateTrackSessionStartColors.border, lineWidth: 1)
        )
        .accessibilityIdentifier("live-hud-mini-route-map")
    }

    private var mapBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    SkateTrackSessionStartColors.navy3,
                    SkateTrackSessionStartColors.panel,
                    SkateTrackSessionStartColors.navy2
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            DotGridPattern()
                .stroke(Color.white.opacity(0.035), lineWidth: 1)
        }
    }

    private var currentPositionMarker: some View {
        GeometryReader { proxy in
            let point = RouteLineShape.point(
                for: coordinates.last,
                in: coordinates,
                rect: CGRect(origin: .zero, size: proxy.size).insetBy(dx: 28, dy: 28)
            )

            Circle()
                .fill(.white)
                .frame(width: 12, height: 12)
                .shadow(color: .white.opacity(0.8), radius: 8, x: 0, y: 0)
                .position(point)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "location.slash")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(accentColor)
            Text("session.hud.routeWaiting")
                .font(.caption.weight(.semibold))
                .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
        }
    }
}

private struct RouteLineShape: Shape {
    let coordinates: [GeoCoordinate]

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard let first = coordinates.first else { return path }

        path.move(to: Self.point(for: first, in: coordinates, rect: rect))
        for coordinate in coordinates.dropFirst() {
            path.addLine(to: Self.point(for: coordinate, in: coordinates, rect: rect))
        }
        return path
    }

    static func point(for coordinate: GeoCoordinate?, in coordinates: [GeoCoordinate], rect: CGRect) -> CGPoint {
        guard let coordinate else {
            return CGPoint(x: rect.midX, y: rect.midY)
        }

        let latitudes = coordinates.map(\.latitude)
        let longitudes = coordinates.map(\.longitude)
        let minLatitude = latitudes.min() ?? coordinate.latitude
        let maxLatitude = latitudes.max() ?? coordinate.latitude
        let minLongitude = longitudes.min() ?? coordinate.longitude
        let maxLongitude = longitudes.max() ?? coordinate.longitude

        let latitudeSpan = max(maxLatitude - minLatitude, 0.00001)
        let longitudeSpan = max(maxLongitude - minLongitude, 0.00001)
        let x = rect.minX + CGFloat((coordinate.longitude - minLongitude) / longitudeSpan) * rect.width
        let y = rect.maxY - CGFloat((coordinate.latitude - minLatitude) / latitudeSpan) * rect.height
        return CGPoint(x: x, y: y)
    }
}

private struct DotGridPattern: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let spacing: CGFloat = 24
        var y = rect.minY
        while y <= rect.maxY {
            var x = rect.minX
            while x <= rect.maxX {
                path.addEllipse(in: CGRect(x: x, y: y, width: 2, height: 2))
                x += spacing
            }
            y += spacing
        }
        return path
    }
}

#Preview("Mini Route") {
    MiniRouteMapView(
        coordinates: [
            GeoCoordinate(latitude: 25.033, longitude: 121.565),
            GeoCoordinate(latitude: 25.034, longitude: 121.566),
            GeoCoordinate(latitude: 25.035, longitude: 121.568)
        ],
        accentColor: SkateTrackSessionStartColors.accent
    )
    .frame(height: 260)
    .padding()
    .background(SkateTrackSessionStartColors.navy2)
    .preferredColorScheme(.dark)
}
