#!/usr/bin/env python3
"""Verify Task-018a/018b/018c Session Summary, route, safety, share, and advanced chart contracts."""

from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]

REQUIRED_FILES = [
    "iOS/Features/SessionSummary/SessionSummaryView.swift",
    "iOS/Features/SessionSummary/SessionSummaryMetricsGridView.swift",
    "iOS/Features/SessionSummary/SessionSummaryPlaceholderSectionView.swift",
    "iOS/Features/SessionSummary/SessionEquipmentAttributionView.swift",
    "iOS/Features/SessionSummary/SessionRouteMapView.swift",
    "iOS/Features/SessionSummary/SessionSummarySafetyStatusView.swift",
    "iOS/Features/SessionSummary/SessionSummaryShareStubView.swift",
    "iOS/Features/SessionSummary/SessionShareCardPreviewView.swift",
    "iOS/Features/SessionSummary/SessionShareCardMetricView.swift",
    "iOS/Features/SessionSummary/SessionShareCardLockedView.swift",
    "iOS/Features/SessionSummary/SessionShareCardActionView.swift",
    "iOS/Features/SessionSummary/SessionShareCardRenderer.swift",
    "iOS/Features/SessionSummary/SessionShareExportViewModel.swift",
    "iOS/Features/SessionSummary/SessionShareSheetView.swift",
    "iOS/Core/SessionSharing/SessionShareExportPayload.swift",
    "iOS/Core/SessionSharing/SessionShareExportService.swift",
    "iOS/Features/SessionSummary/SessionAdvancedChartsView.swift",
    "iOS/Features/SessionSummary/SpeedTimelineChartView.swift",
    "iOS/Features/SessionSummary/ElevationProfileChartView.swift",
    "iOS/Features/SessionSummary/AdvancedChartsLockedView.swift",
    "iOS/Features/SessionSummary/HeartRateZonePlaceholderView.swift",
    "iOS/Hooks/useSessionSummary.swift",
    "iOS/Hooks/useSessionShareCard.swift",
    "Shared/Models/SessionShareCardData.swift",
]

LOCALIZATION_KEYS = [
    "summary.title",
    "summary.subtitle",
    "summary.loading",
    "summary.error.title",
    "summary.error.generic",
    "summary.retry",
    "summary.close",
    "summary.metric.distance",
    "summary.metric.duration",
    "summary.metric.maxSpeed",
    "summary.metric.avgSpeed",
    "summary.metric.elevationGain",
    "summary.metric.movingRatio",
    "summary.metric.falls",
    "summary.metric.tricks",
    "summary.gear.title",
    "summary.gear.detailFormat",
    "summary.gear.archived.badge",
    "summary.gear.unsynced.title",
    "summary.route.preview.title",
    "summary.route.preview.subtitle",
    "summary.route.map.title",
    "summary.route.map.subtitle",
    "summary.route.empty.title",
    "summary.route.empty.subtitle",
    "summary.route.empty.detail",
    "summary.route.start",
    "summary.route.finish",
    "summary.route.sampleCountFormat",
    "summary.safety.clear.title",
    "summary.safety.clear.subtitle",
    "summary.safety.falls.title",
    "summary.safety.falls.subtitleFormat",
    "summary.safety.metric.falls",
    "summary.safety.metric.impact",
    "summary.safety.metric.confirmed",
    "summary.safety.impactFormat",
    "summary.share.title",
    "summary.share.subtitle",
    "summary.share.button",
    "summary.share.stub.alert.title",
    "summary.share.stub.alert.message",
    "summary.share.stub.alert.dismiss",
    "summary.share.card.eyebrow",
    "summary.share.brand",
    "summary.share.footer",
    "summary.share.unlocked.subtitle",
    "summary.share.locked.sectionSubtitle",
    "summary.share.locked.title",
    "summary.share.locked.subtitle",
    "summary.share.spot",
    "summary.share.spot.none",
    "summary.share.equipment",
    "summary.share.equipment.none",
    "summary.share.route",
    "summary.share.route.available",
    "summary.share.route.unavailable",
    "summary.share.safety",
    "summary.share.safety.clear",
    "summary.share.safety.fallsFormat",
    "summary.share.action.title",
    "summary.share.action.subtitle",
    "summary.share.action.button",
    "summary.share.export.preparing",
    "summary.share.export.error.title",
    "summary.share.export.error.image",
    "summary.share.export.error.file",
    "summary.share.export.error.generic",
    "summary.share.export.error.dismiss",
    "summary.share.export.text.title",
    "summary.share.export.text.footer",
    "summary.charts.placeholder.title",
    "summary.charts.placeholder.subtitle",
    "summary.health.placeholder.title",
    "summary.health.placeholder.subtitle",
    "summary.advancedCharts.title",
    "summary.advancedCharts.unlocked.subtitle",
    "summary.advancedCharts.locked.subtitle",
    "summary.advancedCharts.speed.title",
    "summary.advancedCharts.speed.subtitle",
    "summary.advancedCharts.speed.empty",
    "summary.advancedCharts.speed.empty.title",
    "summary.advancedCharts.speed.empty.detail",
    "summary.advancedCharts.elevation.title",
    "summary.advancedCharts.elevation.subtitle",
    "summary.advancedCharts.elevation.empty",
    "summary.advancedCharts.elevation.empty.title",
    "summary.advancedCharts.elevation.empty.detail",
    "summary.advancedCharts.axis.time",
    "summary.advancedCharts.axis.speed",
    "summary.advancedCharts.axis.elevation",
    "summary.advancedCharts.locked.preview.speed",
    "summary.advancedCharts.locked.preview.elevation",
    "summary.advancedCharts.heartRate.title",
    "summary.advancedCharts.heartRate.subtitle",
    "summary.advancedCharts.heartRate.noFakeData",
    "subscription.pro_badge",
]

