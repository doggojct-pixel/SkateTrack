// [協作區] SessionSummaryShareStubView.swift
// 用途：呈現 Task-018b 的分享入口 stub，避免在正式 share card 任務前假裝已完成輸出功能。
// 委派至：後續 Social / Share Card 任務實作真正分享卡、圖片輸出與系統分享流程。

import SwiftUI

struct SessionSummaryShareStubView: View {
    @State private var isStubAlertPresented = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "square.and.arrow.up.fill")
                    .font(.system(size: 17, weight: .black))
                    .foregroundStyle(SkateTrackSessionStartColors.purple)
                    .frame(width: 36, height: 36)
                    .background(SkateTrackSessionStartColors.purple.opacity(0.14))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 5) {
                    Text("summary.share.title")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundStyle(.white)

                    Text("summary.share.subtitle")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            Button {
                isStubAlertPresented = true
            } label: {
                Text("summary.share.button")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(SkateTrackSessionStartColors.purple.opacity(0.72))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(SkateTrackSessionStartColors.card.opacity(0.74))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(SkateTrackSessionStartColors.border.opacity(0.8), lineWidth: 1))
        .alert("summary.share.stub.alert.title", isPresented: $isStubAlertPresented) {
            Button("summary.share.stub.alert.dismiss", role: .cancel) {}
        } message: {
            Text("summary.share.stub.alert.message")
        }
        .accessibilityIdentifier("session-summary-share-stub")
    }
}
