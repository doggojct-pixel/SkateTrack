// [協作區] macOS/Features/SessionBrowser/MacRouteInspectionWindowPresenter.swift
// 用途：以可調整大小的 macOS 視窗呈現唯讀 route inspection，讓使用者可拖拉視窗並使用 MapKit 內建縮放 / 平移。
// 委派至：MacRouteInspectionView；本檔不請求定位、不顯示 user location、不做 road matching、snap-to-road 或 route mutation。

import AppKit
import SwiftUI

final class MacRouteInspectionWindowPresenter: NSObject, NSWindowDelegate {
    static let shared = MacRouteInspectionWindowPresenter()

    private var openWindows: [NSWindow] = []

    func open(points: [MacRoutePoint], summary: MacRouteSummary) {
        var routeWindow: NSWindow?
        let contentView = MacRouteInspectionView(points: points, summary: summary) {
            routeWindow?.close()
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1120, height: 780),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        routeWindow = window
        window.title = NSLocalizedString("mac.viewer.route.inspect.title", comment: "")
        window.minSize = NSSize(width: 860, height: 680)
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.contentView = NSHostingView(rootView: contentView)
        window.center()

        openWindows.append(window)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func windowWillClose(_ notification: Notification) {
        guard let closedWindow = notification.object as? NSWindow else { return }
        openWindows.removeAll { $0 === closedWindow }
    }
}