PROJECT_TOKENS = [
    "SessionSummaryView.swift in Sources",
    "SessionSummaryMetricsGridView.swift in Sources",
    "SessionSummaryPlaceholderSectionView.swift in Sources",
    "SessionEquipmentAttributionView.swift in Sources",
    "SessionRouteMapView.swift in Sources",
    "SessionSummarySafetyStatusView.swift in Sources",
    "SessionSummaryShareStubView.swift in Sources",
    "SessionShareCardData.swift in Sources",
    "useSessionShareCard.swift in Sources",
    "SessionShareCardPreviewView.swift in Sources",
    "SessionShareCardMetricView.swift in Sources",
    "SessionShareCardLockedView.swift in Sources",
    "SessionShareCardActionView.swift in Sources",
    "SessionShareCardRenderer.swift in Sources",
    "SessionShareExportViewModel.swift in Sources",
    "SessionShareSheetView.swift in Sources",
    "SessionShareExportPayload.swift in Sources",
    "SessionShareExportService.swift in Sources",
    "useSessionSummary.swift in Sources",
    "SessionAdvancedChartsView.swift in Sources",
    "SpeedTimelineChartView.swift in Sources",
    "ElevationProfileChartView.swift in Sources",
    "AdvancedChartsLockedView.swift in Sources",
    "HeartRateZonePlaceholderView.swift in Sources",
    "iOS/Features/SessionSummary",
]

