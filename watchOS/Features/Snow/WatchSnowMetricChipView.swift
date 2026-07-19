// [Collaboration Zone] WatchSnowMetricChipView.swift
// Purpose: Compact watchOS Snow metric chip shared by mock-backed Watch Snow cards.

import SwiftUI

struct WatchSnowMetricChipView: View {
    let titleKey: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(LocalizedStringKey(titleKey))
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(WatchSnowPalette.text3)
            Text(value)
                .font(.system(size: 17, weight: .black, design: .rounded))
                .foregroundStyle(color)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 14).fill(WatchSnowPalette.card.opacity(0.72)))
    }
}
