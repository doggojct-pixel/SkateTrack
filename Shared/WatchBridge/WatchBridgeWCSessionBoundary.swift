// [協作區] Shared/WatchBridge/WatchBridgeWCSessionBoundary.swift

import Foundation

#if canImport(WatchConnectivity) && (os(iOS) || os(watchOS))
import WatchConnectivity

public final class WatchBridgeWCSessionBoundary: NSObject, WatchBridgeConnectivityBoundary, WCSessionDelegate {
    private let session: WCSession
    private let encoder: JSONEncoder
    private let inboundDecoder: WatchBridgeInboundEnvelopeDecoder
    private var connectionStore: WatchBridgeConnectionStateStore
    private var latestAvailability: WatchBridgeConnectivityAvailability

    public var inboundEnvelopeHandler: ((WatchBridgeEnvelope) -> Void)?
    public var malformedEnvelopeHandler: ((Data, Error) -> Void)?

    public init?(
        session: WCSession? = nil,
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder(),
        reportedAt: Date = Date()
    ) {
        guard WCSession.isSupported() else {
            return nil
        }
        self.session = session ?? .default
        self.encoder = encoder
        self.inboundDecoder = WatchBridgeInboundEnvelopeDecoder(decoder: decoder)
        self.connectionStore = WatchBridgeConnectionStateStore(
            initialState: WatchBridgeConnectionState(
                status: .unknown,
                quality: .unknown,
                lastUpdatedAt: reportedAt,
                explanation: "WCSession boundary created but not activated"
            )
        )
        self.latestAvailability = WatchBridgeConnectivityAvailability(
            state: connectionStore.state,
            runtimeSupported: true,
            runtimeActivated: false,
            paired: nil,
            reachable: false,
            reportedAt: reportedAt,
            explanation: "WCSession boundary created but not activated"
        )
        super.init()
        self.session.delegate = self
    }

    public var availability: WatchBridgeConnectivityAvailability {
        latestAvailability
    }

    @discardableResult
    public func activate(at date: Date = Date()) -> WatchBridgeConnectivityAvailability {
        session.delegate = self
        session.activate()
        return refreshAvailability(at: date)
    }

    @discardableResult
    public func refreshAvailability(at date: Date = Date()) -> WatchBridgeConnectivityAvailability {
        latestAvailability = makeAvailability(at: date, explanation: nil)
        return latestAvailability
    }

    @discardableResult
    public func send(_ envelope: WatchBridgeEnvelope) -> WatchBridgeConnectivitySendResult {
        guard availability.runtimeActivated, availability.reachable else {
            return .rejected(
                messageId: envelope.messageId,
                reason: availability.explanation ?? "WCSession boundary is not reachable"
            )
        }

        do {
            let data = try encoder.encode(envelope)
            session.sendMessageData(data, replyHandler: nil) { [weak self] error in
                _ = self?.markBoundaryUnavailable(reason: error.localizedDescription)
            }
            return .queued(messageId: envelope.messageId)
        } catch {
            return .rejected(messageId: envelope.messageId, reason: error.localizedDescription)
        }
    }

    public func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        _ = refreshAvailability(
            at: Date(),
            activationState: activationState,
            errorDescription: error?.localizedDescription
        )
    }

    public func sessionReachabilityDidChange(_ session: WCSession) {
        _ = refreshAvailability(at: Date())
    }

    public func session(_ session: WCSession, didReceiveMessageData messageData: Data) {
        _ = handleReceivedMessageData(messageData, receivedAt: Date())
    }

    @discardableResult
    public func handleReceivedMessageData(_ messageData: Data, receivedAt: Date = Date()) -> Bool {
        connectionStore.apply(
            .messageReceived(
                at: receivedAt,
                endpoint: .appleWatch,
                explanation: "WCSession boundary received envelope data"
            )
        )
        latestAvailability = makeAvailability(at: receivedAt, explanation: "received envelope data")

        do {
            let envelope = try inboundDecoder.decode(messageData)
            inboundEnvelopeHandler?(envelope)
            return true
        } catch {
            malformedEnvelopeHandler?(messageData, error)
            return false
        }
    }

    #if os(iOS)
    public func sessionDidBecomeInactive(_ session: WCSession) {
        _ = markBoundaryUnavailable(reason: "WCSession became inactive")
    }

    public func sessionDidDeactivate(_ session: WCSession) {
        _ = markBoundaryUnavailable(reason: "WCSession deactivated")
        session.activate()
    }
    #endif

    @discardableResult
    private func refreshAvailability(
        at date: Date,
        activationState: WCSessionActivationState,
        errorDescription: String?
    ) -> WatchBridgeConnectivityAvailability {
        latestAvailability = makeAvailability(
            at: date,
            activationState: activationState,
            explanation: errorDescription
        )
        return latestAvailability
    }

    @discardableResult
    private func markBoundaryUnavailable(reason: String) -> WatchBridgeConnectivityAvailability {
        connectionStore.apply(
            .unavailable(at: Date(), endpoint: .appleWatch, explanation: reason)
        )
        latestAvailability = WatchBridgeConnectivityAvailability(
            state: connectionStore.state,
            runtimeSupported: true,
            runtimeActivated: false,
            paired: platformPairedState,
            reachable: false,
            reportedAt: Date(),
            explanation: reason
        )
        return latestAvailability
    }

    private func makeAvailability(
        at date: Date,
        activationState: WCSessionActivationState? = nil,
        explanation: String?
    ) -> WatchBridgeConnectivityAvailability {
        let resolvedActivationState = activationState ?? session.activationState
        let activated = resolvedActivationState == .activated
        let reachable = activated && session.isReachable
        let event: WatchBridgeConnectionTimelineEvent

        if !activated {
            event = .unavailable(
                at: date,
                endpoint: .appleWatch,
                explanation: explanation ?? "WCSession is not activated"
            )
        } else if reachable {
            event = .connected(
                at: date,
                endpoint: .appleWatch,
                explanation: explanation ?? "WCSession is activated and reachable"
            )
        } else {
            event = .disconnected(
                at: date,
                endpoint: .appleWatch,
                explanation: explanation ?? "WCSession is activated but not reachable"
            )
        }

        connectionStore.apply(event)
        return WatchBridgeConnectivityAvailability(
            state: connectionStore.state,
            runtimeSupported: true,
            runtimeActivated: activated,
            paired: platformPairedState,
            reachable: reachable,
            reportedAt: date,
            explanation: connectionStore.state.explanation
        )
    }

    private var platformPairedState: Bool? {
        #if os(iOS)
        return session.isPaired
        #else
        return nil
        #endif
    }
}

#else

public typealias WatchBridgeWCSessionBoundary = WatchBridgeSimulatorFallbackBoundary

#endif
