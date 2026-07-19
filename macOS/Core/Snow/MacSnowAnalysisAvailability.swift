// [協作區] MacSnowAnalysisAvailability.swift
// 用途：定義 macOS Snow viewer 的資料可用狀態與來源，不寫入 package schema 或 repository。
// 委派至：MacSnowAnalysisViewModel、MacSnow viewer UI、Snow-Task-008 package adapter。

import Foundation

enum MacSnowAnalysisSource: String, Sendable, Equatable {
    case debugMock
    case coreDataRepository
    case importedPackage
}

enum MacSnowAnalysisAvailability: Sendable, Equatable {
    case available(MacSnowSessionAnalysis)
    case packageSchemaPending
    case unavailable(reason: String)

    var analysis: MacSnowSessionAnalysis? {
        guard case let .available(analysis) = self else { return nil }
        return analysis
    }

    var isPackageSchemaPending: Bool {
        if case .packageSchemaPending = self { return true }
        return false
    }
}
