// [協作區] Shared/Protocols/SensorProvider.swift
// 用途：定義跨 iOS 與 watchOS 感測資料提供者的最小介面。
// 委派至：後續 SensorEngine、Watch session coordination 與 session recording hooks。

import Combine
import Foundation

protocol SensorProvider: AnyObject {
    var motionSamplePublisher: AnyPublisher<MotionSample, Never> { get }

    func startRecording(mode: SportMode, powerType: PowerType, fidelityProfile: ActivityFidelityProfile?) async throws
    func stopRecording() async -> SessionData
}
