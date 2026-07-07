// [Collaboration] SkateTrackWatchApp.swift
// Purpose: Defines SkateTrack watchOS App entry point and hosts the Task-036b live session face shell.
// Delegates to: watchOS/Features and Shared WatchUI view models.

import SwiftUI

@main
struct SkateTrackWatchApp: App {
    var body: some Scene {
        WindowGroup {
            WatchLiveSessionFaceView(viewModel: WatchActivityViewModel())
        }
    }
}
