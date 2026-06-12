// [協作區] SpotMapView.swift
// 用途：以 MapKit 顯示本機 Spot markers；不要求定位權限、不接公開場地資料庫。
// 委派至：SpotListView 管理選取、Paywall 與 CRUD 操作。

import MapKit
import SwiftUI

struct SpotMapView: View {
    let spots: [SpotProfile]
    let onSelectSpot: (SpotProfile) -> Void
    let onToggleFavorite: (SpotProfile) async -> Void
    var rideabilityLevelProvider: ((SpotProfile) -> WeatherSuitabilityLevel)?

    @State private var cameraPosition: MapCameraPosition

    init(
        spots: [SpotProfile],
        onSelectSpot: @escaping (SpotProfile) -> Void,
        onToggleFavorite: @escaping (SpotProfile) async -> Void,
        rideabilityLevelProvider: ((SpotProfile) -> WeatherSuitabilityLevel)? = nil
    ) {
        self.spots = spots
        self.onSelectSpot = onSelectSpot
        self.onToggleFavorite = onToggleFavorite
        self.rideabilityLevelProvider = rideabilityLevelProvider
        _cameraPosition = State(initialValue: .region(Self.defaultRegion(for: spots)))
    }

    var body: some View {
        VStack(spacing: 12) {
            if mappableSpots.isEmpty {
                emptyMapState
            } else {
                Map(position: $cameraPosition) {
                    ForEach(mappableSpots) { spot in
                        Annotation(spot.name, coordinate: spot.mapCoordinate) {
                            spotMarker(for: spot)
                        }
                    }
                }
                .frame(height: 330)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 24).stroke(SkateTrackSessionStartColors.border, lineWidth: 1))
                .accessibilityIdentifier("spots-map")

                mapSpotStrip
            }
        }
        .onChange(of: spots) { _, newSpots in
            cameraPosition = .region(Self.defaultRegion(for: newSpots))
        }
    }

    private var mappableSpots: [SpotProfile] {
        spots.filter(\.hasCoordinate)
    }

    private func spotMarker(for spot: SpotProfile) -> some View {
        Button { onSelectSpot(spot) } label: {
            VStack(spacing: 4) {
                Image(systemName: spot.isFavorite ? "star.circle.fill" : "mappin.circle.fill")
                    .font(.title2.weight(.black))
                    .foregroundStyle(spot.isFavorite ? SkateTrackSessionStartColors.amber : SkateTrackSessionStartColors.teal)
                    .shadow(radius: 4)
                if let level = rideabilityLevelProvider?(spot) {
                    WeatherRideabilityStatusChipView(level: level, compact: true)
                }
                Text(spot.name)
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(.black.opacity(0.58))
                    .clipShape(Capsule())
            }
        }
        .buttonStyle(.plain)
    }

    private var emptyMapState: some View {
        VStack(spacing: 12) {
            Image(systemName: "map")
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(SkateTrackSessionStartColors.teal)
            Text("spots.map.empty.title")
                .font(.headline.weight(.heavy))
                .foregroundStyle(.white)
            Text("spots.map.empty.subtitle")
                .font(.subheadline)
                .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(22)
        .background(SkateTrackSessionStartColors.card.opacity(0.86))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(SkateTrackSessionStartColors.border, lineWidth: 1))
        .accessibilityIdentifier("spots-map-empty")
    }

    private var mapSpotStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(mappableSpots) { spot in
                    Button { onSelectSpot(spot) } label: {
                        HStack(spacing: 8) {
                            Image(systemName: spot.isFavorite ? "star.fill" : "mappin")
                                .foregroundStyle(spot.isFavorite ? SkateTrackSessionStartColors.amber : SkateTrackSessionStartColors.teal)
                            Text(spot.name)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.white)
                                .lineLimit(1)
                            if let level = rideabilityLevelProvider?(spot) {
                                WeatherRideabilityStatusChipView(level: level, compact: true)
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(SkateTrackSessionStartColors.card.opacity(0.88))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 2)
        }
    }

    private static func defaultRegion(for spots: [SpotProfile]) -> MKCoordinateRegion {
        guard let first = spots.first(where: { $0.coordinate != nil })?.coordinate else {
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 25.0330, longitude: 121.5654),
                span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
            )
        }
        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: first.latitude, longitude: first.longitude),
            span: MKCoordinateSpan(latitudeDelta: 0.035, longitudeDelta: 0.035)
        )
    }
}

private extension SpotProfile {
    var mapCoordinate: CLLocationCoordinate2D {
        let coordinate = coordinate ?? GeoCoordinate(latitude: 25.0330, longitude: 121.5654)
        return CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }
}
