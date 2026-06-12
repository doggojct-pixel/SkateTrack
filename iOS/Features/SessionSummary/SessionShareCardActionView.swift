// [協作區] SessionShareCardActionView.swift
// 用途：呈現 Task-023a 的分享卡下一步入口；真正圖片輸出與系統分享保留給 Task-023b。
// 委派至：Task-023b Quick Export / Share Sheet integration。

import SwiftUI

struct SessionShareCardActionView: View {
    @State private var isPreviewOnlyAlertPresented = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "square.and.arrow.up.on.square.fill")
                    .font(.system(size: 15, weight: .black))
                    .foregroundStyle(SkateTrackSessionStartColors.purple)
                    .frame(width: 34, height: 34)
                    .background(SkateTrackSessionStartColors.purple.opacity(0.16))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text("summary.share.action.title")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundStyle(.white)

                    Text("summary.share.action.subtitle")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            Button {
                isPreviewOnlyAlertPresented = true
            } label: {
                Text("summary.share.action.button")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(SkateTrackSessionStartColors.purple.opacity(0.72))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(Color.white.opacity(0.045))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .alert("summary.share.action.alert.title", isPresented: $isPreviewOnlyAlertPresented) {
            Button("summary.share.action.alert.dismiss", role: .cancel) {}
        } message: {
            Text("summary.share.action.alert.message")
        }
        .accessibilityIdentifier("session-share-card-action-view")
    }
}
