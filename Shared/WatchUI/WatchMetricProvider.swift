// [協作區] Shared/WatchUI/WatchMetricProvider.swift
// Purpose: Defines safe, mode-aware Watch metric provider outputs for Task-037a.
// Delegates to: WatchActivityViewModel compact display state and future scoped provider implementations.

import Foundation

enum WatchMetricActivityMode: Equatable, Hashable, Sendable {
    case skateboard
    case inline
    case unsupported(rawValue: String?)

    init(descriptor: WatchBridgeActivityModeDescriptor) {
        let normalized = descriptor.sportModeKey?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        switch normalized {
        case "skateboard", "board":
            self = .skateboard
        case "inline", "inline_skating", "inlineskating", "inline-skating":
            self = .inline
        case let rawValue:
            self = .unsupported(rawValue: rawValue)
        }
    }
}

enum WatchMetricCardKind: String, Equatable, Sendable {
    case route
    case speed
    case elevation
}

enum WatchMetricProviderSource: String, Equatable, Sendable {
    case compactRouteDisplay
    case compactSpeedSparkline
    case compactElevationProfile
    case unavailable
}

enum WatchMetricUnavailableReason: String, Equatable, Sendable {
    case missingCompactOutput
    case watchBridgeDisconnected
    case staleData
    case providerDisabled
    case unsupportedMode
    case lockedByEntitlementBoundary
}

enum WatchMetricAvailabilityState: Equatable, Sendable {
    case available
    case unavailable(WatchMetricUnavailableReason)
    case disabled(WatchMetricUnavailableReason)
    case locked(WatchMetricUnavailableReason)
    case unsupportedMode(String?)

    var isRenderable: Bool {
        if case .available = self { return true }
        return false
    }
}

struct WatchMetricProviderContext: Equatable, Sendable {
    let generatedAt: Date
    let activityMode: WatchMetricActivityMode
    let session: WatchActivitySessionViewState
    let metrics: WatchActivityMetricViewState
    let samples: WatchActivitySampleViewState
    let compactSummary: WatchActivityCompactSummaryViewState
    let fallback: WatchActivityFallbackViewState

    init(viewModel: WatchActivityViewModel) {
        self.generatedAt = viewModel.generatedAt
        self.activityMode = WatchMetricActivityMode(descriptor: viewModel.session.mode)
        self.session = viewModel.session
        self.metrics = viewModel.metrics
        self.samples = viewModel.samples
        self.compactSummary = viewModel.compactSummary
        self.fallback = viewModel.fallback
    }
}

struct WatchMetricProviderOutput: Equatable, Sendable {
    let identifier: String
    let kind: WatchMetricCardKind
    let titleLocalizationKey: String
    let accessibilityIdentifier: String
    let availability: WatchMetricAvailabilityState
    let source: WatchMetricProviderSource
    let compactRoute: CompactRouteDisplay?
    let speedSparkline: CompactSpeedSparkline?
    let elevationProfile: CompactElevationProfile?

    var isRenderable: Bool {
        availability.isRenderable
    }
}

protocol WatchMetricProviding: Sendable {
    var providerIdentifier: String { get }
    func supports(activityMode: WatchMetricActivityMode) -> Bool
    func makeMetricOutputs(context: WatchMetricProviderContext) -> [WatchMetricProviderOutput]
}

struct WatchBaseMetricProvider: WatchMetricProviding {
    let providerIdentifier = "watch.metric.provider.base"

    func supports(activityMode: WatchMetricActivityMode) -> Bool {
        switch activityMode {
        case .skateboard, .inline:
            return true
        case .unsupported:
            return false
        }
    }

    func makeMetricOutputs(context: WatchMetricProviderContext) -> [WatchMetricProviderOutput] {
        [
            routeOutput(context: context),
            speedOutput(context: context),
            elevationOutput(context: context),
        ]
    }

    private func routeOutput(context: WatchMetricProviderContext) -> WatchMetricProviderOutput {
        let routeCard = context.compactSummary.routeCard
        let hasCompactValues = routeCard.compactRoute?.hasDisplayData == true
        return WatchMetricProviderOutput(
            identifier: "watch.metric.route",
            kind: .route,
            titleLocalizationKey: "watch.compact.route.title",
            accessibilityIdentifier: "watch-metric-provider-route",
            availability: availability(context: context, hasData: hasCompactValues),
            source: hasCompactValues ? .compactRouteDisplay : .unavailable,
            compactRoute: hasCompactValues ? routeCard.compactRoute : nil,
            speedSparkline: nil,
            elevationProfile: nil
        )
    }