SOURCE_TOKENS = {
    "iOS/Hooks/useSessionSummary.swift": [
        "SessionSummaryViewModel",
        "SessionRepositoryProtocol",
        "fetchSession(id:",
        "loadMotionSamples(for:",
        "SessionSummaryContent",
        "SessionSummaryViewState",
    ],
    "iOS/Features/SessionSummary/SessionSummaryView.swift": [
        "SessionSummaryView",
        "useSessionSummary(sessionID:",
        "SessionSummaryMetricsGridView",
        "SessionEquipmentAttributionView",
        "SessionRouteMapView",
        "SessionRouteMapView(session: content.session, samples: content.motionSamples)",
        "SessionSummarySafetyStatusView",
        "SessionSummaryShareStubView",
        "lockedFeature: .sessionShareCard",
        "isShareCardPaywallPresented",
        "SessionAdvancedChartsView",
        "SubscriptionPaywallView",
        "lockedFeature: .advancedCharts",
        "refreshable",
        "safeAreaInset(edge: .bottom",
        "session-summary-floating-close",
    ],
    "iOS/Features/SessionSummary/SessionSummaryMetricsGridView.swift": [
        "SessionSummaryMetricItem",
        "session-summary-metrics-grid",
    ],
    "iOS/Features/SessionSummary/SessionSummaryPlaceholderSectionView.swift": [
        "SessionSummaryPlaceholderSectionView",
        "session-summary-placeholder-section",
    ],
    "iOS/Features/SessionSummary/SessionEquipmentAttributionView.swift": [
        "SessionEquipmentAttributionView",
        "summary.gear.title",
        "summary.gear.detailFormat",
        "session-equipment-attribution",
    ],
    "iOS/Features/SessionSummary/SessionRouteMapView.swift": [
        "import MapKit",
        "MapPolyline",
        "Annotation",
        "rawRouteCoordinates",
        "displayRoutePoints",
        "displayRouteSegments",
        "RouteMapSegmentStyle",
        "reliableDisplayRouteCoordinates",
        "routeAccuracyDisclosureText",
        "session-route-accuracy-disclosure",
        "segment.style.opacity",
        "private static let fluorescentPink",
        "makeDisplayRoutePoints",
        "deduplicatedTrustedLocationFixes",
        "isTrustedDisplayRouteSample",
        "shouldSuppressSmallAreaJitter",
        "smoothDisplayCoordinate",
        "shouldStartNewRouteSegment",
        "session-route-map-view",
        "session-route-map-empty",
    ],
    "iOS/Features/SessionSummary/SessionSummarySafetyStatusView.swift": [
        "SessionSummarySafetyStatusView",
        "FallEvent",
        "session-summary-safety-status",
    ],
    "Shared/Models/SessionShareCardData.swift": [
        "SessionShareCardData",
        "SessionShareCardMetricData",
        "SessionShareCardAccent",
    ],
    "iOS/Hooks/useSessionShareCard.swift": [
        "SessionShareCardViewModel",
        "useSessionShareCard(content:",
        "routeStatusLocalizationKey",
    ],
    "iOS/Features/SessionSummary/SessionSummaryShareStubView.swift": [
        "SessionSummaryShareStubView",
        "subscriptionStatus.hasAccess(to: .sessionShareCard)",
        "SessionShareCardPreviewView",
        "SessionShareCardLockedView",
        "session-summary-share-card-section",
    ],
    "iOS/Features/SessionSummary/SessionShareCardPreviewView.swift": [
        "SessionShareCardPreviewView",
        "SessionShareCardMetricView",
        "summary.share.card.eyebrow",
        "session-share-card-preview",
    ],
    "iOS/Features/SessionSummary/SessionShareCardLockedView.swift": [
        "SessionShareCardLockedView",
        "LockedFeatureOverlayView",
        "feature: .sessionShareCard",
    ],
    "iOS/Features/SessionSummary/SessionShareCardActionView.swift": [
        "SessionShareCardActionView",
        "SessionShareExportViewModel",
        "summary.share.export.preparing",
    ],

    "iOS/Features/SessionSummary/SessionAdvancedChartsView.swift": [
        "SessionAdvancedChartsView",
        "SessionSummaryChartPoint",
        "downsample",
        "subscriptionStatus.hasAccess(to: .advancedCharts)",
        "AdvancedChartsLockedView",
        "SpeedTimelineChartView",
        "ElevationProfileChartView",
        "HeartRateZonePlaceholderView",
    ],
    "iOS/Features/SessionSummary/SpeedTimelineChartView.swift": [
        "import Charts",
        "SessionSummaryChartSegment",
        "LineMark",
        "series: .value",
        "summary-speed-timeline-chart",
    ],
    "iOS/Features/SessionSummary/ElevationProfileChartView.swift": [
        "import Charts",
        "SessionSummaryChartSegment",
        "LineMark",
        "series: .value",
        "summary-elevation-profile-chart",
    ],
    "iOS/Features/SessionSummary/AdvancedChartsLockedView.swift": [
        "AdvancedChartsLockedView",
        "LockedFeatureOverlayView",
        "feature: .advancedCharts",
        "advanced-charts-locked-view",
    ],
    "iOS/Features/SessionSummary/HeartRateZonePlaceholderView.swift": [
        "HeartRateZonePlaceholderView",
        "ChartCard",
        "ChartEmptyState",
        "heart-rate-zone-placeholder-view",
    ],
    "iOS/Features/SessionHistory/SessionHistoryView.swift": [
        "SessionSummaryView(",
        "selectedSummarySession",
    ],
    "docs/history/DEV_LOG.md": [
        "Task-020c",
        "Task-018c Advanced Charts + Subscription Gating",
        "SpeedTimelineChartView",
        "GatedFeature.advancedCharts",
    ],
    "docs/reference/FILE_STRUCTURE.md": [
        "Task-020c",
        "Task-018c Advanced Charts + Subscription Gating",
        "SessionAdvancedChartsView.swift",
        "SpeedTimelineChartView.swift",
        "verify_session_summary.py",
        "Task-023a",
        "SessionShareCardPreviewView.swift",
    ],
}

FORBIDDEN_TOKENS = [
    "AppStore.sync()",
    "Transaction.currentEntitlements",
    "Product.products(for:",
    "HKHealthStore",
    "calories",
    "PHPhotoLibrary",
]

