// [自主區] iOS/Core/SensorEngine/DeadReckoningReplayReviewPackBuilder.swift
// 用途：將 real-session replay diagnostics 轉成 b17-D JSON / Markdown / CSV review artifacts。
// 委派至：DeadReckoningReplayReviewPack 與 product decision checkpoint。

import Foundation

struct DeadReckoningReplayReviewSessionInput: Sendable, Equatable {
    let sessionIdentifier: String
    let replayDiagnostics: [DeadReckoningReplayDiagnostics]

    init(sessionIdentifier: String, replayDiagnostics: [DeadReckoningReplayDiagnostics]) {
        self.sessionIdentifier = sessionIdentifier
        self.replayDiagnostics = replayDiagnostics
    }
}

enum DeadReckoningReplayReviewPackBuilder {
    static let archiveFileName = "Task030c_b17D_ReplayReviewPack.zip"

    static func makeReviewPack(
        sessions: [DeadReckoningReplayReviewSessionInput],
        createdAt: Date = Date()
    ) -> DeadReckoningReplayReviewPack {
        let summaries = sessions.map { makeSessionSummary(from: $0) }
        let gapRecords = sessions.flatMap { session in
            session.replayDiagnostics.enumerated().map { index, diagnostics in
                makeGapRecord(
                    sessionIdentifier: session.sessionIdentifier,
                    gapIndex: index,
                    diagnostics: diagnostics
                )
            }
        }
        return DeadReckoningReplayReviewPack(
            archiveFileName: archiveFileName,
            createdAt: createdAt,
            sessionSummaries: summaries,
            gapRecords: gapRecords
        )
    }

    static func makeArtifacts(for pack: DeadReckoningReplayReviewPack) throws -> [DeadReckoningReplayReviewArtifact] {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let jsonData = try encoder.encode(pack)
        let jsonContents = String(data: jsonData, encoding: .utf8) ?? "{}"
        let baseName = sanitizedArtifactBaseName(for: pack)
        return [
            DeadReckoningReplayReviewArtifact(
                fileName: "\(baseName).json",
                kind: .json,
                contents: jsonContents
            ),
            DeadReckoningReplayReviewArtifact(
                fileName: "\(baseName).md",
                kind: .markdown,
                contents: makeMarkdown(for: pack)
            ),
            DeadReckoningReplayReviewArtifact(
                fileName: "\(baseName).csv",
                kind: .csv,
                contents: makeCSV(for: pack)
            )
        ]
    }

    static func makeMarkdown(for pack: DeadReckoningReplayReviewPack) -> String {
        var lines: [String] = [
            "# Task-030c-b17-D Real-Session Replay Review Pack",
            "",
            "Archive: `\(pack.archiveFileName)`",
            "Task: `\(pack.taskIdentifier)`",
            "Replay review only: `\(pack.replayReviewOnly)`",
            "Production route mutation applied: `\(pack.productionRouteMutationApplied)`",
            "Trusted metrics mutation applied: `\(pack.trustedMetricsMutationApplied)`",
            "Estimated route display enabled: `\(pack.estimatedRouteDisplayEnabled)`",
            "Product decision checkpoint required: `\(pack.productDecisionCheckpointRequired)`",
            "b18 display work blocked until product decision: `\(pack.b18DisplayWorkBlockedUntilProductDecision)`",
            "",
            "## Session summaries",
            "",
            "| Session | Gaps | Replay OK | Blocked | Eligible | Review recommended | Max closure error |",
            "|---|---:|---:|---:|---:|---:|---:|"
        ]
        for summary in pack.sessionSummaries {
            lines.append(
                "| \(summary.sessionIdentifier) | \(summary.totalGapCount) | \(summary.replaySucceededGapCount) | \(summary.blockedGapCount) | \(summary.userVisibleEligibleGapCount) | \(summary.reviewRecommendedGapCount) | \(formatOptional(summary.maximumClosureErrorMeters)) |"
            )
        }
        lines.append(contentsOf: [
            "",
            "## Gap records",
            "",
            "| Session | Gap | Duration | IMU coverage | Heading | Estimated displacement | Closure error | Eligible | Blocking reasons |",
            "|---|---:|---:|---:|---|---:|---:|---|---|"
        ])
        for record in pack.gapRecords {
            let blockingReasonsText = record.blockingReasons.joined(separator: ";")
            lines.append(
                "| \(record.sessionIdentifier) | \(record.gapIndex) | \(format(record.gapDurationSeconds)) | \(format(record.imuSampleCoverageRatio)) | \(record.headingReliability.rawValue) | \(format(record.estimatedDisplacementMeters)) | \(formatOptional(record.anchorClosureErrorMeters)) | \(record.eligibleForUserVisibleEstimatedRoute) | \(blockingReasonsText) |"
            )
        }
        return lines.joined(separator: "\n") + "\n"
    }

