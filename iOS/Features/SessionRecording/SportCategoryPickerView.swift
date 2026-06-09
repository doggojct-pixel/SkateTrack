// [協作區] SportCategoryPickerView.swift
// 用途：顯示 Skateboard / Inline Skating 兩大運動類別切換器。
// 委派至：SessionStartView 管理後續模式與 power type 狀態。

import SwiftUI

struct SportCategoryPickerView: View {
    @Binding var selectedCategory: SessionStartSportCategory

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("session.start.selectSport")
                .tracking(2)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(SkateTrackSessionStartColors.textTertiary)
                .textCase(.uppercase)

            HStack(spacing: 10) {
                ForEach(SessionStartSportCategory.allCases) { category in
                    Button {
                        selectedCategory = category
                    } label: {
                        categoryCard(category)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("sport-category-\(category.rawValue)")
                }
            }
        }
    }

    private func categoryCard(_ category: SessionStartSportCategory) -> some View {
        let isSelected = selectedCategory == category

        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                Image(systemName: category.iconName)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(category.accentColor)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundStyle(.white)
                        .frame(width: 18, height: 18)
                        .background(category.accentColor)
                        .clipShape(Circle())
                }
            }

            Text(LocalizedStringKey(category.titleKey))
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text(LocalizedStringKey(category.subtitleKey))
                .font(.caption2.weight(.medium))
                .foregroundStyle(SkateTrackSessionStartColors.textTertiary)
        }
        .frame(maxWidth: .infinity, minHeight: 112, alignment: .topLeading)
        .padding(14)
        .background(categoryBackground(category, isSelected: isSelected))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(category.accentColor.opacity(isSelected ? 1.0 : 0.22), lineWidth: isSelected ? 2 : 1)
        )
        .shadow(color: category.accentColor.opacity(isSelected ? 0.32 : 0.0), radius: 16, x: 0, y: 0)
    }

    private func categoryBackground(_ category: SessionStartSportCategory, isSelected: Bool) -> LinearGradient {
        let baseOpacity = isSelected ? 0.28 : 0.10

        return LinearGradient(
            colors: [
                SkateTrackSessionStartColors.navy3,
                category.accentColor.opacity(baseOpacity)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

#Preview("Category Picker") {
    SportCategoryPickerView(selectedCategory: .constant(.skateboard))
        .padding()
        .background(SkateTrackSessionStartColors.navy2)
        .preferredColorScheme(.dark)
}
