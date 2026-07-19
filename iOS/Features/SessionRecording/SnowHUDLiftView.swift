// [協作區] SnowHUDLiftView.swift
// 用途：呈現 lift / gondola / surface lift transport 狀態，明確標示不計入 ski distance。

import SwiftUI

struct SnowHUDLiftView: View {
    let model: SnowLiftHUDModel
    let accentColor: Color

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 14) {
                Image(systemName: iconName)
                    .font(.system(size: 34, weight: .heavy))
                    .foregroundStyle(SkateTrackSessionStartColors.amber)
                    .frame(width: 62, height: 62)
                    .background(SkateTrackSessionStartColors.amber.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 22))

                VStack(alignment: .leading, spacing: 5) {
                    Text(LocalizedStringKey(model.segmentType.localizationKey))
                        .font(.system(size: 21, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                    Text(LocalizedStringKey(model.messageLocalizationKey))
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            .padding(18)
            .background(SkateTrackSessionStartColors.card.opacity(0.86))
            .clipShape(RoundedRectangle(cornerRadius: 26))
            .overlay(RoundedRectangle(cornerRadius: 26).stroke(SkateTrackSessionStartColors.amber.opacity(0.24), lineWidth: 1))

            HStack(spacing: 10) {
                SnowHUDMetricTile(
                    value: SnowHUDView.formatSpeed(model.currentSpeedKmh),
                    labelKey: "session.hud.currentSpeed",
                    tintColor: accentColor,
                    accessibilityID: "snow-hud-lift-current-speed"
                )
                SnowHUDMetricTile(
                    value: SnowHUDView.formatMeters(model.liftDistanceMeters),
                    labelKey: "snow.hud.liftDistanceMeters",
                    tintColor: SkateTrackSessionStartColors.amber,
                    accessibilityID: "snow-hud-lift-distance"
                )
                SnowHUDMetricTile(
                    value: SnowHUDView.formatMeters(model.routeDistanceMeters),
                    labelKey: "snow.hud.routeDistanceMeters",
                    tintColor: SkateTrackSessionStartColors.blueCold,
                    accessibilityID: "snow-hud-route-distance"
                )
            }
        }
        .accessibilityIdentifier("snow-hud-lift")
    }

    private var iconName: String {
        switch model.segmentType {
        case .gondolaAscent:
            return "cablecar.fill"
        case .surfaceLiftAscent:
            return "arrow.up.forward.circle.fill"
        default:
            return "figure.skiing.crosscountry"
        }
    }
}
