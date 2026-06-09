// [協作區] AppConstants.swift
// 用途：集中管理 SkateTrack 全域常數，避免魔法數字與散落設定。
// 委派至：後續 Task 可依功能將專屬常數拆分到更小的 Constants 檔案。

import Foundation

enum AppConstants {
    static let productInternalName = "SkateTrack"
    static let bundleIdentifierPrefix = "com.jjf.skatetrack"
    static let minimumSupportedIOSVersion = "17.0"
    static let minimumSupportedWatchOSVersion = "10.0"
    static let minimumSupportedMacOSVersion = "14.0"
}
