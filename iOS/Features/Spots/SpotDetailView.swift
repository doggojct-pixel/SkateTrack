// [協作區] SpotDetailView.swift
// 用途：呈現單一 Spot 詳情、編輯、刪除與收藏操作。
// 委派至：SpotsViewModel 執行資料操作。

import Foundation
import SwiftUI

struct SpotDetailView: View {
    let spot: SpotProfile
    @ObservedObject var weatherRisk: WeatherRiskViewModel
    let onBack: () -> Void
    let onToggleFavorite: () async -> Void
    let onSave: (SpotProfile) async -> Bool
    let onDelete: () async -> Void
    let onOpenHealthReminders: () -> Void

    @State private var isEditorPresented = false
    @State private var isDeleteConfirmationPresented = false

    var body: some View {
        ZStack {
            background
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    detailGrid
                    SpotRideabilityCardView(
                        spot: spot,
                        weatherRisk: weatherRisk,
                        onOpenHealthReminders: onOpenHealthReminders
                    )
                    notesSection
                    localOnlySection
                    actionsSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 72)
                .padding(.bottom, 36)
            }

            topBar
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $isEditorPresented) {
            SpotEditorView(spot: spot, onSave: onSave)
        }
        .confirmationDialog(
            "spots.delete.confirm.title",
            isPresented: $isDeleteConfirmationPresented,
            titleVisibility: .visible
        ) {
            Button("spots.delete.confirm.action", role: .destructive) {
                Task { await onDelete() }
            }
            Button("gear.detail.back", role: .cancel) {}
        } message: {
            Text("spots.delete.confirm.message")
        }
        .accessibilityIdentifier("spot-detail-view")
    }

    private var background: some View {
        ZStack {
            LinearGradient(
                colors: [
                    SkateTrackSessionStartColors.navy3,
                    SkateTrackSessionStartColors.navy2,
                    SkateTrackSessionStartColors.navy
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            RadialGradient(
                colors: [accentColor.opacity(0.28), .clear],
                center: .topTrailing,
                startRadius: 10,
                endRadius: 420
            )
        }
    }

    private var topBar: some View {
        VStack {
            HStack {
                Button(action: onBack) {
                    Label("gear.detail.back", systemImage: "chevron.left")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .background(SkateTrackSessionStartColors.card.opacity(0.82))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                Spacer()

                Button { Task { await onToggleFavorite() } } label: {
                    Image(systemName: spot.isFavorite ? "star.fill" : "star")
                        .font(.headline.weight(.black))
                        .foregroundStyle(spot.isFavorite ? SkateTrackSessionStartColors.amber : SkateTrackSessionStartColors.textSecondary)
                        .frame(width: 40, height: 40)
                        .background(SkateTrackSessionStartColors.card.opacity(0.82))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 18)
            .padding(.top, 18)
            Spacer()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("spots.detail.eyebrow")
                .tracking(2)
                .font(.caption.weight(.black))
                .foregroundStyle(accentColor)
                .textCase(.uppercase)

            titleText
                .font(.system(size: 34, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.72)

            HStack(spacing: 8) {
                badge(spot.activityFamily.localizationKey, color: accentColor)
                badge(spot.crowdLevel.localizationKey, color: SkateTrackSessionStartColors.amber)
                if spot.isFavorite {
                    badge("spots.favorite", color: SkateTrackSessionStartColors.amber)
                }
            }
        }
    }

    private var detailGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            metricCard(value: spot.surfaceRating.map { Text(LocalizedStringKey($0.localizationKey)) } ?? Text("spots.form.unset"), label: "spots.form.surface")
            metricCard(value: spot.safetyRating.map { Text(verbatim: "\($0)/5") } ?? Text("spots.form.unset"), label: "spots.safety")
            metricCard(value: Text(verbatim: "\(Int(spot.radiusMeters)) m"), label: "spots.radius")
            metricCard(value: Text(verbatim: "\(spot.visitCount)"), label: "spots.visits")
            metricCard(value: Text(verbatim: lastVisitedText), label: "spots.lastVisited")
            if let coordinate = spot.coordinate {
                metricCard(value: Text(verbatim: String(format: "%.4f", coordinate.latitude)), label: "spots.form.latitude")
                metricCard(value: Text(verbatim: String(format: "%.4f", coordinate.longitude)), label: "spots.form.longitude")
            }
        }
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("spots.form.section.notes")
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)
            notesText
                .font(.subheadline)
                .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
        }
        .spotPanel()
    }

    private var localOnlySection: some View {
        HStack(spacing: 12) {
            Image(systemName: "lock.shield.fill")
                .foregroundStyle(SkateTrackSessionStartColors.teal)
            Text("spots.private.default")
                .font(.caption.weight(.semibold))
                .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
            Spacer()
        }
        .spotPanel()
    }

    private var actionsSection: some View {
        VStack(spacing: 10) {
            Button { isEditorPresented = true } label: {
                Text("spots.edit")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(accentColor)

            Button(role: .destructive) { isDeleteConfirmationPresented = true } label: {
                Text("spots.delete")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
    }

    private var titleText: Text {
        if spot.name.isEmpty {
            return Text("spots.untitled")
        }
        return Text(verbatim: spot.name)
    }

    private var notesText: Text {
        if let notes = spot.notes, !notes.isEmpty {
            return Text(verbatim: notes)
        }
        return Text("spots.notes.empty")
    }

    private var lastVisitedText: String {
        guard let lastVisitedAt = spot.lastVisitedAt else {
            return NSLocalizedString("spots.lastVisited.never", comment: "")
        }
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.calendar = .autoupdatingCurrent
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: lastVisitedAt)
    }

    private func metricCard(value: Text, label: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            value
                .font(.headline.weight(.heavy))
                .foregroundStyle(.white)
                .lineLimit(1)
            Text(LocalizedStringKey(label))
                .font(.caption2.weight(.bold))
                .foregroundStyle(SkateTrackSessionStartColors.textTertiary)
                .textCase(.uppercase)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .spotPanel()
    }

    private func badge(_ key: String, color: Color) -> some View {
        Text(LocalizedStringKey(key))
            .font(.caption.weight(.black))
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(color.opacity(0.14))
            .clipShape(Capsule())
    }

    private var accentColor: Color {
        switch spot.activityFamily {
        case .skateboard:
            return SkateTrackSessionStartColors.accent
        case .inline:
            return SkateTrackSessionStartColors.purple
        case .mixed:
            return SkateTrackSessionStartColors.teal
        }
    }
}

private extension View {
    func spotPanel() -> some View {
        padding(14)
            .background(SkateTrackSessionStartColors.card.opacity(0.88))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(SkateTrackSessionStartColors.border, lineWidth: 1))
    }
}
