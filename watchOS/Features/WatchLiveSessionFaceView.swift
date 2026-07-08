// [Collaboration] watchOS/Features/WatchLiveSessionFaceView.swift
// Purpose: Provides the Task-036b live watch face shell for speed, session status, and mirrored controls.
// Delegates to: Shared WatchUI view models and WatchBridge command boundary.

import SwiftUI

struct WatchLiveSessionFaceView: View {
    @Environment(\.isLuminanceReduced) private var isLuminanceReduced

    let viewModel: WatchActivityViewModel
    let onCommand: (WatchBridgeCommandEnvelope) -> Void

    init(
        viewModel: WatchActivityViewModel,
        onCommand: @escaping (WatchBridgeCommandEnvelope) -> Void = { _ in }
    ) {
        self.viewModel = viewModel
        self.onCommand = onCommand
    }

    var body: some View {
        let speed = WatchLiveSpeedDisplayValue(
            currentSpeedMetersPerSecond: viewModel.metrics.currentSpeedMetersPerSecond
        )
        let controls = WatchLiveControlState(viewModel: viewModel)
        let modeAccent = WatchLivePalette.accentColor(for: viewModel.session.mode.sportModeKey)
        let metricSelection = WatchMetricProviderSelector().makeSelection(for: viewModel)

        Group {
            if isLuminanceReduced {
                WatchAlwaysOnFallbackView(
                    viewModel: viewModel,
                    speed: speed,
                    accentColor: modeAccent
                )
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("watch.live.title")
                            .font(.headline)
                            .foregroundStyle(.white)

                        if viewModel.fallback.isVisible {
                            WatchFallbackBannerView(
                                state: viewModel.fallback,
                                accentColor: modeAccent
                            )
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("watch.live.speed.current")
                                .font(.caption2)
                                .foregroundStyle(WatchLivePalette.textSecondary)
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text(speed.valueText)
                                    .font(.system(size: 34, weight: .bold, design: .rounded))
                                    .monospacedDigit()
                                    .foregroundStyle(modeAccent)
                                    .shadow(color: modeAccent.opacity(0.35), radius: 10, x: 0, y: 0)
                                Text(LocalizedStringKey(speed.unitLocalizationKey))
                                    .font(.caption)
                                    .foregroundStyle(WatchLivePalette.textSecondary)
                            }
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel(Text("watch.live.accessibility.currentSpeed"))
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("watch.live.session.status")
                                .font(.caption2)
                                .foregroundStyle(WatchLivePalette.textSecondary)
                            Text(LocalizedStringKey(WatchLiveSessionStatusLocalization.key(for: viewModel.session.state)))
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                                .accessibilityLabel(Text("watch.live.accessibility.sessionStatus"))
                        }

                        WatchMetricCarouselView(
                            selection: metricSelection,
                            accentColor: modeAccent
                        )

                        if controls.actions.isEmpty {
                            Text("watch.live.controls.pending")
                                .font(.caption)
                                .foregroundStyle(WatchLivePalette.textSecondary)
                        } else {
                            VStack(spacing: 6) {
                                ForEach(controls.actions) { action in
                                    Button {
                                        if let command = controls.makeCommand(for: action.kind) {
                                            onCommand(command)
                                        }
                                    } label: {
                                        Text(LocalizedStringKey(action.titleLocalizationKey))
                                            .frame(maxWidth: .infinity)
                                    }
                                    .disabled(!action.isEnabled)
                                    .accessibilityLabel(Text(LocalizedStringKey(action.accessibilityLabelLocalizationKey)))
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                }
            }
        }
        .background(WatchLivePalette.navy.ignoresSafeArea())
    }
}

#Preview {
    WatchLiveSessionFaceView(viewModel: WatchActivityViewModel())
}

private struct WatchFallbackBannerView: View {
    let state: WatchActivityFallbackViewState
    let accentColor: Color

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: state.isBlocking ? "exclamationmark.triangle.fill" : "clock.badge.exclamationmark")
                .font(.caption.weight(.bold))
                .foregroundStyle(state.isBlocking ? WatchLivePalette.amber : accentColor)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(LocalizedStringKey(state.titleLocalizationKey))
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                Text(LocalizedStringKey(state.detailLocalizationKey))
                    .font(.caption2)
                    .foregroundStyle(WatchLivePalette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(WatchLivePalette.panel)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(WatchLivePalette.border, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(state.accessibilityIdentifier)
    }
}

private struct WatchAlwaysOnFallbackView: View {
    let viewModel: WatchActivityViewModel
    let speed: WatchLiveSpeedDisplayValue
    let accentColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("watch.fallback.alwaysOn.title")
                .font(.caption.weight(.semibold))
                .foregroundStyle(WatchLivePalette.textSecondary)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(speed.valueText)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(accentColor)
                Text(LocalizedStringKey(speed.unitLocalizationKey))
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(WatchLivePalette.textSecondary)
            }

            Text(LocalizedStringKey(WatchLiveSessionStatusLocalization.key(for: viewModel.session.state)))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)

            Text(LocalizedStringKey(alwaysOnDetailKey))
                .font(.caption2)
                .foregroundStyle(WatchLivePalette.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("watch-always-on-fallback")
    }

    private var alwaysOnDetailKey: String {
        viewModel.fallback.isVisible
            ? viewModel.fallback.detailLocalizationKey
            : "watch.fallback.alwaysOn.detail"
    }
}

