// [協作區] WatchSnowLaunchRoute.swift
// Purpose: Resolves the DEBUG-only Watch Snow mock-gallery launch argument without changing the default root.
// Delegates to: SkateTrackWatchApp; contains no transport, session authority, or provider ownership.

import Foundation

enum WatchSnowLaunchRoute: Equatable, Sendable {
    case mainline
    #if DEBUG
    case snowMockGallery
    #endif
}

enum WatchSnowLaunchRouter {
    #if DEBUG
    static let mockGalleryArgument = "-SnowMockGallery"
    #endif

    static func resolve(arguments: [String], isDebugBuild: Bool) -> WatchSnowLaunchRoute {
        #if DEBUG
        guard isDebugBuild, arguments.contains(mockGalleryArgument) else {
            return .mainline
        }
        return .snowMockGallery
        #else
        return .mainline
        #endif
    }
}
