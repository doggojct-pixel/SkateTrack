// [協作區] watchOS/Features/WatchMetricCarouselView.swift
// Purpose: Renders the Task-037b base Watch metric carousel from safe provider outputs.
// Delegates to: WatchMetricCarouselModel and Shared compact speed/elevation display points.

import SwiftUI

struct WatchMetricCarouselView: View {
    let model: WatchMetricCarouselModel
    let accentColor: Color

    init(
        selection: WatchMetricProviderSelectionResult,
        accentColor: Color
    ) {
        self.model = WatchMetricCarouselModel(selection: selection)
        self.accentColor = accentColor
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text("watch.metric.carousel.title")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                Spacer(minLength: 0)
                WatchMetricCarouselPillView(
                    titleKey: model.hasCards
                        ? "watch.metric.carousel.subtitle"
                        : "watch.metric.carousel.empty"
                )
            }

            if model.hasCards {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(model.cards) { card in
                            WatchMetricCarouselCardView(
                                card: card,
                                accentColor: color(for: card)
                            )
                            .frame(width: 156)
                        }
                    }
                    .padding(.vertical, 2)
                }
                .accessibilityIdentifier("watch-metric-carousel")
            } else {
                WatchMetricCarouselUnsupportedCardView()
                    .accessibilityIdentifier("watch-metric-carousel-empty")
            }
        }
        .padding(.vertical, 2)
    }

    private func color(for card: WatchMetricCarouselCardModel) -> Color {
        card.isAvailable ? accentColor : accentColor.opacity(0.72)
    }
}

private struct WatchMetricCarouselCardView: View {
    let card: WatchMetricCarouselCardModel
    let accentColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 8) {
                Image(systemName: iconName)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(accentColor)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(LocalizedStringKey(card.titleLocalizationKey))
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                    Text(LocalizedStringKey(card.detailLocalizationKey))
                        .font(.system(size: 8, weight: .heavy, design: .monospaced))
                        .foregroundStyle(WatchMetricCarouselPalette.textTertiary)
                        .textCase(.uppercase)
                        .lineLimit(1)
                        .minimumScaleFactor(0.68)
                }
                Spacer(minLength: 0)
            }

            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(card.valueText)
                    .font(.system(size: 27, weight: .heavy, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(card.isAvailable ? .white : accentColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                if let unitKey = card.unitLocalizationKey {
                    Text(LocalizedStringKey(unitKey))
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(WatchMetricCarouselPalette.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }
            }

            if card.kind == .route || card.kind == .cadence {
                WatchMetricCarouselPillView(titleKey: card.detailLocalizationKey)
            } else {
                WatchMetricCarouselSparklineView(
                    points: card.sparklinePoints,
                    tintColor: accentColor,
                    isAvailable: card.isAvailable
                )
                .frame(height: 28)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, minHeight: 140, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(WatchMetricCarouselPalette.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(accentColor.opacity(card.isAvailable ? 0.38 : 0.22), lineWidth: 1)
        )
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(accentColor.opacity(card.isAvailable ? 0.18 : 0.10))
                .frame(width: 42, height: 42)
                .blur(radius: 10)
                .offset(x: 10, y: -10)
                .accessibilityHidden(true)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(LocalizedStringKey(card.titleLocalizationKey)))
        .accessibilityValue(Text(LocalizedStringKey(card.detailLocalizationKey)))
        .accessibilityIdentifier(card.accessibilityIdentifier)
    }

    private var iconName: String {
        switch card.kind {
        case .route:
            return "point.topleft.down.curvedto.point.bottomright.up"
        case .speed:
            return "speedometer"
        case .elevation:
            return "mountain.2.fill"
        case .cadence:
            return "timer"
        }
    }
}

private struct WatchMetricCarouselUnsupportedCardView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.headline.weight(.bold))
                .foregroundStyle(WatchMetricCarouselPalette.textSecondary)
                .accessibilityHidden(true)
            Text("watch.metric.carousel.empty")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
            Text("watch.metric.card.unsupported")
                .font(.caption2)
                .foregroundStyle(WatchMetricCarouselPalette.textSecondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, minHeight: 104, alignment: .leading)
        .background(WatchMetricCarouselPalette.card)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

private struct WatchMetricCarouselSparklineView: View {
    let points: [CompactSparklinePoint]
    let tintColor: Color
    let isAvailable: Bool

    var body: some View {
        GeometryReader { proxy in
            if isAvailable && points.count >= 2 {
                Path { path in
                    for index in points.indices {
                        let point = points[index]
                        let xRatio = points.count == 1 ? 0 : CGFloat(index) / CGFloat(points.count - 1)
                        let x = xRatio * proxy.size.width
                        let y = (1 - CGFloat(point.normalizedValue)) * proxy.size.height
                        if index == points.startIndex {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(tintColor, style: StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round))
            } else {
                HStack(spacing: 4) {
                    Capsule().fill(tintColor.opacity(0.36)).frame(width: proxy.size.width * 0.18)
                    Capsule().fill(tintColor.opacity(0.24)).frame(width: proxy.size.width * 0.28)
                    Capsule().fill(WatchMetricCarouselPalette.panel).frame(maxWidth: .infinity)
                }
            }
        }
        .accessibilityHidden(true)
    }
}

private struct WatchMetricCarouselPillView: View {
    let titleKey: String

    var body: some View {
        Text(LocalizedStringKey(titleKey))
            .font(.system(size: 9, weight: .heavy, design: .monospaced))
            .foregroundStyle(WatchMetricCarouselPalette.textSecondary)
            .lineLimit(1)
            .minimumScaleFactor(0.62)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(WatchMetricCarouselPalette.panel)
            .clipShape(Capsule())
    }
}

private enum WatchMetricCarouselPalette {
    static let panel = Color(red: 0.092, green: 0.124, blue: 0.203).opacity(0.95)
    static let card = Color(red: 0.083, green: 0.125, blue: 0.220).opacity(0.96)
    static let textSecondary = Color(red: 0.700, green: 0.745, blue: 0.860)
    static let textTertiary = Color(red: 0.470, green: 0.535, blue: 0.680)
}
