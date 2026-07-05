// [協作區] Shared/ActivityVisualization/Route/RouteDisplayPipeline+Filtering.swift
// Purpose: Keeps display-only route sample filtering and de-duplication helpers separate from route orchestration.
// Delegates to: MotionSample source-of-truth data and ActivityFidelityPolicy thresholds.

import Foundation

extension RouteDisplayPipeline {
    func deduplicatedTrustedLocationFixes(
        from samples: [MotionSample],
        fidelityPolicy: ActivityFidelityPolicy
    ) -> [MotionSample] {
        let primary = deduplicatedTrustedLocationFixes(
            from: samples,
            fidelityPolicy: fidelityPolicy,
            allowsTimerFusionFallback: false
        )
        if !primary.isEmpty { return primary }
        return deduplicatedTrustedLocationFixes(
            from: samples,
            fidelityPolicy: fidelityPolicy,
            allowsTimerFusionFallback: true
        )
    }

    func deduplicatedTrustedLocationFixes(
        from samples: [MotionSample],
        fidelityPolicy: ActivityFidelityPolicy,
        allowsTimerFusionFallback: Bool
    ) -> [MotionSample] {
        var seenKeys = Set<String>()
        return samples.sorted { routeTimestamp(for: $0) < routeTimestamp(for: $1) }.compactMap { sample in
            guard validCoordinate(from: sample) != nil,
                  isTrustedDisplayRouteSample(
                      sample,
                      fidelityPolicy: fidelityPolicy,
                      allowsTimerFusionFallback: allowsTimerFusionFallback
                  ) else { return nil }
            let key = locationFixKey(for: sample)
            guard seenKeys.insert(key).inserted else { return nil }
            return sample
        }
    }

    func isTrustedDisplayRouteSample(
        _ sample: MotionSample,
        fidelityPolicy: ActivityFidelityPolicy,
        allowsTimerFusionFallback: Bool
    ) -> Bool {
        guard allowsTimerFusionFallback
                || sample.sampleSource != .timerFusion
                || sample.locationDiagnostics?.rawLocationTimestampMillisecondsSince1970 == nil else {
            return false
        }

        guard let diagnostics = sample.locationDiagnostics else { return true }
        if diagnostics.freshnessState == .stale { return false }
        if diagnostics.gpsUpdateIntervalSeconds.map({ $0 > max(12, fidelityPolicy.maximumTrustedUpdateIntervalSeconds + 4) }) == true { return false }
        if diagnostics.horizontalAccuracyMeters.map({ $0 > fidelityPolicy.displayRouteMaximumHorizontalAccuracyMeters }) == true { return false }
        if diagnostics.coordinateDerivedSpeedKmh.map({ $0 > fidelityPolicy.maximumTrustedImpliedSpeedKmh }) == true { return false }
        return true
    }

    func validCoordinate(from sample: MotionSample) -> GeoCoordinate? {
        guard let coordinate = sample.gpsCoordinate,
              coordinate.latitude.isFinite,
              coordinate.longitude.isFinite,
              (-90.0...90.0).contains(coordinate.latitude),
              (-180.0...180.0).contains(coordinate.longitude) else {
            return nil
        }
        return coordinate
    }

    func locationFixKey(for sample: MotionSample) -> String {
        if let timestamp = sample.locationDiagnostics?.rawLocationTimestampMillisecondsSince1970 {
            return "locationFix:\(timestamp)"
        }

        if let coordinate = sample.gpsCoordinate {
            let latitude = (coordinate.latitude * 100_000).rounded() / 100_000
            let longitude = (coordinate.longitude * 100_000).rounded() / 100_000
            let second = Int(sample.timestamp.timeIntervalSince1970.rounded())
            return "coordinate:\(latitude):\(longitude):\(second)"
        }

        return sample.id.uuidString
    }

}