    static func makeCSV(for pack: DeadReckoningReplayReviewPack) -> String {
        let header = [
            "sessionIdentifier",
            "gapIndex",
            "gapDurationSeconds",
            "imuSampleCoverageRatio",
            "headingReliability",
            "estimatedDisplacementMeters",
            "anchorClosureErrorMeters",
            "closureErrorRatio",
            "eligibleForUserVisibleEstimatedRoute",
            "replayBlockingReason",
            "blockingReasons"
        ].joined(separator: ",")
        let rows = pack.gapRecords.map { record in
            [
                csvEscape(record.sessionIdentifier),
                String(record.gapIndex),
                format(record.gapDurationSeconds),
                format(record.imuSampleCoverageRatio),
                csvEscape(record.headingReliability.rawValue),
                format(record.estimatedDisplacementMeters),
                formatOptional(record.anchorClosureErrorMeters),
                formatOptional(record.closureErrorRatio),
                String(record.eligibleForUserVisibleEstimatedRoute),
                csvEscape(record.replayBlockingReason.rawValue),
                csvEscape(record.blockingReasons.joined(separator: ";"))
            ].joined(separator: ",")
        }
        return ([header] + rows).joined(separator: "\n") + "\n"
    }

    private static func makeSessionSummary(
        from session: DeadReckoningReplayReviewSessionInput
    ) -> DeadReckoningReplayReviewSessionSummary {
        let records = session.replayDiagnostics.map { diagnostics in
            makeGapRecord(sessionIdentifier: session.sessionIdentifier, gapIndex: 0, diagnostics: diagnostics)
        }
        let maximumClosureError = records.compactMap { $0.anchorClosureErrorMeters }.max()
        let replaySucceededCount = session.replayDiagnostics.filter { diagnostics in
            diagnostics.blockingReason == .noBlockingReason && !diagnostics.estimates.isEmpty
        }.count
        let blockedCount = session.replayDiagnostics.filter { $0.blockingReason != .noBlockingReason }.count
        let eligibleCount = records.filter { $0.eligibleForUserVisibleEstimatedRoute }.count
        let reviewRecommendedCount = records.filter { record in
            !record.eligibleForUserVisibleEstimatedRoute || !record.blockingReasons.isEmpty
        }.count
        return DeadReckoningReplayReviewSessionSummary(
            sessionIdentifier: session.sessionIdentifier,
            totalGapCount: session.replayDiagnostics.count,
            replaySucceededGapCount: replaySucceededCount,
            blockedGapCount: blockedCount,
            userVisibleEligibleGapCount: eligibleCount,
            reviewRecommendedGapCount: reviewRecommendedCount,
            maximumClosureErrorMeters: maximumClosureError
        )
    }

    private static func makeGapRecord(
        sessionIdentifier: String,
        gapIndex: Int,
        diagnostics: DeadReckoningReplayDiagnostics
    ) -> DeadReckoningReplayReviewGapRecord {
        let closure = diagnostics.closureDiagnostics
        let replayBlockingReasons = diagnostics.blockingReason == .noBlockingReason
            ? []
            : [diagnostics.blockingReason.rawValue]
        let closureBlockingReasons = closure?.blockingReasons ?? []
        return DeadReckoningReplayReviewGapRecord(
            sessionIdentifier: sessionIdentifier,
            gapIndex: gapIndex,
            gapStartTimestamp: diagnostics.gapStartTimestamp,
            gapEndTimestamp: diagnostics.gapEndTimestamp,
            gapDurationSeconds: diagnostics.gapDurationSeconds,
            replayBlockingReason: diagnostics.blockingReason,
            estimateCount: diagnostics.estimates.count,
            estimatedDisplacementMeters: closure?.estimatedDistanceMeters ?? pathDistanceMeters(for: diagnostics.estimates),
            anchorClosureErrorMeters: closure?.closureErrorMeters ?? diagnostics.anchorClosureErrorMeters,
            closureErrorRatio: closure?.closureErrorRatio,
            headingReliability: closure?.headingReliability ?? .unavailable,
            imuSampleCoverageRatio: closure?.imuSampleCoverageRatio ?? 0,
            eligibleForUserVisibleEstimatedRoute: closure?.eligibleForUserVisibleEstimatedRoute ?? false,
            blockingReasons: replayBlockingReasons + closureBlockingReasons
        )
    }

    private static func pathDistanceMeters(for estimates: [DeadReckoningReplayEstimate]) -> Double {
        guard !estimates.isEmpty else { return 0 }
        var totalDistanceMeters = 0.0
        var previousEastMeters = 0.0
        var previousNorthMeters = 0.0
        for estimate in estimates {
            let eastDelta = estimate.localEastMeters - previousEastMeters
            let northDelta = estimate.localNorthMeters - previousNorthMeters
            totalDistanceMeters += sqrt((eastDelta * eastDelta) + (northDelta * northDelta))
            previousEastMeters = estimate.localEastMeters
            previousNorthMeters = estimate.localNorthMeters
        }
        return totalDistanceMeters
    }

    private static func sanitizedArtifactBaseName(for pack: DeadReckoningReplayReviewPack) -> String {
        let sessionToken = pack.sessionSummaries.map { $0.sessionIdentifier }.joined(separator: "_")
        let rawName = sessionToken.isEmpty ? "all_sessions" : sessionToken
        let sanitizedName = rawName.map { character -> Character in
            character.isLetter || character.isNumber || character == "_" || character == "-" ? character : "_"
        }
        return "Task030c_b17D_\(String(sanitizedName))_ReplayReviewPack"
    }

    private static func format(_ value: Double) -> String {
        String(format: "%.3f", value)
    }

    private static func formatOptional(_ value: Double?) -> String {
        guard let value else { return "" }
        return format(value)
    }

    private static func csvEscape(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            return "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return value
    }
}
