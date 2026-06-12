// [協作區 — 邊界適配層] useSessionShareCard.swift
// 用途：將 SessionSummaryContent 轉成分享卡預覽資料，避免 Summary View 直接格式化分享文案。
// 委派至：SessionShareCardData 作為可重用資料模型；Task-023b 才接圖片輸出與系統分享。

import Foundation

struct SessionShareCardViewModel: Equatable {
    let card: SessionShareCardData
    let hasRoutePreview: Bool
    let hasSpotAttribution: Bool
    let hasEquipmentAttribution: Bool
}

func useSessionShareCard(content: SessionSummaryContent) -> SessionShareCardViewModel {
    let session = content.session
    let metrics = content.metrics
    let distance = distanceText(metrics)
    let duration = durationText(session)
    let maxSpeed = speedText(metrics.maxSpeedKilometersPerHour)
    let averageSpeed = speedText(metrics.averageSpeedKilometersPerHour)
    let elevation = elevationText(metrics.elevationGainMeters)
    let movingRatio = percentText(metrics.movingRatio)
    let fallCount = "\(content.fallCount)"
    let trickCount = "\(content.trickCount)"

    let cardMetrics = [
        SessionShareCardMetricData(
            id: "distance",
            labelLocalizationKey: "summary.metric.distance",
            value: distance,
            systemImageName: "point.topleft.down.curvedto.point.bottomright.up",
            accentName: .teal
        ),
        SessionShareCardMetricData(
            id: "duration",
            labelLocalizationKey: "summary.metric.duration",
            value: duration,
            systemImageName: "timer",
            accentName: .white
        ),
        SessionShareCardMetricData(
            id: "maxSpeed",
            labelLocalizationKey: "summary.metric.maxSpeed",
            value: maxSpeed,
            systemImageName: "speedometer",
            accentName: .purple
        ),
        SessionShareCardMetricData(
            id: "avgSpeed",
            labelLocalizationKey: "summary.metric.avgSpeed",
            value: averageSpeed,
            systemImageName: "gauge.with.dots.needle.bottom.50percent",
            accentName: .white
        ),
        SessionShareCardMetricData(
            id: "elevation",
            labelLocalizationKey: "summary.metric.elevationGain",
            value: elevation,
            systemImageName: "mountain.2.fill",
            accentName: .amber
        ),
        SessionShareCardMetricData(
            id: "moving",
            labelLocalizationKey: "summary.metric.movingRatio",
            value: movingRatio,
            systemImageName: "figure.roll",
            accentName: .teal
        )
    ]

    let card = SessionShareCardData(
        id: session.id,
        sportModeLocalizationKey: session.sportMode.modeLocalizationKey,
        powerTypeLocalizationKey: session.powerType.localizationKey,
        dateLine: dateLine(for: session),
        durationText: duration,
        distanceText: distance,
        maxSpeedText: maxSpeed,
        averageSpeedText: averageSpeed,
        elevationText: elevation,
        movingRatioText: movingRatio,
        fallCountText: fallCount,
        trickCountText: trickCount,
        routeStatusLocalizationKey: content.hasRouteSamples ? "summary.share.route.available" : "summary.share.route.unavailable",
        safetyStatusText: safetyStatusText(fallCount: content.fallCount),
        spotName: session.spotSnapshot?.displayName,
        equipmentName: session.equipmentSnapshot?.displayName,
        metrics: cardMetrics
    )

    return SessionShareCardViewModel(
        card: card,
        hasRoutePreview: content.hasRouteSamples,
        hasSpotAttribution: session.spotSnapshot != nil,
        hasEquipmentAttribution: session.equipmentSnapshot != nil
    )
}

private func dateLine(for session: SessionData) -> String {
    let formatter = DateFormatter()
    formatter.locale = .autoupdatingCurrent
    formatter.calendar = .autoupdatingCurrent
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter.string(from: session.startDate)
}

private func distanceText(_ metrics: SessionSummaryMetrics) -> String {
    UnitFormatter.distance(meters: metrics.distanceKilometers * 1_000, maximumFractionDigits: 2)
}

private func durationText(_ session: SessionData) -> String {
    guard let duration = session.durationSeconds else { return unavailableText() }
    let formatter = DateComponentsFormatter()
    formatter.allowedUnits = duration >= 3_600 ? [.hour, .minute] : [.minute, .second]
    formatter.unitsStyle = .abbreviated
    return formatter.string(from: duration) ?? unavailableText()
}

private func speedText(_ value: Double) -> String {
    guard value.isFinite else { return unavailableText() }
    let format = NSLocalizedString("unit.speed.kmh.valueFormat", comment: "")
    let unit = NSLocalizedString("unit.speed.kmh.short", comment: "")
    return String(format: format, locale: .autoupdatingCurrent, value, unit)
}

private func elevationText(_ meters: Double) -> String {
    guard meters.isFinite else { return unavailableText() }
    let format = NSLocalizedString("unit.length.meter.valueFormat", comment: "")
    return String(format: format, locale: .autoupdatingCurrent, meters)
}

private func percentText(_ value: Double) -> String {
    guard value.isFinite else { return unavailableText() }
    return String(format: "%.0f%%", min(max(value, 0), 1) * 100)
}

private func safetyStatusText(fallCount: Int) -> String {
    if fallCount == 0 {
        return NSLocalizedString("summary.share.safety.clear", comment: "")
    }
    let format = NSLocalizedString("summary.share.safety.fallsFormat", comment: "")
    return String(format: format, locale: .autoupdatingCurrent, fallCount)
}

private func unavailableText() -> String {
    NSLocalizedString("general.value.unavailable", comment: "")
}
