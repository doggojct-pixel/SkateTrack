// [協作區] iOS/Features/Debug/DebugToolsPanelView.swift
// 用途：集中呈現 DEBUG-only 工具入口，統一管理跌倒警示、Demo Speed、訂閱與測試資料。
// 委派至：useFallDetection、useSessionRecording、useSubscriptionStatus 與 EmergencyContactStore。

#if DEBUG
import SwiftUI

struct DebugToolsPanelView: View {
    @ObservedObject var subscriptionStatus: SubscriptionStatusViewModel
    @ObservedObject var sessionRecording: SessionRecordingViewModel
    @ObservedObject var fallDetection: FallDetectionViewModel
    @ObservedObject var emergencyContactStore: EmergencyContactStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                SkateTrackSessionStartColors.navy.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        header
                        sessionRuntimeSection
                        recordingDiagnosticsContextSection
                        fallAlertSection
                        subscriptionSection
                        safetyDataSection
                        SessionRecordingPreviewPanel(sessionRecording: sessionRecording)
                        debugBuildSignatureCard
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 22)
                    .padding(.bottom, 28)
                }
            }
            .navigationTitle(Text("debug.tools.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("general.done") { dismiss() }
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(SkateTrackSessionStartColors.teal)
                }
            }
        }
        .preferredColorScheme(.dark)
        .accessibilityIdentifier("debug-tools-panel")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("debug.tools.headline")
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundStyle(.white)
            Text("debug.tools.description")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
                .lineSpacing(4)
        }
    }

    private var sessionRuntimeSection: some View {
        debugCard(flag: .demoSpeedSession) {
            Toggle(
                "debug.tools.demoSpeed.toggle",
                isOn: Binding(
                    get: { sessionRecording.debugDemoSpeedSessionEnabled },
                    set: { DebugMockSessionFactory.setDemoSpeedSessionEnabled($0, on: sessionRecording) }
                )
            )
            .font(.system(size: 14, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .tint(SkateTrackSessionStartColors.amber)
            .disabled(sessionRecording.state.status != .idle)
            .accessibilityIdentifier(DebugToolAction.enableDemoSpeedSession.accessibilityIdentifier)

            Text(sessionRecording.state.status == .idle ? "debug.tools.demoSpeed.idleHint" : "debug.tools.demoSpeed.activeHint")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(SkateTrackSessionStartColors.textTertiary)
        }
    }


    private var recordingDiagnosticsContextSection: some View {
        debugCard(flag: .recordingDiagnosticsContext) {
            VStack(alignment: .leading, spacing: 10) {
                Picker(
                    "debug.tools.recordingContext.picker",
                    selection: Binding(
                        get: { sessionRecording.debugRecordingTestContext },
                        set: { sessionRecording.setDebugRecordingTestContext($0) }
                    )
                ) {
                    ForEach(DebugRecordingTestContextLabel.allCases) { context in
                        Text(LocalizedStringKey(context.localizationKey)).tag(context)
                    }
                }
                .pickerStyle(.menu)
                .tint(SkateTrackSessionStartColors.teal)
                .disabled(sessionRecording.state.status != .idle)
                .accessibilityIdentifier("debug-recording-context-picker")

                Text(LocalizedStringKey(sessionRecording.debugRecordingTestContext.descriptionLocalizationKey))
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("debug-recording-context-description")

                HStack(spacing: 8) {
                    Image(systemName: "lock.doc.fill")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundStyle(SkateTrackSessionStartColors.amber)
                    Text("debug.tools.recordingContext.hint")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(SkateTrackSessionStartColors.textTertiary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var fallAlertSection: some View {
        debugCard(flag: .simulateFallAlert) {
            Button(action: fallDetection.actions.simulateFallAlert) {
                Label("debug.tools.simulateFall.button", systemImage: "exclamationmark.triangle.fill")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
            }
            .font(.system(size: 15, weight: .heavy, design: .rounded))
            .foregroundStyle(.white)
            .background(SkateTrackSessionStartColors.accent2.opacity(0.86))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .accessibilityIdentifier(DebugToolAction.simulateFallAlert.accessibilityIdentifier)
        }
    }

    private var subscriptionSection: some View {
        debugCard(flag: .subscriptionOverride) {
            SubscriptionDebugPanel(subscriptionStatus: subscriptionStatus)
        }
    }

    private var safetyDataSection: some View {
        debugCard(flag: .resetEmergencyContacts) {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("debug.tools.contacts.count")
                        .font(.system(size: 11, weight: .heavy, design: .monospaced))
                        .foregroundStyle(SkateTrackSessionStartColors.textTertiary)
                        .textCase(.uppercase)
                    Text("\(emergencyContactStore.contacts.count)")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundStyle(SkateTrackSessionStartColors.teal)
                }
                Spacer()
                Button(role: .destructive) {
                    emergencyContactStore.clearContacts()
                } label: {
                    Text("debug.tools.resetContacts.button")
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.borderedProminent)
                .disabled(emergencyContactStore.contacts.isEmpty)
                .accessibilityIdentifier(DebugToolAction.resetEmergencyContacts.accessibilityIdentifier)
            }
        }
    }

    private var debugBuildSignatureCard: some View {
        HStack(alignment: .center, spacing: 12) {
            ZStack {
                Circle()
                    .fill(SkateTrackSessionStartColors.teal.opacity(0.16))
                    .frame(width: 38, height: 38)
                Image(systemName: "sparkles")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(SkateTrackSessionStartColors.teal)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("debug.build.title")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundStyle(SkateTrackSessionStartColors.textTertiary)
                    .textCase(.uppercase)
                Text("Task-030c-b11-r3-3")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .tracking(0.3)
                Text("debug.build.subtitle")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            Text("DEBUG")
                .font(.system(size: 11, weight: .black, design: .monospaced))
                .foregroundStyle(SkateTrackSessionStartColors.navy)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(SkateTrackSessionStartColors.teal)
                .clipShape(Capsule())
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [
                    SkateTrackSessionStartColors.navy3.opacity(0.90),
                    SkateTrackSessionStartColors.card.opacity(0.72)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(SkateTrackSessionStartColors.teal.opacity(0.22), lineWidth: 1)
        )
        .shadow(color: SkateTrackSessionStartColors.teal.opacity(0.10), radius: 20, x: 0, y: 10)
        .accessibilityIdentifier("debug-build-signature-card")
    }


    private func debugCard<Content: View>(
        flag: DebugFeatureFlag,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text(LocalizedStringKey(flag.titleKey))
                    .font(.system(size: 13, weight: .black, design: .monospaced))
                    .foregroundStyle(.white)
                    .textCase(.uppercase)
                Text(LocalizedStringKey(flag.descriptionKey))
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SkateTrackSessionStartColors.card.opacity(0.86))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(SkateTrackSessionStartColors.border, lineWidth: 1))
    }
}

private extension DebugRecordingTestContextLabel {
    var localizationKey: String {
        switch self {
        case .unspecified:
            return "debug.recordingContext.unspecified"
        case .handheldScreenOn:
            return "debug.recordingContext.handheldScreenOn"
        case .handheldAutoLock:
            return "debug.recordingContext.handheldAutoLock"
        case .lockedPocketWalk:
            return "debug.recordingContext.lockedPocketWalk"
        case .windshieldDrive:
            return "debug.recordingContext.windshieldDrive"
        case .vehicleScreenOff:
            return "debug.recordingContext.vehicleScreenOff"
        case .electricLongboardLockedPocket:
            return "debug.recordingContext.electricLongboardLockedPocket"
        case .scooterLockedPocket:
            return "debug.recordingContext.scooterLockedPocket"
        }
    }

    var descriptionLocalizationKey: String {
        switch self {
        case .unspecified:
            return "debug.recordingContext.unspecified.description"
        case .handheldScreenOn:
            return "debug.recordingContext.handheldScreenOn.description"
        case .handheldAutoLock:
            return "debug.recordingContext.handheldAutoLock.description"
        case .lockedPocketWalk:
            return "debug.recordingContext.lockedPocketWalk.description"
        case .windshieldDrive:
            return "debug.recordingContext.windshieldDrive.description"
        case .vehicleScreenOff:
            return "debug.recordingContext.vehicleScreenOff.description"
        case .electricLongboardLockedPocket:
            return "debug.recordingContext.electricLongboardLockedPocket.description"
        case .scooterLockedPocket:
            return "debug.recordingContext.scooterLockedPocket.description"
        }
    }
}

#endif
