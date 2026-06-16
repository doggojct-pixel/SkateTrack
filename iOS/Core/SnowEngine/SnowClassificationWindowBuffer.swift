// [協作區] iOS/Core/SnowEngine/SnowClassificationWindowBuffer.swift
// 用途：保留 SnowSegmentClassifier 所需的 rolling MotionSample window。
// 委派至：SnowLiveSessionCoordinator。

import Foundation

struct SnowClassificationWindowBuffer: Sendable, Equatable {
    private(set) var samples: [MotionSample] = []

    mutating func append(_ sample: MotionSample) {
        samples.append(sample)
        samples.sort { $0.timestamp < $1.timestamp }
    }

    mutating func trim(keepingLast seconds: TimeInterval) {
        guard seconds > 0, let latestDate = samples.last?.timestamp else { return }
        let cutoff = latestDate.addingTimeInterval(-seconds)
        samples.removeAll { $0.timestamp < cutoff }
    }

    mutating func reset() {
        samples.removeAll(keepingCapacity: true)
    }
}
