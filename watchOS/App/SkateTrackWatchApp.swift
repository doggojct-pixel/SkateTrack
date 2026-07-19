// [協作區] SkateTrackWatchApp.swift
// Purpose: Defines SkateTrack watchOS App entry point and hosts the Task-036b live session face shell.
// Delegates to: watchOS/Features and Shared WatchUI view models.

import SwiftUI

@main
@MainActor
struct SkateTrackWatchApp: App {
    @StateObject private var watchBridgeRuntime: WatchBridgeWatchRuntime
    @StateObject private var snowSessionProvider: WatchBridgeSnowSessionProvider
    private let launchRoute: WatchSnowLaunchRoute

    init() {
        let runtime = WatchBridgeWatchRuntime()
        _watchBridgeRuntime = StateObject(wrappedValue: runtime)
        _snowSessionProvider = StateObject(
            wrappedValue: WatchBridgeSnowSessionProvider(runtime: runtime)
        )
        #if DEBUG
        launchRoute = WatchSnowLaunchRouter.resolve(
            arguments: ProcessInfo.processInfo.arguments,
            isDebugBuild: true
        )
        #else
        launchRoute = .mainline
        #endif
    }

    var body: some Scene {
        WindowGroup {
            Group {
                #if DEBUG
                if launchRoute == .snowMockGallery {
                    WatchSnowRootView()
                } else {
                    mainlineRoot
                }
                #else
                mainlineRoot
                #endif
            }
            .task {
                watchBridgeRuntime.activate()
            }
        }
    }

    @ViewBuilder
    private var mainlineRoot: some View {
        if watchBridgeRuntime.activityViewModel.session.mode.sportModeKey == "snow" {
            WatchSnowLiveView(snapshot: snowSessionProvider.currentSnapshot)
        } else {
            WatchLiveSessionFaceView(
                viewModel: watchBridgeRuntime.activityViewModel,
                onCommand: { command in
                    _ = watchBridgeRuntime.send(command)
                }
            )
        }
    }
}
