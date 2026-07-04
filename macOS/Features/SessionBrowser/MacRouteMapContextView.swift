// [協作區] macOS/Features/SessionBrowser/MacRouteMapContextView.swift
// 用途：在 macOS Session Viewer 中以 read-only MapKit 背景呈現既有 .skatetrack 路線樣本脈絡。
// 委派至：MacRoutePreviewView；只讀顯示現有 route samples，不請求定位、不 map-match、不 snap-to-road、不修改路線或 trusted metrics。

import AppKit
import MapKit
import SwiftUI

struct MacRouteMapContextView: NSViewRepresentable {
    let points: [MacRoutePoint]
    let summary: MacRouteSummary

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> MKMapView {
        let mapView = MKMapView(frame: .zero)
        mapView.delegate = context.coordinator
        mapView.mapType = .standard
        mapView.showsUserLocation = false
        mapView.translatesAutoresizingMaskIntoConstraints = false
        return mapView
    }

    func updateNSView(_ mapView: MKMapView, context: Context) {
        context.coordinator.configure(mapView: mapView, points: points, summary: summary)
    }

    final class Coordinator: NSObject, MKMapViewDelegate {
        private var lastRouteSignature: String?
        private var routeOverlayStyles: [ObjectIdentifier: MacRouteVisualStyle] = [:]

        func configure(mapView: MKMapView, points: [MacRoutePoint], summary: MacRouteSummary) {
            let signature = routeSignature(points: points, summary: summary)
            guard signature != lastRouteSignature else { return }
            lastRouteSignature = signature

            mapView.removeOverlays(mapView.overlays)
            mapView.removeAnnotations(mapView.annotations)
            routeOverlayStyles.removeAll()
            guard points.count >= 2, summary.quality != .unavailable else { return }

            // Segment styles map to MacRouteVisualStyle.fluorescentPinkGlow / brightOrangeAccent / trustedGreenRoute.
            let segments = makeRouteSegments(from: points)
            guard !segments.isEmpty else { return }

            var unionRect: MKMapRect?
            for segment in segments {
                let polyline = addRouteOverlay(coordinates: segment.coordinates, style: segment.style.visualStyle, to: mapView)
                unionRect = unionRect.map { $0.union(polyline.boundingMapRect) } ?? polyline.boundingMapRect
            }

            let displayCoordinates = points.map { CLLocationCoordinate2D(latitude: $0.displayCoordinate.latitude, longitude: $0.displayCoordinate.longitude) }
            mapView.addAnnotations(endpointAnnotations(for: displayCoordinates))
            if let unionRect {
                mapView.setVisibleMapRect(
                    expandedMapRect(unionRect),
                    edgePadding: NSEdgeInsets(top: 34, left: 34, bottom: 34, right: 34),
                    animated: false
                )
            }
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            guard let polyline = overlay as? MKPolyline else { return MKOverlayRenderer(overlay: overlay) }
            let style = routeOverlayStyles[ObjectIdentifier(polyline)] ?? .trustedGreenRoute
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = style.appKitColor
            renderer.lineWidth = style.lineWidth
            renderer.alpha = style.opacity
            renderer.lineJoin = .round
            renderer.lineCap = .round
            return renderer
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let endpoint = annotation as? MacRouteEndpointAnnotation else { return nil }
            let reuseID = endpoint.role.reuseIdentifier
            let view = mapView.dequeueReusableAnnotationView(withIdentifier: reuseID) as? MKMarkerAnnotationView
                ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: reuseID)
            view.annotation = annotation
            view.canShowCallout = true
            view.markerTintColor = endpoint.role.markerTintColor
            view.glyphTintColor = .white
            return view
        }

        private func makeRouteSegments(from points: [MacRoutePoint]) -> [MacRouteRenderedSegment] {
            var segments: [MacRouteRenderedSegment] = []
            var currentCoordinates: [CLLocationCoordinate2D] = []
            var currentStyle: MacRouteSegmentStyle?
            var segmentID = 0
            var previousPoint: MacRoutePoint?

            for point in points.sorted(by: { $0.timestamp < $1.timestamp }) {
                let pointStyle = point.segmentStyle
                if let previousPoint, shouldStartNewRouteSegment(after: previousPoint, current: point) {
                    appendSegmentIfNeeded(currentCoordinates, style: currentStyle ?? .trusted, id: segmentID, to: &segments)
                    currentCoordinates = []
                    currentStyle = pointStyle
                    segmentID += 1
                } else if let previousPoint, let existingStyle = currentStyle, existingStyle != pointStyle {
                    appendSegmentIfNeeded(currentCoordinates, style: existingStyle, id: segmentID, to: &segments)
                    currentCoordinates = pointStyle == .trusted ? [] : [coordinate(from: previousPoint.displayCoordinate)]
                    currentStyle = pointStyle
                    segmentID += 1
                } else if currentStyle == nil {
                    currentStyle = pointStyle
                }

                currentCoordinates.append(coordinate(from: point.displayCoordinate))
                previousPoint = point
            }

            appendSegmentIfNeeded(currentCoordinates, style: currentStyle ?? .trusted, id: segmentID, to: &segments)
            return segments
        }

