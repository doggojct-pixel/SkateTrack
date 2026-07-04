// [協作區] macOS/Features/SessionBrowser/MacRouteVisualStyle.swift
// 用途：集中管理 Task-030e-007B macOS read-only route visual parity colors 與 legend metadata。
// 委派至：MacRouteMapContextView / MacRouteInspectionView；只做顯示樣式，不表示路線修正、不 map-match、不 snap、不修改 trusted metrics。

import AppKit
import SwiftUI

enum MacRouteVisualStyle: CaseIterable {
    case fluorescentPinkGlow
    case brightOrangeAccent
    case trustedGreenRoute
    case startMarker
    case finishMarker

    var swiftUIColor: Color {
        switch self {
        case .fluorescentPinkGlow:
            return Color(red: 1.0, green: 0.2, blue: 0.6)
        case .brightOrangeAccent:
            return Color(red: 1.0, green: 0.56, blue: 0.0)
        case .trustedGreenRoute:
            return Color(red: 0.0, green: 0.831, blue: 0.667)
        case .startMarker:
            return Color(red: 0.063, green: 0.725, blue: 0.506)
        case .finishMarker:
            return Color(red: 0.961, green: 0.651, blue: 0.137)
        }
    }

    var appKitColor: NSColor {
        NSColor(swiftUIColor)
    }

    var lineWidth: CGFloat {
        switch self {
        case .fluorescentPinkGlow, .brightOrangeAccent, .trustedGreenRoute:
            return 4.6
        case .startMarker, .finishMarker:
            return 0
        }
    }

    var opacity: CGFloat {
        switch self {
        case .fluorescentPinkGlow, .brightOrangeAccent, .trustedGreenRoute:
            return 0.96
        case .startMarker, .finishMarker:
            return 1.0
        }
    }

    var legendKey: String {
        switch self {
        case .fluorescentPinkGlow:
            return "mac.viewer.route.legend.pink"
        case .brightOrangeAccent:
            return "mac.viewer.route.legend.orange"
        case .trustedGreenRoute:
            return "mac.viewer.route.legend.green"
        case .startMarker:
            return "mac.viewer.route.legend.start"
        case .finishMarker:
            return "mac.viewer.route.legend.finish"
        }
    }

    var isRouteLine: Bool {
        switch self {
        case .fluorescentPinkGlow, .brightOrangeAccent, .trustedGreenRoute:
            return true
        case .startMarker, .finishMarker:
            return false
        }
    }
}

enum MacRouteSegmentStyle: Equatable {
    case trusted
    case uncertain
    case startupWarmup

    var visualStyle: MacRouteVisualStyle {
        switch self {
        case .trusted:
            return .trustedGreenRoute
        case .uncertain:
            return .brightOrangeAccent
        case .startupWarmup:
            return .fluorescentPinkGlow
        }
    }
}
