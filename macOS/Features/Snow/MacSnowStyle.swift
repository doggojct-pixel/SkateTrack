// [協作區] MacSnowStyle.swift
// 用途：定義 macOS Snow viewer 的 read-only 視覺樣式，不承載資料來源或 package schema。
// 委派至：MacSnowComponents 與 macOS Snow viewer views。

import SwiftUI

enum MacSnowStyle {
    static let panelCornerRadius: CGFloat = 22
    static let cardCornerRadius: CGFloat = 16
    static let routeLineWidth: CGFloat = 4

    // Palette aligned with SkateTrack_SnowMode_UI_v1.1.1.
    static let os = Color(red: 0.024, green: 0.063, blue: 0.118)
    static let os2 = Color(red: 0.031, green: 0.090, blue: 0.165)
    static let win = Color(red: 0.043, green: 0.071, blue: 0.125)
    static let panel = Color(red: 0.063, green: 0.114, blue: 0.200)
    static let panel2 = Color(red: 0.075, green: 0.149, blue: 0.251)
    static let card = Color(red: 0.090, green: 0.165, blue: 0.278)
    static let card2 = Color(red: 0.106, green: 0.208, blue: 0.345)
    static let ice = Color(red: 0.467, green: 0.910, blue: 1.000)
    static let ice2 = Color(red: 0.725, green: 0.961, blue: 1.000)
    static let blue = Color(red: 0.220, green: 0.741, blue: 0.973)
    static let deep = Color(red: 0.145, green: 0.388, blue: 0.922)
    static let mint = Color(red: 0.408, green: 0.949, blue: 0.761)
    static let amber = Color(red: 0.984, green: 0.749, blue: 0.141)
    static let purple = Color(red: 0.655, green: 0.545, blue: 0.980)
    static let red = Color(red: 0.984, green: 0.443, blue: 0.522)
    static let snowText = Color(red: 0.949, green: 0.984, blue: 1.000)
    static let text2 = Color(red: 0.686, green: 0.773, blue: 0.906)
    static let text3 = Color(red: 0.435, green: 0.533, blue: 0.690)

    static var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [
                os,
                os2,
                panel.opacity(0.90)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var auroraGradient: RadialGradient {
        RadialGradient(
            colors: [
                ice.opacity(0.20),
                blue.opacity(0.10),
                Color.clear
            ],
            center: .topTrailing,
            startRadius: 24,
            endRadius: 720
        )
    }

    static var panelGradient: LinearGradient {
        LinearGradient(
            colors: [
                panel2.opacity(0.78),
                panel.opacity(0.62),
                win.opacity(0.72)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var cardGradient: LinearGradient {
        LinearGradient(
            colors: [
                card2.opacity(0.72),
                card.opacity(0.52)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var metricGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.085),
                ice.opacity(0.045),
                Color.white.opacity(0.035)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var selectedRowGradient: LinearGradient {
        LinearGradient(
            colors: [
                ice.opacity(0.18),
                blue.opacity(0.10),
                card2.opacity(0.42)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    static var mapGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.043, green: 0.102, blue: 0.180),
                Color(red: 0.027, green: 0.063, blue: 0.114)
            ],
            startPoint: .topTrailing,
            endPoint: .bottomLeading
        )
    }

    static var sectionStroke: Color { Color.white.opacity(0.13) }
    static var iceStroke: Color { ice.opacity(0.34) }

    static func segmentColor(for type: SnowSegmentType) -> Color {
        switch type {
        case .downhillRun, .flatTraverse:
            return ice
        case .liftAscent, .gondolaAscent, .surfaceLiftAscent:
            return amber
        case .walking:
            return mint
        case .stopped:
            return purple
        case .unknown:
            return red
        }
    }

    static func segmentGradient(for type: SnowSegmentType) -> LinearGradient {
        LinearGradient(
            colors: [
                segmentColor(for: type).opacity(0.22),
                segmentColor(for: type).opacity(0.06)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    static func countedLabelKey(for segment: SnowSegment) -> String {
        segment.countsTowardSkiDistance ? "mac.snow.inspector.counted" : "mac.snow.inspector.excluded"
    }
}