private struct WatchRouteCompactCardView: View {
    let card: WatchActivityRouteCompactCardViewState
    let accentColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 6) {
                Image(systemName: "point.topleft.down.curvedto.point.bottomright.up")
                    .foregroundStyle(accentColor)
                Text("watch.compact.route.title")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                Spacer(minLength: 0)
                Text("watch.compact.route.scope.textOnly")
                    .font(.system(size: 8, weight: .heavy, design: .monospaced))
                    .foregroundStyle(WatchLivePalette.textTertiary)
                    .textCase(.uppercase)
            }

            Text(LocalizedStringKey(routeStatusKey))
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(statusColor)
                .lineLimit(2)
                .minimumScaleFactor(0.78)

            HStack(spacing: 4) {
                Text("\(card.pointCount)")
                    .monospacedDigit()
                Text("watch.compact.route.points")
                if card.segmentCount > 0 {
                    Text("·")
                    Text("\(card.segmentCount)")
                        .monospacedDigit()
                    Text("watch.compact.route.segments")
                }
            }
            .font(.system(size: 10, weight: .bold, design: .monospaced))
            .foregroundStyle(WatchLivePalette.textTertiary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(WatchLivePalette.card)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(WatchLivePalette.border, lineWidth: 1)
        )
        .accessibilityIdentifier("watch-route-compact-card")
    }

    private var routeStatusKey: String {
        switch card.status {
        case .recorded:
            return "watch.compact.route.status.recorded"
        case .qualityInsufficient:
            return "watch.compact.route.status.qualityInsufficient"
        case .unavailable:
            return "watch.compact.route.status.unavailable"
        }
    }

    private var statusColor: Color {
        switch card.status {
        case .recorded:
            return accentColor
        case .qualityInsufficient:
            return WatchLivePalette.amber
        case .unavailable:
            return WatchLivePalette.textSecondary
        }
    }
}

private struct WatchSparklineCompactCardView: View {
    let titleKey: String
    let valueText: String
    let unitKey: String
    let detailKey: String
    let points: [CompactSparklinePoint]
    let tintColor: Color
    let accessibilityIdentifier: String

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 6) {
                Text(LocalizedStringKey(titleKey))
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                Spacer(minLength: 0)
                Text(LocalizedStringKey(detailKey))
                    .font(.system(size: 8, weight: .heavy, design: .monospaced))
                    .foregroundStyle(WatchLivePalette.textTertiary)
                    .textCase(.uppercase)
            }

            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(valueText)
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(tintColor)
                Text(LocalizedStringKey(unitKey))
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(WatchLivePalette.textSecondary)
            }

            WatchCompactSparklineView(points: points, tintColor: tintColor)
                .frame(height: 28)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(WatchLivePalette.card)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(WatchLivePalette.border, lineWidth: 1)
        )
        .accessibilityIdentifier(accessibilityIdentifier)
    }
}

private struct WatchCompactSparklineView: View {
    let points: [CompactSparklinePoint]
    let tintColor: Color

    var body: some View {
        GeometryReader { proxy in
            if points.count >= 2 {
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
                .stroke(tintColor, style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round))
                .shadow(color: tintColor.opacity(0.28), radius: 4, x: 0, y: 0)
            } else {
                Capsule()
                    .fill(WatchLivePalette.panel)
                    .overlay(alignment: .leading) {
                        Capsule()
                            .fill(tintColor.opacity(0.35))
                            .frame(width: proxy.size.width * 0.28)
                    }
            }
        }
        .accessibilityHidden(true)
    }
}

private enum WatchCompactCardFormatting {
    static func speedValueText(_ value: Double?) -> String {
        guard let value, value.isFinite, value >= 0 else { return "--" }
        return String(format: "%.1f", value)
    }

    static func meterValueText(_ value: Double?) -> String {
        guard let value, value.isFinite, value >= 0 else { return "--" }
        return String(format: "%.0f", value)
    }
}

private enum WatchLivePalette {
    static let navy = Color(red: 0.051, green: 0.059, blue: 0.102)
    static let panel = Color(red: 0.102, green: 0.122, blue: 0.208)
    static let card = Color(red: 0.129, green: 0.157, blue: 0.267).opacity(0.92)
    static let accent = Color(red: 0.914, green: 0.271, blue: 0.376)
    static let purple = Color(red: 0.608, green: 0.361, blue: 0.965)
    static let teal = Color(red: 0.000, green: 0.831, blue: 0.667)
    static let amber = Color(red: 0.961, green: 0.651, blue: 0.137)
    static let textSecondary = Color(red: 0.659, green: 0.698, blue: 0.800)
    static let textTertiary = Color(red: 0.420, green: 0.478, blue: 0.600)
    static let border = Color.white.opacity(0.08)

    static func accentColor(for sportModeKey: String?) -> Color {
        sportModeKey == "inline" ? purple : accent
    }
}
