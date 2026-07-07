// [Collaboration] Shared/WatchSensors/WatchSampleFusionRules.swift

import Foundation

public enum WatchSampleFusionDisplaySource: String, Codable, Equatable, Sendable {
    case iPhoneTrusted
    case watchDisplayDerived
}

public struct WatchSampleFusionPolicy: Codable, Equatable, Sendable {
    public let maximumAlignmentInterval: TimeInterval
    public let maximumDisplayGap: TimeInterval
    public let minimumConflictDelta: Double
    public let allowsWatchDisplayContinuity: Bool

    public init(
        maximumAlignmentInterval: TimeInterval = 2.0,
        maximumDisplayGap: TimeInterval = 30.0,
        minimumConflictDelta: Double = 0.5,
        allowsWatchDisplayContinuity: Bool = true
    ) {
        self.maximumAlignmentInterval = max(0.0, maximumAlignmentInterval)
        self.maximumDisplayGap = max(0.0, maximumDisplayGap)
        self.minimumConflictDelta = max(0.0, minimumConflictDelta)
        self.allowsWatchDisplayContinuity = allowsWatchDisplayContinuity
    }
}

public struct WatchSampleFusionInput: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let kind: WatchSensorSampleKind
    public let timestamp: Date
    public let numericValue: Double
    public let unitSymbol: String

    public init(
        id: UUID = UUID(),
        kind: WatchSensorSampleKind,
        timestamp: Date,
        numericValue: Double,
        unitSymbol: String
    ) {
        self.id = id
        self.kind = kind
        self.timestamp = timestamp
        self.numericValue = numericValue
        self.unitSymbol = unitSymbol
    }
}

public struct WatchSampleDisplayPoint: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let kind: WatchSensorSampleKind
    public let timestamp: Date
    public let numericValue: Double
    public let unitSymbol: String
    public let source: WatchSampleFusionDisplaySource
    public let watchSourceAttribution: WatchSampleSourceAttribution?

    public init(
        id: UUID,
        kind: WatchSensorSampleKind,
        timestamp: Date,
        numericValue: Double,
        unitSymbol: String,
        source: WatchSampleFusionDisplaySource,
        watchSourceAttribution: WatchSampleSourceAttribution? = nil
    ) {
        self.id = id
        self.kind = kind
        self.timestamp = timestamp
        self.numericValue = numericValue
        self.unitSymbol = unitSymbol
        self.source = source
        self.watchSourceAttribution = watchSourceAttribution
    }

    public var isDisplayDerived: Bool {
        source == .watchDisplayDerived
    }
}

public enum WatchSampleFusionDiagnosticKind: String, Codable, Equatable, Sendable {
    case iPhoneWatchConflict
    case iPhoneSampleGap
    case watchSampleIgnored
    case watchContinuityApplied
}

public struct WatchSampleFusionDiagnostic: Codable, Equatable, Sendable {
    public let kind: WatchSampleFusionDiagnosticKind
    public let kindOfSample: WatchSensorSampleKind
    public let timestamp: Date
    public let message: String

    public init(
        kind: WatchSampleFusionDiagnosticKind,
        kindOfSample: WatchSensorSampleKind,
        timestamp: Date,
        message: String
    ) {
        self.kind = kind
        self.kindOfSample = kindOfSample
        self.timestamp = timestamp
        self.message = message
    }
}

public struct WatchSampleFusionDiagnostics: Codable, Equatable, Sendable {
    public let diagnostics: [WatchSampleFusionDiagnostic]

    public init(diagnostics: [WatchSampleFusionDiagnostic] = []) {
        self.diagnostics = diagnostics
    }

    public var conflictCount: Int {
        diagnostics.filter { $0.kind == .iPhoneWatchConflict }.count
    }

    public var gapCount: Int {
        diagnostics.filter { $0.kind == .iPhoneSampleGap }.count
    }
}

public struct WatchSampleFusionResult: Codable, Equatable, Sendable {
    public let displayPoints: [WatchSampleDisplayPoint]
    public let diagnostics: WatchSampleFusionDiagnostics
    public let displayDerivedSeparation: Bool
    public let trustedMetricMutationCount: Int
    public let routeGeometryMutationCount: Int

    public init(
        displayPoints: [WatchSampleDisplayPoint],
        diagnostics: WatchSampleFusionDiagnostics
    ) {
        self.displayPoints = displayPoints
        self.diagnostics = diagnostics
        self.displayDerivedSeparation = true
        self.trustedMetricMutationCount = 0
        self.routeGeometryMutationCount = 0
    }

    public var displayDerivedPoints: [WatchSampleDisplayPoint] {
        displayPoints.filter { $0.isDisplayDerived }
    }
}

public struct WatchSampleFusionEngine: Sendable {
    public init() {}

