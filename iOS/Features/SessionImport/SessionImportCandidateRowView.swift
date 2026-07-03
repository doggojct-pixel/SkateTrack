// [協作區] iOS/Features/SessionImport/SessionImportCandidateRowView.swift
// 用途：呈現單一 .skatetrack 匯入候選檔案的驗證狀態、選取狀態與提交結果。
// 委派至：SessionImportPreviewView；只顯示 ViewModel 已準備好的狀態。

import SwiftUI

struct SessionImportCandidateRowView: View {
    let candidate: SkateTrackImportCandidate
    let isSelected: Bool
    let commitResult: SkateTrackImportCommitResult?
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            VStack(alignment: .leading, spacing: 12) {
                header
                metadata
                detailText
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(SkateTrackSessionStartColors.card.opacity(0.88))
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 22).stroke(borderColor, lineWidth: isSelected ? 1.5 : 1))
        }
        .buttonStyle(.plain)
        .disabled(candidate.isImportable == false || commitResult != nil)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityIdentifier("session-import-candidate-row")
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: iconName)
                .font(.system(size: 20, weight: .black))
                .foregroundStyle(statusColor)
                .frame(width: 30, height: 30)
                .background(statusColor.opacity(0.16))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(candidate.sourceDisplayName)
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                Text(LocalizedStringKey(displayStatusKey))
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(statusColor)
            }

            Spacer()

            if candidate.isImportable && commitResult == nil {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(isSelected ? SkateTrackSessionStartColors.teal : SkateTrackSessionStartColors.textTertiary)
            }
        }
    }

    private var metadata: some View {
        HStack(spacing: 10) {
            metadataChip(value: "\(candidate.sessionCount)", labelKey: "import.preview.sessionCount")
            metadataChip(value: dateRangeText, labelKey: "import.preview.dateRange")
        }
    }

    private func metadataChip(value: String, labelKey: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
            Text(LocalizedStringKey(labelKey))
                .font(.system(size: 9, weight: .black, design: .rounded))
                .foregroundStyle(SkateTrackSessionStartColors.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color.white.opacity(0.045))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var detailText: some View {
        Text(LocalizedStringKey(displayDetailKey))
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var displayStatusKey: String {
        commitResult?.status.localizationKey ?? candidate.validationStatus.localizationKey
    }

    private var displayDetailKey: String {
        commitResult?.detailKey ?? candidate.detailLocalizationKey
    }

    private var statusColor: Color {
        if let commitResult {
            switch commitResult.status {
            case .imported:
                return SkateTrackSessionStartColors.teal
            case .skippedDuplicate:
                return SkateTrackSessionStartColors.amber
            case .failed:
                return SkateTrackSessionStartColors.accent2
            }
        }

        switch candidate.validationStatus {
        case .ready:
            return SkateTrackSessionStartColors.teal
        case .alreadyImported, .duplicateCandidate, .needsReview, .checksumMismatch:
            return SkateTrackSessionStartColors.amber
        default:
            return SkateTrackSessionStartColors.accent2
        }
    }

    private var borderColor: Color {
        isSelected ? SkateTrackSessionStartColors.teal.opacity(0.80) : SkateTrackSessionStartColors.border
    }

    private var iconName: String {
        if let commitResult {
            switch commitResult.status {
            case .imported:
                return "checkmark.circle.fill"
            case .skippedDuplicate:
                return "exclamationmark.triangle.fill"
            case .failed:
                return "xmark.octagon.fill"
            }
        }
        switch candidate.validationStatus {
        case .ready:
            return "tray.and.arrow.down.fill"
        case .alreadyImported, .duplicateCandidate, .needsReview:
            return "exclamationmark.triangle.fill"
        default:
            return "xmark.octagon.fill"
        }
    }

    private var dateRangeText: String {
        guard let start = candidate.dateRangeStart else {
            return NSLocalizedString("import.preview.value.none", comment: "")
        }
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.calendar = .autoupdatingCurrent
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        if let end = candidate.dateRangeEnd, !Calendar.autoupdatingCurrent.isDate(start, inSameDayAs: end) {
            return "\(formatter.string(from: start)) – \(formatter.string(from: end))"
        }
        return formatter.string(from: start)
    }

    private var accessibilityLabel: String {
        let format = NSLocalizedString("import.accessibility.fileRowFormat", comment: "")
        let status = NSLocalizedString(displayStatusKey, comment: "")
        return String(format: format, locale: .autoupdatingCurrent, candidate.sourceDisplayName, status)
    }
}