    private func speedOutput(context: WatchMetricProviderContext) -> WatchMetricProviderOutput {
        let speedCard = context.compactSummary.speedCard
        let hasCompactValues = !speedCard.points.isEmpty
        return WatchMetricProviderOutput(
            identifier: "watch.metric.speed",
            kind: .speed,
            titleLocalizationKey: "watch.compact.speed.title",
            accessibilityIdentifier: "watch-metric-provider-speed",
            availability: availability(context: context, hasData: hasCompactValues),
            source: hasCompactValues ? .compactSpeedSparkline : .unavailable,
            compactRoute: nil,
            speedSparkline: hasCompactValues ? compactSpeedSparkline(from: speedCard) : nil,
            elevationProfile: nil
        )
    }

    private func elevationOutput(context: WatchMetricProviderContext) -> WatchMetricProviderOutput {
        let elevationCard = context.compactSummary.elevationCard
        let hasCompactValues = !elevationCard.points.isEmpty
        return WatchMetricProviderOutput(
            identifier: "watch.metric.elevation",
            kind: .elevation,
            titleLocalizationKey: "watch.compact.elevation.title",
            accessibilityIdentifier: "watch-metric-provider-elevation",
            availability: availability(context: context, hasData: hasCompactValues),
            source: hasCompactValues ? .compactElevationProfile : .unavailable,
            compactRoute: nil,
            speedSparkline: nil,
            elevationProfile: hasCompactValues ? compactElevationProfile(from: elevationCard) : nil
        )
    }

    private func availability(
        context: WatchMetricProviderContext,
        hasData: Bool
    ) -> WatchMetricAvailabilityState {
        switch context.fallback.kind {
        case .disabledProvider:
            return .disabled(.providerDisabled)
        case .disconnected:
            return .unavailable(.watchBridgeDisconnected)
        case .staleData:
            return .unavailable(.staleData)
        case .ready, .noSamples:
            return hasData ? .available : .unavailable(.missingCompactOutput)
        }
    }

    private func compactSpeedSparkline(
        from card: WatchActivitySpeedCompactCardViewState
    ) -> CompactSpeedSparkline {
        CompactSpeedSparkline(
            points: card.points,
            quality: card.quality ?? .unavailable,
            minimumSpeedKilometersPerHour: card.minimumSpeedKilometersPerHour,
            maximumSpeedKilometersPerHour: card.maximumSpeedKilometersPerHour,
            averageDisplaySpeedKilometersPerHour: card.averageDisplaySpeedKilometersPerHour,
            segmentCount: card.segmentCount,
            hasSparseData: card.hasSparseData
        )
    }

    private func compactElevationProfile(
        from card: WatchActivityElevationCompactCardViewState
    ) -> CompactElevationProfile {
        CompactElevationProfile(
            points: card.points,
            quality: card.quality ?? .unavailable,
            displayDerivedTotalAscentMeters: card.ascentMeters,
            selectedSource: card.selectedSource ?? .motionSample,
            segmentCount: card.segmentCount,
            hasAbsoluteAnchor: card.hasAbsoluteAnchor,
            hasSparseData: card.hasSparseData
        )
    }
}

struct WatchMetricProviderSelectionResult: Sendable {
    let activityMode: WatchMetricActivityMode
    let providerIdentifier: String?
    let outputs: [WatchMetricProviderOutput]
    let availability: WatchMetricAvailabilityState

    var hasProvider: Bool {
        providerIdentifier != nil
    }
}

struct WatchMetricProviderSelector: Sendable {
    private let providers: [any WatchMetricProviding]

    init(providers: [any WatchMetricProviding] = [WatchBaseMetricProvider()]) {
        self.providers = providers
    }

    func selectProvider(
        for context: WatchMetricProviderContext
    ) -> (any WatchMetricProviding)? {
        providers.first { provider in
            provider.supports(activityMode: context.activityMode)
        }
    }

    func makeSelection(for viewModel: WatchActivityViewModel) -> WatchMetricProviderSelectionResult {
        let context = WatchMetricProviderContext(viewModel: viewModel)
        guard let provider = selectProvider(for: context) else {
            return WatchMetricProviderSelectionResult(
                activityMode: context.activityMode,
                providerIdentifier: nil,
                outputs: [],
                availability: unsupportedAvailability(for: context.activityMode)
            )
        }

        return WatchMetricProviderSelectionResult(
            activityMode: context.activityMode,
            providerIdentifier: provider.providerIdentifier,
            outputs: provider.makeMetricOutputs(context: context),
            availability: .available
        )
    }

    private func unsupportedAvailability(
        for activityMode: WatchMetricActivityMode
    ) -> WatchMetricAvailabilityState {
        switch activityMode {
        case .unsupported(let rawValue):
            return .unsupportedMode(rawValue)
        case .skateboard, .inline:
            return .unavailable(.unsupportedMode)
        }
    }
}
