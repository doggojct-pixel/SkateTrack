// [協作區] Shared/WatchUI/WatchRewardFoundationState.swift
// Purpose: Defines a local-only early-bird reward foundation shell for Task-039c.
// Delegates to: future decisions without adding monetization frameworks or release claims.

import Foundation

enum WatchRewardFoundationAvailability: String, Codable, Equatable, Sendable {
    case localShellOnly
    case preADPDisabled
}

enum WatchRewardFoundationEntryKind: String, CaseIterable, Codable, Equatable, Identifiable, Sendable {
    case firstSession
    case steadyWeek
    case safetyReview

    var id: String { rawValue }
}

struct WatchRewardFoundationEntry: Identifiable, Codable, Equatable, Sendable {
    let kind: WatchRewardFoundationEntryKind
    let isEarned: Bool
    let localProgress: Double

    var id: WatchRewardFoundationEntryKind { kind }

    init(
        kind: WatchRewardFoundationEntryKind,
        isEarned: Bool = false,
        localProgress: Double = 0
    ) {
        self.kind = kind
        self.isEarned = isEarned
        self.localProgress = Self.clampedProgress(localProgress)
    }

    private static func clampedProgress(_ value: Double) -> Double {
        guard value.isFinite else {
            return 0
        }
        return min(max(value, 0), 1)
    }
}

struct WatchRewardFoundationState: Codable, Equatable, Sendable {
    let generatedAt: Date
    let availability: WatchRewardFoundationAvailability
    let entries: [WatchRewardFoundationEntry]

    init(
        generatedAt: Date = Date(),
        availability: WatchRewardFoundationAvailability,
        entries: [WatchRewardFoundationEntry]
    ) {
        self.generatedAt = generatedAt
        self.availability = availability
        self.entries = entries
    }

    static func localShell(
        generatedAt: Date = Date()
    ) -> WatchRewardFoundationState {
        WatchRewardFoundationState(
            generatedAt: generatedAt,
            availability: .localShellOnly,
            entries: WatchRewardFoundationEntryKind.allCases.map {
                WatchRewardFoundationEntry(kind: $0)
            }
        )
    }

    var hasLocalEntries: Bool {
        !entries.isEmpty
    }

    var isLocalOnly: Bool {
        true
    }

    var usesMonetizationFramework: Bool {
        false
    }

    var usesProductionMonetization: Bool {
        false
    }

    var grantsEntitlement: Bool {
        false
    }

    var unlocksPaidFeatures: Bool {
        false
    }

    var exposesReleaseClaim: Bool {
        false
    }

    var syncsRemoteRewardState: Bool {
        false
    }
}