        private func shouldStartNewRouteSegment(after previousPoint: MacRoutePoint, current point: MacRoutePoint) -> Bool {
            if point.timestamp.timeIntervalSince(previousPoint.timestamp) > 12 { return true }
            let rawDistance = distanceMetersBetween(previousPoint.rawCoordinate, point.rawCoordinate)
            let displayDistance = distanceMetersBetween(previousPoint.displayCoordinate, point.displayCoordinate)
            return rawDistance > 55 && displayDistance > 40
        }

        private func appendSegmentIfNeeded(
            _ coordinates: [CLLocationCoordinate2D],
            style: MacRouteSegmentStyle,
            id: Int,
            to segments: inout [MacRouteRenderedSegment]
        ) {
            guard coordinates.count >= 2 else { return }
            segments.append(MacRouteRenderedSegment(id: id, coordinates: coordinates, style: style))
        }

        @discardableResult
        private func addRouteOverlay(coordinates: [CLLocationCoordinate2D], style: MacRouteVisualStyle, to mapView: MKMapView) -> MKPolyline {
            let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
            routeOverlayStyles[ObjectIdentifier(polyline)] = style
            mapView.addOverlay(polyline, level: .aboveRoads)
            return polyline
        }

        private func endpointAnnotations(for coordinates: [CLLocationCoordinate2D]) -> [MacRouteEndpointAnnotation] {
            guard let first = coordinates.first, let last = coordinates.last else { return [] }
            return [
                MacRouteEndpointAnnotation(coordinate: first, role: .start, title: String(localized: "mac.viewer.route.preview.start")),
                MacRouteEndpointAnnotation(coordinate: last, role: .finish, title: String(localized: "mac.viewer.route.preview.finish")),
            ]
        }

        private func coordinate(from value: GeoCoordinate) -> CLLocationCoordinate2D {
            CLLocationCoordinate2D(latitude: value.latitude, longitude: value.longitude)
        }

        private func expandedMapRect(_ rect: MKMapRect) -> MKMapRect {
            guard !rect.isNull, rect.width.isFinite, rect.height.isFinite else { return rect }
            let width = max(rect.width, 360)
            let height = max(rect.height, 360)
            let dx = max(width * 0.12, 80)
            let dy = max(height * 0.12, 80)
            return rect.insetBy(dx: -dx, dy: -dy)
        }

        private func routeSignature(points: [MacRoutePoint], summary: MacRouteSummary) -> String {
            let first = points.first?.displayCoordinate
            let last = points.last?.displayCoordinate
            return [
                "count=\(points.count)",
                "route=\(summary.routePointCount)",
                "unique=\(summary.uniqueRoutePointCount)",
                "warmup=\(summary.hasStartupWarmup)",
                coordinateSignature(first),
                coordinateSignature(last),
            ].joined(separator: "|")
        }

        private func coordinateSignature(_ coordinate: GeoCoordinate?) -> String {
            guard let coordinate else { return "none" }
            return String(format: "%.6f,%.6f", coordinate.latitude, coordinate.longitude)
        }

        private func distanceMetersBetween(_ first: GeoCoordinate, _ second: GeoCoordinate) -> Double {
            let earthRadiusMeters = 6_371_000.0
            let latitude1 = first.latitude * .pi / 180
            let latitude2 = second.latitude * .pi / 180
            let deltaLatitude = (second.latitude - first.latitude) * .pi / 180
            let deltaLongitude = (second.longitude - first.longitude) * .pi / 180
            let a = sin(deltaLatitude / 2) * sin(deltaLatitude / 2)
                + cos(latitude1) * cos(latitude2) * sin(deltaLongitude / 2) * sin(deltaLongitude / 2)
            let c = 2 * atan2(sqrt(a), sqrt(1 - a))
            return earthRadiusMeters * c
        }
    }
}

private struct MacRouteRenderedSegment: Identifiable {
    let id: Int
    let coordinates: [CLLocationCoordinate2D]
    let style: MacRouteSegmentStyle
}

private final class MacRouteEndpointAnnotation: NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D
    let role: MacRouteEndpointRole
    let title: String?

    init(coordinate: CLLocationCoordinate2D, role: MacRouteEndpointRole, title: String) {
        self.coordinate = coordinate
        self.role = role
        self.title = title
    }
}

private enum MacRouteEndpointRole {
    case start
    case finish

    var reuseIdentifier: String {
        switch self {
        case .start:
            return "mac-route-start-annotation"
        case .finish:
            return "mac-route-finish-annotation"
        }
    }

    var markerTintColor: NSColor {
        switch self {
        case .start:
            return MacRouteVisualStyle.startMarker.appKitColor
        case .finish:
            return MacRouteVisualStyle.finishMarker.appKitColor
        }
    }
}
