// [Collaboration] Shared/WatchSensors/WatchSampleIngestion.swift

import Foundation

public struct WatchSampleIngestionPolicy: Codable, Equatable, Sendable {
    public let maximumExpectedSampleGap: TimeInterval
    public let dropsDuplicateSamples: Bool

    public init(
        maximumExpectedSampleGap: TimeInterval = 30.0,
        dropsDuplicateSamples: Bool = true
    ) {
        self.maximumExpectedSampleGap = max(0.0, maximumExpectedSampleGap)
        self.dropsDuplicateSamples = dropsDuplicateSamples
    }
}

public struct WatchSampleSourceAttribution: Codable, Equatable, Sendable {
    public let providerKind: WatchSensorProviderKind
    public let capturedAt: Date
    public let availabilityStatus: WatchSensorProviderAvailabilityStatus
    public let unavailableReason: WatchSensorProviderUnavailableReason?

    public init(snapshot: WatchSensorProviderSnapshot) {
        self.providerKind = snapshot.providerKind
        self.capturedAt = snapshot.capturedAt
        self.availabilityStatus = snapshot.availability.status
        self.unavailableReason = snapshot.availability.reason
    }
}

public enum WatchSampleIngestionIssueKind: String, Codable, Equatable, Sendable {
    case duplicateSample
    case outOfOrderSample
    case sampleGap
    case unusableSnapshot
}

public struct WatchSampleIngestionIssue: Codable, Equatable, Sendable {
    public let kind: WatchSampleIngestionIssueKind
    public let sampleID: UUID?
    public let timestamp: Date?
    public let providerKind: WatchSensorProviderKind
    public let detail: String

    public init(
        kind: WatchSampleIngestionIssueKind,
        sampleID: UUID?,
        timestamp: Date?,
        providerKind: WatchSensorProviderKind,
        detail: String
    ) {
        self.kind = kind
        self.sampleID = sampleID
        self.timestamp = timestamp
        self.providerKind = providerKind
        self.detail = detail
    }
}

public struct WatchIngestedSample: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let kind: WatchSensorSampleKind
    public let timestamp: Date
    public let numericValue: Double
    public let unitSymbol: String
    public let providerKind: WatchSensorProviderKind
    public let confidence: Double
    public let sourceAttribution: WatchSampleSourceAttribution

    public init(
        sample: WatchSensorSample,
        sourceAttribution: WatchSampleSourceAttribution
    ) {
        self.id = sample.id
        self.kind = sample.kind
        self.timestamp = sample.timestamp
        self.numericValue = sample.numericValue
        self.unitSymbol = sample.unitSymbol
        self.providerKind = sample.providerKind
        self.confidence = sample.confidence
        self.sourceAttribution = sourceAttribution
    }
}

public struct WatchSampleIngestionResult: Codable, Equatable, Sendable {
    public let samples: [WatchIngestedSample]
    public let issues: [WatchSampleIngestionIssue]
    public let sourceAttribution: WatchSampleSourceAttribution
    public let trustedMetricMutationCount: Int
    public let routeGeometryMutationCount: Int

    public init(
        samples: [WatchIngestedSample],
        issues: [WatchSampleIngestionIssue],
        sourceAttribution: WatchSampleSourceAttribution
    ) {
        self.samples = samples
        self.issues = issues
        self.sourceAttribution = sourceAttribution
        self.trustedMetricMutationCount = 0
        self.routeGeometryMutationCount = 0
    }

    public var sampleCount: Int {
        samples.count
    }
}

public struct WatchSampleIngestor: Sendable {
    public init() {}

