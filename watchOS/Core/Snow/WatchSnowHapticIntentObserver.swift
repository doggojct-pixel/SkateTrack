// [Collaboration Zone] WatchSnowHapticIntentObserver.swift
// Purpose: Pure transition mapper from Watch Snow snapshots to haptic intents.
//          It intentionally owns no Combine subscription and does not depend on
//          external transport delivery timing.

import Foundation

struct WatchSnowHapticIntentObserver: Sendable {
    func intent(
        from oldSnapshot: WatchSnowSessionSnapshot,
        to newSnapshot: WatchSnowSessionSnapshot
    ) -> WatchSnowHapticIntent? {
        if oldSnapshot.fallAlertActive == false,
           newSnapshot.fallAlertActive == true {
            return .fallAlert
        }

        if isLowConfidenceTransition(from: oldSnapshot, to: newSnapshot) {
            return .lowConfidence
        }

        if oldSnapshot.snowSegmentType != newSnapshot.snowSegmentType,
           newSnapshot.snowSegmentType == "downhillRun" {
            return .runStarted
        }

        if oldSnapshot.snowSegmentType != newSnapshot.snowSegmentType,
           isUphillTransport(newSnapshot.snowSegmentType) {
            return .liftDetected
        }

        return nil
    }

    private func isLowConfidenceTransition(
        from oldSnapshot: WatchSnowSessionSnapshot,
        to newSnapshot: WatchSnowSessionSnapshot
    ) -> Bool {
        oldSnapshot.snowSegmentType != "unknown" && newSnapshot.snowSegmentType == "unknown"
    }

    private func isUphillTransport(_ segmentType: String?) -> Bool {
        switch segmentType {
        case "liftAscent", "gondolaAscent", "surfaceLiftAscent":
            return true
        default:
            return false
        }
    }
}
