// [Collaboration Zone] WatchSnowMockGalleryView.swift
// Purpose: DEBUG-only mock-backed watchOS Snow UI gallery. Real WatchBridge wiring is deferred to Snow-Task-006b.

#if DEBUG
import SwiftUI

struct WatchSnowMockGalleryView: View {
    @StateObject private var dataSource = WatchSnowMockSessionProvider()
    @State private var selectedScenario: WatchSnowMockScenario = .downhill

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                header
                scenarioSelector
                stateContent
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 10)
        }
        .watchSnowBackground()
    }

    private var header: some View {
        VStack(spacing: 4) {
            Text("snow.watch.root.eyebrow")
                .font(.system(size: 9, weight: .heavy, design: .monospaced))
                .foregroundStyle(WatchSnowPalette.ice)
            Text("snow.watch.root.title")
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundStyle(WatchSnowPalette.snow)
            Text("snow.watch.root.mockOnly")
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(WatchSnowPalette.text2)
                .multilineTextAlignment(.center)
        }
        .watchSnowCard(cornerRadius: 18)
    }

    private var scenarioSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(WatchSnowMockScenario.allCases) { scenario in
                    Button {
                        selectedScenario = scenario
                        dataSource.selectScenario(scenario)
                    } label: {
                        Text(LocalizedStringKey(scenario.titleKey))
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .foregroundStyle(selectedScenario == scenario ? WatchSnowPalette.navy : WatchSnowPalette.ice)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(
                                Capsule().fill(selectedScenario == scenario ? WatchSnowPalette.ice : WatchSnowPalette.ice.opacity(0.12))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 2)
        }
    }

    @ViewBuilder
    private var stateContent: some View {
        let snapshot = dataSource.currentSnapshot

        if snapshot.fallAlertActive {
            WatchSnowFallAlertView(snapshot: snapshot)
        } else {
            WatchSnowLiveView(snapshot: snapshot)
            WatchSnowCarouselView(snapshot: snapshot)

            switch selectedScenario {
            case .liftOrGondola:
                WatchSnowLiftCardView(snapshot: snapshot)
            case .waiting:
                WatchSnowWaitingCardView(snapshot: snapshot)
            case .summary:
                WatchSnowSummaryView(snapshot: snapshot)
            case .lowConfidence:
                WatchSnowLowConfidenceView(snapshot: snapshot)
            case .downhill, .fallAlert:
                EmptyView()
            }
        }

        WatchSnowControlView(
            snapshot: snapshot,
            lastHapticIntent: dataSource.lastHapticIntent,
            markManeuver: dataSource.markManeuver,
            startRun: dataSource.startRun,
            pauseSession: dataSource.pauseSession,
            resumeSession: dataSource.resumeSession,
            endRun: dataSource.endRun,
            toggleSubscriberGate: dataSource.toggleSubscriberGate
        )
    }
}
#endif