    public func ingest(
        snapshot: WatchSensorProviderSnapshot,
        policy: WatchSampleIngestionPolicy = WatchSampleIngestionPolicy()
    ) -> WatchSampleIngestionResult {
        let attribution = WatchSampleSourceAttribution(snapshot: snapshot)

        guard snapshot.isUsable else {
            return WatchSampleIngestionResult(
                samples: [],
                issues: [
                    WatchSampleIngestionIssue(
                        kind: .unusableSnapshot,
                        sampleID: nil,
                        timestamp: snapshot.capturedAt,
                        providerKind: snapshot.providerKind,
                        detail: "Watch sensor snapshot is not available for ingestion."
                    )
                ],
                sourceAttribution: attribution
            )
        }

        let deduplicated = deduplicate(
            snapshot.samples,
            providerKind: snapshot.providerKind,
            dropsDuplicateSamples: policy.dropsDuplicateSamples
        )
        let orderingIssues = orderingIssues(
            for: deduplicated.samples,
            providerKind: snapshot.providerKind
        )
        let orderedSamples = deduplicated.samples.sorted {
            if $0.timestamp == $1.timestamp {
                return $0.id.uuidString < $1.id.uuidString
            }
            return $0.timestamp < $1.timestamp
        }
        let gapIssues = sampleGapIssues(
            for: orderedSamples,
            providerKind: snapshot.providerKind,
            maximumExpectedSampleGap: policy.maximumExpectedSampleGap
        )
        let ingestedSamples = orderedSamples.map {
            WatchIngestedSample(sample: $0, sourceAttribution: attribution)
        }

        return WatchSampleIngestionResult(
            samples: ingestedSamples,
            issues: deduplicated.issues + orderingIssues + gapIssues,
            sourceAttribution: attribution
        )
    }

    private func deduplicate(
        _ samples: [WatchSensorSample],
        providerKind: WatchSensorProviderKind,
        dropsDuplicateSamples: Bool
    ) -> (samples: [WatchSensorSample], issues: [WatchSampleIngestionIssue]) {
        guard dropsDuplicateSamples else {
            return (samples, [])
        }

        var seenSampleIDs = Set<UUID>()
        var keptSamples: [WatchSensorSample] = []
        var issues: [WatchSampleIngestionIssue] = []

        for sample in samples {
            if seenSampleIDs.contains(sample.id) {
                issues.append(
                    WatchSampleIngestionIssue(
                        kind: .duplicateSample,
                        sampleID: sample.id,
                        timestamp: sample.timestamp,
                        providerKind: providerKind,
                        detail: "Duplicate Watch sample id was ignored."
                    )
                )
            } else {
                seenSampleIDs.insert(sample.id)
                keptSamples.append(sample)
            }
        }

        return (keptSamples, issues)
    }

    private func orderingIssues(
        for samples: [WatchSensorSample],
        providerKind: WatchSensorProviderKind
    ) -> [WatchSampleIngestionIssue] {
        guard samples.count > 1 else {
            return []
        }

        var issues: [WatchSampleIngestionIssue] = []
        var previousTimestamp = samples[0].timestamp

        for sample in samples.dropFirst() {
            if sample.timestamp < previousTimestamp {
                issues.append(
                    WatchSampleIngestionIssue(
                        kind: .outOfOrderSample,
                        sampleID: sample.id,
                        timestamp: sample.timestamp,
                        providerKind: providerKind,
                        detail: "Watch sample arrived before an earlier sample timestamp."
                    )
                )
            }
            previousTimestamp = sample.timestamp
        }

        return issues
    }

    private func sampleGapIssues(
        for samples: [WatchSensorSample],
        providerKind: WatchSensorProviderKind,
        maximumExpectedSampleGap: TimeInterval
    ) -> [WatchSampleIngestionIssue] {
        guard maximumExpectedSampleGap > 0.0, samples.count > 1 else {
            return []
        }

        var issues: [WatchSampleIngestionIssue] = []

        for (previous, current) in zip(samples, samples.dropFirst()) {
            let gap = current.timestamp.timeIntervalSince(previous.timestamp)
            if gap > maximumExpectedSampleGap {
                issues.append(
                    WatchSampleIngestionIssue(
                        kind: .sampleGap,
                        sampleID: current.id,
                        timestamp: current.timestamp,
                        providerKind: providerKind,
                        detail: "Watch sample gap exceeds the ingestion policy."
                    )
                )
            }
        }

        return issues
    }
}
