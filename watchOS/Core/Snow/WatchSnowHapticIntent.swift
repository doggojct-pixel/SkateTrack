// [Collaboration Zone] WatchSnowHapticIntent.swift
// Purpose: Semantic haptic intents for mock-backed Watch Snow UI transitions.

import Foundation

enum WatchSnowHapticIntent: String, Equatable, Sendable {
    case runStarted
    case liftDetected
    case fallAlert
    case lowConfidence
    case paused
    case resumed
    case maneuverMarked
    case sessionEnded

    var titleKey: String {
        switch self {
        case .runStarted:
            return "snow.watch.haptic.runStarted"
        case .liftDetected:
            return "snow.watch.haptic.liftDetected"
        case .fallAlert:
            return "snow.watch.haptic.fallAlert"
        case .lowConfidence:
            return "snow.watch.haptic.lowConfidence"
        case .paused:
            return "snow.watch.haptic.paused"
        case .resumed:
            return "snow.watch.haptic.resumed"
        case .maneuverMarked:
            return "snow.watch.haptic.maneuverMarked"
        case .sessionEnded:
            return "snow.watch.haptic.sessionEnded"
        }
    }
}
