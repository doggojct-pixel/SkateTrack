// [Collaboration Zone] WatchSnowMockScenario.swift
// Purpose: DEBUG scenario identifiers for mock-backed Watch Snow UI QA.

import Foundation

enum WatchSnowMockScenario: String, CaseIterable, Identifiable, Sendable {
    case downhill
    case liftOrGondola
    case waiting
    case lowConfidence
    case fallAlert
    case summary

    var id: String { rawValue }

    var titleKey: String {
        switch self {
        case .downhill:
            return "snow.watch.scenario.downhill"
        case .liftOrGondola:
            return "snow.watch.scenario.lift"
        case .waiting:
            return "snow.watch.scenario.waiting"
        case .lowConfidence:
            return "snow.watch.scenario.lowConfidence"
        case .fallAlert:
            return "snow.watch.scenario.fallAlert"
        case .summary:
            return "snow.watch.scenario.summary"
        }
    }
}
