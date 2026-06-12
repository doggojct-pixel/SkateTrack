// [自主區] SessionRecordingCoordinator+CompletionEffects.swift
// 用途：隔離 completed session 保存成功後的副作用，避免核心 coordinator 檔案過長。
// 委派至：SessionRecordingCoordinator.requestEndSession()；只在 SessionRepository save 成功後呼叫。

import Foundation

extension SessionRecordingCoordinator {
    func applyEquipmentMileageIfNeeded(for session: SessionData) async {
        do {
            _ = try await equipmentMileageTracker.applyMileageIfNeeded(to: session)
        } catch let error as RepositoryError {
            publishError(error.localizationKey)
        } catch {
            publishError("gear.error.mileageTrackingFailed")
        }
    }

    func applySpotVisitIfNeeded(for session: SessionData) async {
        do {
            _ = try await spotVisitTracker.applyVisitIfNeeded(to: session)
        } catch let error as RepositoryError {
            publishError(error.localizationKey)
        } catch {
            publishError("spots.error.visitTrackingFailed")
        }
    }
}
