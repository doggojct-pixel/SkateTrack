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

        func configure(
            mapView: MKMapView,
            points: [MacRoutePoint],
            summary: MacRouteSummary
        ) {
            let coordinates = points.map { point in
                CLLocationCoordinate2D(
                    latitude: point.coordinate.latitude,
                    longitude: point.coordinate.longitude
                )
            }
            let signature = routeSignature(points: points, summary: summary)
            guard signature != lastRouteSignature else { return }
            lastRouteSignature = signature

            mapView.removeOverlays(mapView.overlays)
            mapView.removeAnnotations(mapView.annotations)
            guard coordinates.count >= 2, summary.quality != .unavailable else { return }

            let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
            mapView.addOverlay(polyline, level: .aboveRoads)
            mapView.addAnnotations(endpointAnnotations(for: coordinates))
            mapView.setVisibleMapRect(
                expandedMapRect(polyline.boundingMapRect),
                edgePadding: NSEdgeInsets(top: 34, left: 34, bottom: 34, right: 34),
                animated: false
            )
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            guard let polyline = overlay as? MKPolyline else {
                return MKOverlayRenderer(overlay: overlay)
            }
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = NSColor.systemCyan
            renderer.lineWidth = 4
            renderer.alpha = 0.92
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

        private func endpointAnnotations(for coordinates: [CLLocationCoordinate2D]) -> [MacRouteEndpointAnnotation] {
            guard let first = coordinates.first, let last = coordinates.last else { return [] }
            return [
                MacRouteEndpointAnnotation(
                    coordinate: first,
                    role: .start,
                    title: String(localized: "mac.viewer.route.preview.start")
                ),
                MacRouteEndpointAnnotation(
                    coordinate: last,
                    role: .finish,
                    title: String(localized: "mac.viewer.route.preview.finish")
                ),
            ]
        }

        private func expandedMapRect(_ rect: MKMapRect) -> MKMapRect {
            guard rect.isNull == false, rect.width.isFinite, rect.height.isFinite else { return rect }
            let width = max(rect.width, 360)
            let height = max(rect.height, 360)
            let dx = max(width * 0.12, 80)
            let dy = max(height * 0.12, 80)
            return rect.insetBy(dx: -dx, dy: -dy)
        }

        private func routeSignature(points: [MacRoutePoint], summary: MacRouteSummary) -> String {
            let first = points.first?.coordinate
            let last = points.last?.coordinate
            return [
                "count=\(points.count)",
                "route=\(summary.routePointCount)",
                "unique=\(summary.uniqueRoutePointCount)",
                coordinateSignature(first),
                coordinateSignature(last),
            ].joined(separator: "|")
        }

        private func coordinateSignature(_ coordinate: GeoCoordinate?) -> String {
            guard let coordinate else { return "none" }
            return String(format: "%.6f,%.6f", coordinate.latitude, coordinate.longitude)
        }
    }
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
            return .systemGreen
        case .finish:
            return .systemOrange
        }
    }
}
