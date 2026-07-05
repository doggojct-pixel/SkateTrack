// [協作區] Shared/ActivityVisualization/Route/RouteDisplayPipeline+Startup.swift
// Purpose: Isolates startup GPS lock and warmup classification logic for display-only route preparation.
// Delegates to: MotionSample diagnostics and ActivityFidelityPolicy profile thresholds.

import Foundation

extension RouteDisplayPipeline {
    func isStartupWarmupSample(
        _ sample: MotionSample,
        startDate: Date,
        fidelityPolicy: ActivityFidelityPolicy,
        stableStartupAnchorTimestamp: Date?,
        gpsLockAnchorTimestamp: Date?,
        hasReliableAnchor: Bool
    ) -> Bool {
        let timestamp = routeTimestamp(for: sample)
        let elapsed = timestamp.timeIntervalSince(startDate)
        if elapsed < 0 { return elapsed >= -10 }
        guard !hasReliableAnchor else { return false }
        guard elapsed <= Self.startupConvergenceWarmupSeconds else { return false }
        guard let diagnostics = sample.locationDiagnostics else { return elapsed <= 8 }

        let accuracy = diagnostics.horizontalAccuracyMeters ?? .infinity
        let warmupAccuracyLimit = max(fidelityPolicy.preferredHorizontalAccuracyMeters * 1.8, 18)
        if diagnostics.freshnessState == .stale { return true }
        if diagnostics.routeSegmentConfidence == .low || diagnostics.routeSegmentConfidence == .unavailable { return true }
        if accuracy > warmupAccuracyLimit { return true }

        if startupAnchorGuardApplies(fidelityPolicy: fidelityPolicy) {
            guard let stableStartupAnchorTimestamp else {
                return elapsed <= Self.startupConvergenceWarmupSeconds
                    && !isPreferredFreshAnchor(sample, fidelityPolicy: fidelityPolicy)
            }
            if timestamp < stableStartupAnchorTimestamp { return true }
            return elapsed <= Self.startupRouteVisualSuppressionMaximumSeconds
                && timestamp.timeIntervalSince(stableStartupAnchorTimestamp) <= 3
                && !isPreferredFreshAnchor(sample, fidelityPolicy: fidelityPolicy)
        }

        if let gpsLockAnchorTimestamp {
            return timestamp < gpsLockAnchorTimestamp
        }

        return elapsed <= 10 && !isPreferredFreshAnchor(sample, fidelityPolicy: fidelityPolicy)
    }

    func firstStableStartupAnchorTimestamp(
        gpsLockAnchorTimestamp: Date?,
        fidelityPolicy: ActivityFidelityPolicy
    ) -> Date? {
        guard startupAnchorGuardApplies(fidelityPolicy: fidelityPolicy) else { return nil }
        return gpsLockAnchorTimestamp
    }

    func startupAnchorGuardApplies(fidelityPolicy: ActivityFidelityPolicy) -> Bool {
        switch fidelityPolicy.profile {
        case .technicalSkateboard, .standardSkateboard, .electricSkateboard, .inlineRecreation:
            return true
        case .inlineSpeed, .snowReserved, .vehicleValidation:
            return fidelityPolicy.usesStrictSmallAreaLowSpeedGate
        }
    }

    func firstGPSLockAnchorTimestamp(
        from candidates: [MotionSample],
        startDate: Date,
        fidelityPolicy: ActivityFidelityPolicy
    ) -> Date? {
        let lockCandidates = candidates.filter { sample in
            let elapsed = routeTimestamp(for: sample).timeIntervalSince(startDate)
            return elapsed >= 0
                && elapsed <= Self.startupGPSLockSearchWindowSeconds
                && isPreferredFreshAnchor(sample, fidelityPolicy: fidelityPolicy)
        }
        guard lockCandidates.count >= Self.startupStableAnchorMinimumCandidateCount else { return nil }

        for candidate in lockCandidates {
            let anchorTime = routeTimestamp(for: candidate)
            let cluster = lockCandidates.filter { sample in
                let delta = routeTimestamp(for: sample).timeIntervalSince(anchorTime)
                return delta >= 0 && delta <= Self.startupStableAnchorClusterWindowSeconds
            }
            guard cluster.count >= Self.startupStableAnchorMinimumCandidateCount else { continue }
            return anchorTime
        }

        return nil
    }

    func isPreferredFreshAnchor(
        _ sample: MotionSample,
        fidelityPolicy: ActivityFidelityPolicy
    ) -> Bool {
        guard let diagnostics = sample.locationDiagnostics else { return false }
        let accuracy = diagnostics.horizontalAccuracyMeters ?? .infinity
        return diagnostics.freshnessState == .fresh
            && diagnostics.routeSegmentConfidence == .high
            && accuracy <= fidelityPolicy.preferredHorizontalAccuracyMeters
    }

}
