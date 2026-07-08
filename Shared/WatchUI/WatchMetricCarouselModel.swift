// [協作區] Shared/WatchUI/WatchMetricCarouselModel.swift
// Purpose: Maps safe Watch metric provider outputs into display-only carousel card models for Task-037b.
// Delegates to: WatchMetricProviderOutput and Shared compact speed/elevation display contracts.

import Foundation

enum WatchMetricCarouselDisplayState: Equatable, Sendable {
    case available
    case unavailable
    case disabled
    case locked
    case unsupported
}

struct WatchMetricCarouselCardModel: Identifiable, Equatable, Sendable {
    let id: String
    let kind: WatchMetricCardKind
    let titleLocalizationKey: String
    let accessibilityIdentifier: String
    let valueText: String
    let unitLocalizationKey: String?
    let detailLocalizationKey: String
    let sparklinePoints: [CompactSparklinePoint]
    let availability: WatchMetricAvailabilityState
    let displayState: WatchMetricCarouselDisplayState
    let source: WatchMetricProviderSource

    var isAvailable: Bool {
        displayState == .available
    }

    var shouldRenderSparkline: Bool {
        isAvailable && sparklinePoints.count >= 2
    }
}

struct WatchMetricCarouselModel: Equatable, Sendable {
    let cards: [WatchMetricCarouselCardModel]
    let selectionAvailability: WatchMetricAvailabilityState
    let providerIdentifier: String?

    init(selection: WatchMetricProviderSelectionResult) {
        self.cards = selection.outputs.map(Self.cardModel(from:))
        self.selectionAvailability = selection.availability
        self.providerIdentifier = selection.providerIdentifier
    }

    var hasCards: Bool {
        !cards.isEmpty
    }

    var hasRenderableCompactSpeed: Bool {
        cards.contains { card in
            card.kind == .speed && card.source == .compactSpeedSparkline && card.isAvailable
        }
    }

    var hasRenderableCompactElevation: Bool {
        cards.contains { card in
            card.kind == .elevation && card.source == .compactElevationProfile && card.isAvailable
        }
    }

    private static func cardModel(
        from output: WatchMetricProviderOutput
    ) -> WatchMetricCarouselCardModel {
        switch output.kind {
        case .route:
            return routeCardModel(from: output)
        case .speed:
            return speedCardModel(from: output)
        case .elevation:
            return elevationCardModel(from: output)
        }
    }

    private static func routeCardModel(
        from output: WatchMetricProviderOutput
    ) -> WatchMetricCarouselCardModel {
        let compactRoute = output.compactRoute
        let pointCount = compactRoute?.points.count ?? 0
        return WatchMetricCarouselCardModel(
            id: output.identifier,
            kind: output.kind,
            titleLocalizationKey: output.titleLocalizationKey,
            accessibilityIdentifier: "watch-metric-carousel-route-card",
            valueText: output.isRenderable ? String(pointCount) : unavailableValueText,
            unitLocalizationKey: "watch.compact.route.points",
            detailLocalizationKey: output.isRenderable
                ? routeDetailKey(for: compactRoute)
                : detailKey(for: output.availability),
            sparklinePoints: [],
            availability: output.availability,
            displayState: displayState(for: output.availability),
            source: output.source
        )
    }

    private static func speedCardModel(
        from output: WatchMetricProviderOutput
    ) -> WatchMetricCarouselCardModel {
        let sparkline = output.speedSparkline
        return WatchMetricCarouselCardModel(
            id: output.identifier,
            kind: output.kind,
            titleLocalizationKey: output.titleLocalizationKey,
            accessibilityIdentifier: "watch-metric-carousel-speed-card",
            valueText: output.isRenderable
                ? speedValueText(sparkline?.maximumSpeedKilometersPerHour)
                : unavailableValueText,
            unitLocalizationKey: "unit.speed.kmh.short",
            detailLocalizationKey: output.isRenderable
                ? "watch.compact.speed.max"
                : detailKey(for: output.availability),
            sparklinePoints: output.isRenderable ? speedSparklinePoints(from: sparkline) : [],
            availability: output.availability,
            displayState: displayState(for: output.availability),
            source: output.source
        )
    }

    private static func elevationCardModel(
        from output: WatchMetricProviderOutput
    ) -> WatchMetricCarouselCardModel {
        let profile = output.elevationProfile
        return WatchMetricCarouselCardModel(
            id: output.identifier,
            kind: output.kind,
            titleLocalizationKey: output.titleLocalizationKey,
            accessibilityIdentifier: "watch-metric-carousel-elevation-card",
            valueText: output.isRenderable
                ? meterValueText(profile?.displayDerivedTotalAscentMeters)
                : unavailableValueText,
            unitLocalizationKey: "unit.length.meter.short",
            detailLocalizationKey: output.isRenderable
                ? "watch.compact.elevation.ascent"
                : detailKey(for: output.availability),
            sparklinePoints: output.isRenderable ? elevationProfilePoints(from: profile) : [],
            availability: output.availability,
            displayState: displayState(for: output.availability),
            source: output.source
        )
    }

    private static func speedSparklinePoints(
        from sparkline: CompactSpeedSparkline?
    ) -> [CompactSparklinePoint] {
        sparkline?.points ?? []
    }

    private static func elevationProfilePoints(
        from profile: CompactElevationProfile?
    ) -> [CompactSparklinePoint] {
        profile?.points ?? []
    }

    private static func routeDetailKey(
        for route: CompactRouteDisplay?
    ) -> String {
        guard let route, route.hasDisplayData else {
            return "watch.compact.route.status.unavailable"
        }
        if route.quality == .limited {
            return "watch.compact.route.status.qualityInsufficient"
        }
        return "watch.compact.route.status.recorded"
    }

    private static func detailKey(
        for availability: WatchMetricAvailabilityState
    ) -> String {
        switch availability {
        case .available:
            return "watch.metric.card.available"
        case .unavailable:
            return "watch.metric.card.unavailable"
        case .disabled:
            return "watch.metric.card.disabled"
        case .locked:
            return "watch.metric.card.locked"
        case .unsupportedMode:
            return "watch.metric.card.unsupported"
        }
    }

    private static func displayState(
        for availability: WatchMetricAvailabilityState
    ) -> WatchMetricCarouselDisplayState {
        switch availability {
        case .available:
            return .available
        case .unavailable:
            return .unavailable
        case .disabled:
            return .disabled
        case .locked:
            return .locked
        case .unsupportedMode:
            return .unsupported
        }
    }

    private static func speedValueText(_ value: Double?) -> String {
        guard let value, value.isFinite, value >= 0 else { return unavailableValueText }
        return String(format: "%.1f", value)
    }

    private static func meterValueText(_ value: Double?) -> String {
        guard let value, value.isFinite, value >= 0 else { return unavailableValueText }
        return String(format: "%.0f", value)
    }

    private static let unavailableValueText = "--"
}
