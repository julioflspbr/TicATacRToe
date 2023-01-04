//
//  BroadcastController.swift
//  TicATacRToe
//
//  Created by Júlio César Flores on 28/12/2022.
//

import MultipeerConnectivity

protocol BroadcastControllerAlertDelegate: AnyObject {
    @MainActor func showAlert(title: String, description: String, actions: [InterruptingAlert.Action])
    @MainActor func handleError(_ error: Error)
}

protocol BroadcastControllerInformationDelegate: AnyObject {
    @MainActor var availablePlayers: Set<String> { get set }
    @MainActor func reset()
}

protocol BroadcastControllerGameDelegate: AnyObject {
    var isLobbySetUp: Bool { get set }
    func receive(command: RPC)
    func didConnect(isHost: Bool)
    func didDisconnect(isExpected: Bool, recover: (@escaping () -> Void))
}

final class BroadcastController: NSObject, ObservableObject {
    private static let serviceType = "tic-a-tac-r-toe"

    weak var alertDelegate: BroadcastControllerAlertDelegate?
    weak var gameDelegate: BroadcastControllerGameDelegate?
    weak var informationDelegate: BroadcastControllerInformationDelegate?

    private(set) var availablePlayers = [String : MCPeerID]() {
        didSet {
            Task { @MainActor in
                self.informationDelegate?.availablePlayers = Set(self.availablePlayers.keys)
            }
        }
    }

    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?
    private var connectionDebouncer: Task<Void, Never>?
    private var isDisconnectionExpected = false
    private var isHost = true
    private var session: MCSession?

    private var connectionState = MCSessionState.notConnected {
        didSet {
            if self.myPeerID != nil && self.opponent != nil && self.connectionState == .connected {
                self.gameDelegate?.isLobbySetUp = true
            } else {
                self.gameDelegate?.isLobbySetUp = false
            }
        }
    }
    private var myPeerID: MCPeerID? {
        didSet {
            if self.myPeerID != oldValue {
                self.broadcast()
            }
        }
    }
    var opponent: MCPeerID?

    private func broadcast() {
        self.advertiser?.stopAdvertisingPeer()
        self.browser?.stopBrowsingForPeers()
        self.session?.disconnect()

        guard let myPeerID else {
            self.advertiser = nil
            self.browser = nil
            self.session = nil

            return
        }

        let session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .none)
        session.delegate = self

        let browser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: Self.serviceType)
        browser.delegate = self
        browser.startBrowsingForPeers()

        let advertiser = MCNearbyServiceAdvertiser(peer: myPeerID, discoveryInfo: nil, serviceType: Self.serviceType)
        advertiser.delegate = self
        advertiser.startAdvertisingPeer()

        self.session = session
        self.browser = browser
        self.advertiser = advertiser
        self.isHost = true
    }

    private func finishDiscovery() {
        self.availablePlayers.removeAll()
        self.advertiser?.stopAdvertisingPeer()
        self.browser?.stopBrowsingForPeers()

        self.advertiser = nil
        self.browser = nil
    }

    private func handleError(_ error: Swift.Error) {
        Task { @MainActor in
            self.alertDelegate?.handleError(error)
        }
    }

    private func handleInvitation(from opponent: MCPeerID) async -> Bool {
        guard let alertDelegate else {
            return false
        }

        return await withCheckedContinuation { continuation in
            Task { @MainActor in
                alertDelegate.showAlert(
                    title: "Invitation",
                    description: "\(opponent.displayName) wants to play with you",
                    actions: [
                        InterruptingAlert.Action(title: "No, thanks") {
                            continuation.resume(returning: false)
                        },
                        InterruptingAlert.Action(title: "Play match") {
                            continuation.resume(returning: true)
                        }
                    ]
                )
            }
        }
    }

    private func receive(command: RPC) {
        if case .matchEnded = command {
            self.isDisconnectionExpected = true
            self.session?.disconnect()
        }
    }

    private func reset() {
        self.browser?.stopBrowsingForPeers(); self.browser = nil
        self.advertiser?.stopAdvertisingPeer(); self.advertiser = nil
        self.session?.disconnect(); self.session = nil
        self.availablePlayers = [String : MCPeerID]()
        self.connectionState = MCSessionState.notConnected
        self.isDisconnectionExpected = false
        self.isHost = true
        self.opponent = nil
        Task { @MainActor in
            self.informationDelegate?.reset()
        }
    }
}

extension BroadcastController: GameControllerBroadcastDelegate {
    var playerName: String {
        self.myPeerID?.displayName ?? ""
    }

    var opponentName: String {
        self.opponent?.displayName ?? ""
    }

    func disconnect() {
        self.isDisconnectionExpected = true
        self.send(command: .matchEnded, reliable: true)
    }

    func send(command: RPC, reliable: Bool) {
        do {
            guard let session, let opponent else {
                return
            }

            let encoder = JSONEncoder()
            let encoded = try encoder.encode(command)
            try session.send(encoded, toPeers: [opponent], with: reliable ? .reliable : .unreliable)
        } catch {
            Task { @MainActor in
                self.alertDelegate?.handleError(error)
            }
        }
    }
}

extension BroadcastController: InformationControllerBroadcastDelegate {
    func setNickname(_ name: String) {
        guard name != self.myPeerID?.displayName else {
            return
        }

        self.connectionDebouncer?.cancel()
        self.connectionDebouncer = Task { [weak self] in
            do {
                try await Task.sleep(nanoseconds: 500 * NSEC_PER_MSEC)
                try Task.checkCancellation()
            } catch {
                return
            }

            if name.count > 3 {
                self?.myPeerID = MCPeerID(displayName: name)
            } else {
                self?.myPeerID = nil
            }

            self?.broadcast()
            self?.connectionDebouncer = nil
        }
    }

    func setOpponent(_ name: String) throws {
        self.opponent = self.availablePlayers[name]
        if let opponent, let session {
            self.browser?.invitePeer(opponent, to: session, withContext: nil, timeout: 30.0)
        }
    }
}

extension BroadcastController: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        guard peerID.displayName != self.myPeerID?.displayName else {
            return
        }
        self.availablePlayers[peerID.displayName] = peerID
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        self.availablePlayers.removeValue(forKey: peerID.displayName)
        if self.opponent == peerID {
            self.opponent = nil
        }
    }

    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Swift.Error) {
        self.handleError(error)
    }
}

extension BroadcastController: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        guard let session else {
            invitationHandler(false, nil)
            return
        }
        guard self.opponent == nil else {
            invitationHandler(false, session)
            return
        }

        Task {
            if await self.handleInvitation(from: peerID) {
                invitationHandler(true, session)
                self.isHost = false
            } else {
                invitationHandler(false, session)
                self.opponent = nil
                self.isHost = true
            }
        }
    }

    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Swift.Error) {
        self.handleError(error)
    }
}

extension BroadcastController: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        if state == .connected {
            self.opponent = peerID
            self.finishDiscovery()
            self.gameDelegate?.didConnect(isHost: self.isHost)
        } else if state == .notConnected {
            self.gameDelegate?.didDisconnect(isExpected: self.isDisconnectionExpected, recover: self.broadcast)
            self.reset()
        }
        self.connectionState = state
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        guard peerID == self.opponent else {
            return
        }

        do {
            let decoder = JSONDecoder()
            let command = try decoder.decode(RPC.self, from: data)
            self.receive(command: command)
            self.gameDelegate?.receive(command: command)
        } catch {
            self.handleError(error)
        }
    }

    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        // we don't care
    }

    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        // we don't care
    }

    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Swift.Error?) {
        // we don't care
    }
}
