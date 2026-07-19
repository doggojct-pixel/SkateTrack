// [Collaboration Zone] WatchSnowStyle.swift
// Purpose: Production-safe watchOS Snow visual helpers adapted from the prototype UI pack.

import SwiftUI

enum WatchSnowPalette {
    static let navy = Color(red: 0.027, green: 0.063, blue: 0.114)
    static let navy2 = Color(red: 0.043, green: 0.078, blue: 0.141)
    static let panel = Color(red: 0.071, green: 0.125, blue: 0.224)
    static let card = Color(red: 0.094, green: 0.157, blue: 0.259)
    static let snow = Color(red: 0.918, green: 0.973, blue: 1.0)
    static let ice = Color(red: 0.455, green: 0.91, blue: 1.0)
    static let blue = Color(red: 0.22, green: 0.741, blue: 0.973)
    static let mint = Color(red: 0.431, green: 0.906, blue: 0.718)
    static let purple = Color(red: 0.655, green: 0.545, blue: 0.98)
    static let amber = Color(red: 0.984, green: 0.749, blue: 0.141)
    static let red = Color(red: 0.984, green: 0.443, blue: 0.522)
    static let text2 = Color(red: 0.718, green: 0.78, blue: 0.902)
    static let text3 = Color(red: 0.471, green: 0.565, blue: 0.722)
}

struct WatchSnowIcyBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    LinearGradient(
                        colors: [WatchSnowPalette.navy, Color.black],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    RadialGradient(
                        colors: [WatchSnowPalette.ice.opacity(0.24), .clear],
                        center: .top,
                        startRadius: 10,
                        endRadius: 150
                    )
                    RadialGradient(
                        colors: [WatchSnowPalette.purple.opacity(0.12), .clear],
                        center: .bottomTrailing,
                        startRadius: 10,
                        endRadius: 120
                    )
                }
                .ignoresSafeArea()
            )
    }
}

extension View {
    func watchSnowBackground() -> some View {
        modifier(WatchSnowIcyBackground())
    }

    func watchSnowCard(cornerRadius: CGFloat = 18) -> some View {
        padding(10)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(WatchSnowPalette.panel.opacity(0.74))
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(WatchSnowPalette.ice.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: WatchSnowPalette.ice.opacity(0.08), radius: 12, x: 0, y: 6)
            )
    }
}

struct WatchSnowHeaderBadge: View {
    let titleKey: String
    let systemImage: String
    let color: Color

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: systemImage)
            Text(LocalizedStringKey(titleKey))
        }
        .font(.system(size: 11, weight: .bold, design: .rounded))
        .foregroundStyle(color)
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(Capsule().fill(color.opacity(0.14)))
        .overlay(Capsule().stroke(color.opacity(0.26), lineWidth: 1))
    }
}
