// [自主區] iOS/Core/Safety/SOSEventDispatcher.swift
// 用途：封裝 Phase 1a SOS 事件建立與未來電話 / 訊息 / 推播通道替換點。
// 委派至：useFallDetection、EmergencyContactStore、Task-015 persistence。

import Combine
import Foundation

final class SOSEventDispatcher {
    static let shared = SOSEventDispatcher()

    private let eventSubject = PassthroughSubject<SOSTriggerEvent, Never>()
    private let contactStore: EmergencyContactStore
    private(set) var dispatchedEvents: [SOSTriggerEvent] = []

    init(contactStore: EmergencyContactStore = .shared) {
        self.contactStore = contactStore
    }

    var eventPublisher: AnyPublisher<SOSTriggerEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }

    @discardableResult
    func dispatch(
        source: SOSTriggerSource,
        fallEvent: FallEvent?,
        locationCoordinate: GeoCoordinate?,
        sportMode: SportMode?
    ) -> SOSTriggerEvent {
        let resolvedLocation = locationCoordinate ?? fallEvent?.locationCoordinate
        let resolvedSportMode = sportMode ?? fallEvent?.sportMode
        let contacts = contactStore.usableContacts
        let status: SOSDispatchStatus = contacts.isEmpty ? .contactSetupRequired : .readyForUserAction
        let event = SOSTriggerEvent(
            source: source,
            dispatchStatus: status,
            relatedFallEvent: fallEvent,
            locationCoordinate: resolvedLocation,
            sportMode: resolvedSportMode,
            emergencyContacts: contacts,
            messagePreview: makeMessagePreview(locationCoordinate: resolvedLocation),
            userActionHintLocalizationKey: contacts.isEmpty ? "sos.event.needsContacts" : "sos.event.ready"
        )

        dispatchedEvents.append(event)
        eventSubject.send(event)
        return event
    }

    private func makeMessagePreview(locationCoordinate: GeoCoordinate?) -> String {
        var message = "I may have fallen while skating and need help."
        if let coordinate = locationCoordinate {
            let location = String(format: "https://maps.apple.com/?ll=%.6f,%.6f", coordinate.latitude, coordinate.longitude)
            message += " Location: \(location)"
        } else {
            message += " Location unavailable."
        }
        return message
    }
}
