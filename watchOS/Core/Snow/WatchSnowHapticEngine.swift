// [Collaboration Zone] WatchSnowHapticEngine.swift
// Purpose: Narrow wrapper around local Watch haptics for Snow UI intents.
//          This file must remain local-only and must not depend on external transport plumbing.

import Foundation
import WatchKit

protocol WatchSnowHapticPlaying {
    func play(_ intent: WatchSnowHapticIntent)
}

struct WatchSnowHapticEngine: WatchSnowHapticPlaying {
    func play(_ intent: WatchSnowHapticIntent) {
        switch intent {
        case .runStarted, .resumed, .maneuverMarked:
            WKInterfaceDevice.current().play(.success)
        case .liftDetected, .paused:
            WKInterfaceDevice.current().play(.directionUp)
        case .fallAlert, .lowConfidence:
            WKInterfaceDevice.current().play(.failure)
        case .sessionEnded:
            WKInterfaceDevice.current().play(.stop)
        }
    }
}
