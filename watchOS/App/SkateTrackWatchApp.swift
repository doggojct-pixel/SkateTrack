// [Collaboration Zone] SkateTrackWatchApp.swift
// Purpose: Defines the SkateTrack watchOS app entry point.
// Notes: Snow-Task-006a routes DEBUG builds to the mock-backed Watch Snow UI; Release keeps a neutral fallback until real WatchBridge wiring lands in 006b.

import SwiftUI

@main
struct SkateTrackWatchApp: App {
    var body: some Scene {
        WindowGroup {
            WatchSnowRootView()
        }
    }
}