MAX_LINES = {
    "iOS/Features/SessionSummary/SessionSummaryView.swift": 360,
    "iOS/Features/SessionSummary/SessionSummaryMetricsGridView.swift": 180,
    "iOS/Features/SessionSummary/SessionSummaryPlaceholderSectionView.swift": 160,
    "iOS/Features/SessionSummary/SessionRouteMapView.swift": 760,
    "iOS/Features/SessionSummary/SessionSummarySafetyStatusView.swift": 220,
    "iOS/Features/SessionSummary/SessionSummaryShareStubView.swift": 180,
    "iOS/Features/SessionSummary/SessionShareCardPreviewView.swift": 240,
    "iOS/Features/SessionSummary/SessionShareCardMetricView.swift": 120,
    "iOS/Features/SessionSummary/SessionShareCardLockedView.swift": 140,
    "iOS/Features/SessionSummary/SessionShareCardActionView.swift": 180,
    "iOS/Features/SessionSummary/SessionShareCardRenderer.swift": 120,
    "iOS/Features/SessionSummary/SessionShareExportViewModel.swift": 140,
    "iOS/Features/SessionSummary/SessionShareSheetView.swift": 100,
    "iOS/Core/SessionSharing/SessionShareExportPayload.swift": 120,
    "iOS/Core/SessionSharing/SessionShareExportService.swift": 220,
    "iOS/Features/SessionSummary/SessionAdvancedChartsView.swift": 340,
    "iOS/Features/SessionSummary/SpeedTimelineChartView.swift": 180,
    "iOS/Features/SessionSummary/ElevationProfileChartView.swift": 180,
    "iOS/Features/SessionSummary/AdvancedChartsLockedView.swift": 220,
    "iOS/Features/SessionSummary/HeartRateZonePlaceholderView.swift": 240,
    "iOS/Hooks/useSessionSummary.swift": 420,
    "iOS/Hooks/useSessionShareCard.swift": 220,
    "Shared/Models/SessionShareCardData.swift": 160,
}


def fail(message: str) -> None:
    print(f"❌ {message}")
    sys.exit(1)


def read(relative: str) -> str:
    path = ROOT / relative
    if not path.exists():
        fail(f"Missing required file: {relative}")
    return path.read_text(encoding="utf-8")


def verify_files() -> None:
    for relative in REQUIRED_FILES:
        if not (ROOT / relative).exists():
            fail(f"Missing required file: {relative}")


def verify_line_counts() -> None:
    for relative, limit in MAX_LINES.items():
        count = len(read(relative).splitlines())
        if count > limit:
            fail(f"{relative} has {count} lines; limit is {limit}")


def verify_project_membership() -> None:
    project = read("SkateTrack.xcodeproj/project.pbxproj")
    for token in PROJECT_TOKENS:
        if token not in project:
            fail(f"Project file missing membership token: {token}")

    for filename in [Path(item).name for item in REQUIRED_FILES]:
        file_refs = len(re.findall(rf"/\* {re.escape(filename)} \*/ = {{isa = PBXFileReference;", project))
        build_files = len(re.findall(rf"/\* {re.escape(filename)} in Sources \*/ = {{isa = PBXBuildFile;", project))
        sources = len(re.findall(rf"/\* {re.escape(filename)} in Sources \*/,", project))
        if file_refs < 1:
            fail(f"Missing PBXFileReference for {filename}")
        if build_files < 1:
            fail(f"Missing PBXBuildFile for {filename}")
        if sources < 1:
            fail(f"Missing PBXSourcesBuildPhase entry for {filename}")


def verify_localization() -> None:
    for locale in ["en", "zh-Hant"]:
        text = read(f"Shared/Localization/{locale}.lproj/Localizable.strings")
        for key in LOCALIZATION_KEYS:
            if f'"{key}"' not in text:
                fail(f"Missing localization key {key} in {locale}")

    expected_elevation_gain_labels = {
        "en": "Total elevation gain",
        "zh-Hant": "總爬升量",
        "ja": "総獲得標高",
    }
    for locale, label in expected_elevation_gain_labels.items():
        token = f'"summary.metric.elevationGain" = "{label}";'
        if token not in read(f"Shared/Localization/{locale}.lproj/Localizable.strings"):
            fail(f"Task-030c-b15-B-3 missing total elevation gain label for {locale}: {label}")


def verify_source_contracts() -> None:
    for relative, tokens in SOURCE_TOKENS.items():
        text = read(relative)
        for token in tokens:
            if token not in text:
                fail(f"{relative} missing token: {token}")

    combined = "\n".join(read(relative) for relative in REQUIRED_FILES)
    for token in FORBIDDEN_TOKENS:
        if token in combined:
            fail(f"Task-018a must not add deferred feature token: {token}")

    summary_view = read("iOS/Features/SessionSummary/SessionSummaryView.swift")
    if "No fake health metrics are shown" in summary_view:
        fail("User-facing copy must stay in Localizable.strings, not raw Swift strings")

    chart_sources = "\n".join(
        read(path)
        for path in [
            "iOS/Features/SessionSummary/SpeedTimelineChartView.swift",
            "iOS/Features/SessionSummary/ElevationProfileChartView.swift",
        ]
    )
    if "AreaMark" in chart_sources:
        fail("Task-030c-b3 charts must not use area fills across long GPS gaps")


def main() -> None:
    verify_files()
    verify_line_counts()
    verify_project_membership()
    verify_localization()
    verify_source_contracts()
    print("✅ Task-023b Session Summary share/export verification passed")


if __name__ == "__main__":
    main()
