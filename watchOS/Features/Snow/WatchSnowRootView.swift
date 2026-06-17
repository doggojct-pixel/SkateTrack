// [Collaboration Zone] WatchSnowRootView.swift
// Purpose: watchOS Snow root with DEBUG mock gallery and Release-safe fallback.

import SwiftUI

struct WatchSnowRootView: View {
    var body: some View {
        #if DEBUG
        WatchSnowMockGalleryView()
        #else
        WatchSnowUnavailableView()
        #endif
    }
}