    public func makeDisplayFusion(
        iPhoneSamples: [WatchSampleFusionInput],
        watchSamples: [WatchIngestedSample],
        policy: WatchSampleFusionPolicy = WatchSampleFusionPolicy()
    ) -> WatchSampleFusionResult {
        let iPhoneDisplayPoints = iPhoneSamples.map { sample in
            WatchSampleDisplayPoint(
                id: sample.id,
                kind: sample.kind,
                timestamp: sample.timestamp,
                numericValue: sample.numericValue,
                unitSymbol: sample.unitSymbol,
                source: .iPhoneTrusted
            )
        }

        var diagnostics: [WatchSampleFusionDiagnostic] = []
        var displayDerivedPoints: [WatchSampleDisplayPoint] = []

        for watchSample in watchSamples {
            guard policy.allowsWatchDisplayContinuity else {
                diagnostics.append(
                    diagnostic(
                        .watchSampleIgnored,
                        sample: watchSample,
                        message: "Watch sample is ignored because display continuity is disabled."
                    )
                )
                continue
            }

            if let aligned = nearestAlignedSample(
                to: watchSample,
                in: iPhoneSamples,
                policy: policy
            ) {
                if isConflict(iPhoneSample: aligned, watchSample: watchSample, policy: policy) {
                    diagnostics.append(
                        diagnostic(
                            .iPhoneWatchConflict,
                            sample: watchSample,
                            message: "Watch sample conflicts with nearby iPhone sample; iPhone value remains authoritative."
                        )
                    )
                } else {
                    diagnostics.append(
                        diagnostic(
                            .watchSampleIgnored,
                            sample: watchSample,
                            message: "Watch sample overlaps nearby iPhone sample and is not needed for display continuity."
                        )
                    )
                }
                continue
            }

            if isInsideDisplayGap(watchSample: watchSample, iPhoneSamples: iPhoneSamples, policy: policy) {
                diagnostics.append(
                    diagnostic(
                        .iPhoneSampleGap,
                        sample: watchSample,
                        message: "Watch sample falls inside an iPhone sample gap."
                    )
                )
            }

            diagnostics.append(
                diagnostic(
                    .watchContinuityApplied,
                    sample: watchSample,
                    message: "Watch sample is used only as display-derived continuity."
                )
            )
            displayDerivedPoints.append(displayPoint(from: watchSample))
        }

        let allDisplayPoints = (iPhoneDisplayPoints + displayDerivedPoints).sorted {
            if $0.timestamp == $1.timestamp {
                return $0.id.uuidString < $1.id.uuidString
            }
            return $0.timestamp < $1.timestamp
        }

        return WatchSampleFusionResult(
            displayPoints: allDisplayPoints,
            diagnostics: WatchSampleFusionDiagnostics(diagnostics: diagnostics)
        )
    }

    private func nearestAlignedSample(
        to watchSample: WatchIngestedSample,
        in iPhoneSamples: [WatchSampleFusionInput],
        policy: WatchSampleFusionPolicy
    ) -> WatchSampleFusionInput? {
        iPhoneSamples
            .filter { $0.kind == watchSample.kind && $0.unitSymbol == watchSample.unitSymbol }
            .filter { abs($0.timestamp.timeIntervalSince(watchSample.timestamp)) <= policy.maximumAlignmentInterval }
            .min {
                abs($0.timestamp.timeIntervalSince(watchSample.timestamp)) <
                    abs($1.timestamp.timeIntervalSince(watchSample.timestamp))
            }
    }

    private func isConflict(
        iPhoneSample: WatchSampleFusionInput,
        watchSample: WatchIngestedSample,
        policy: WatchSampleFusionPolicy
    ) -> Bool {
        abs(iPhoneSample.numericValue - watchSample.numericValue) >= policy.minimumConflictDelta
    }

    private func isInsideDisplayGap(
        watchSample: WatchIngestedSample,
        iPhoneSamples: [WatchSampleFusionInput],
        policy: WatchSampleFusionPolicy
    ) -> Bool {
        let orderedSamples = iPhoneSamples
            .filter { $0.kind == watchSample.kind && $0.unitSymbol == watchSample.unitSymbol }
            .sorted { $0.timestamp < $1.timestamp }

        for (left, right) in zip(orderedSamples, orderedSamples.dropFirst()) {
            let containsWatchSample = left.timestamp < watchSample.timestamp && watchSample.timestamp < right.timestamp
            let gap = right.timestamp.timeIntervalSince(left.timestamp)
            if containsWatchSample && gap > policy.maximumDisplayGap {
                return true
            }
        }

        return orderedSamples.isEmpty
    }

    private func displayPoint(from watchSample: WatchIngestedSample) -> WatchSampleDisplayPoint {
        WatchSampleDisplayPoint(
            id: watchSample.id,
            kind: watchSample.kind,
            timestamp: watchSample.timestamp,
            numericValue: watchSample.numericValue,
            unitSymbol: watchSample.unitSymbol,
            source: .watchDisplayDerived,
            watchSourceAttribution: watchSample.sourceAttribution
        )
    }

    private func diagnostic(
        _ kind: WatchSampleFusionDiagnosticKind,
        sample: WatchIngestedSample,
        message: String
    ) -> WatchSampleFusionDiagnostic {
        WatchSampleFusionDiagnostic(
            kind: kind,
            kindOfSample: sample.kind,
            timestamp: sample.timestamp,
            message: message
        )
    }
}
