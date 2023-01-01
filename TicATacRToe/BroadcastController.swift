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

protocol BroadcastControllerGameDelegate: AnyObject {
    var isGameSetUp: Bool { get set }
    func receiveCommand(_ command: RPC)
}

final class BroadcastController: NSObject, ObservableObject {
    private static let serviceType = "tic-a-tac-r-toe"

    weak var alertDelegate: BroadcastControllerAlertDelegate?
    weak var gameDelegate: BroadcastControllerGameDelegate?

    @Published var nickname = "" {
        didSet {
            if self.nickname != oldValue {
                self.broadcast()
            }
        }
    }
    @Published var opponent: MCPeerID? {
        didSet {
            if let session, let opponent {
                self.browser?.invitePeer(opponent, to: session, withContext: nil, timeout: 30.0)
            }
        }
    }

    @Published private(set) var availablePlayers = [String : MCPeerID]()
    @Published private(set) var connectionState = MCSessionState.notConnected {
        didSet {
            self.gameDelegate?.isGameSetUp = (self.connectionState == .connected && self.opponent != nil && self.nickname.count >= 3)
        }
    }

    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?
    private var connectionDebouncer: Task<Void, Never>?
    private var peerID: MCPeerID?
    private var session: MCSession?

    func send(command: RPC, mode: MCSessionSendDataMode = .reliable) {
        do {
            guard let session, let opponent else {
                return
            }

            let encoder = JSONEncoder()
            let encoded = try encoder.encode(command)
            try session.send(encoded, toPeers: [opponent], with: mode)
        } catch {
            Task { @MainActor in
                self.alertDelegate?.handleError(error)
            }
        }
    }

    private func broadcast() {
        self.connectionDebouncer?.cancel()
        self.connectionDebouncer = Task { [weak self] in
            do {
                try await Task.sleep(nanoseconds: 500 * NSEC_PER_MSEC)
                try Task.checkCancellation()
            } catch {
                return
            }

            guard let self else {
                return
            }

            self.advertiser?.stopAdvertisingPeer()
            self.browser?.stopBrowsingForPeers()
            self.session?.disconnect()

            guard self.nickname.count >= 3 else {
                self.advertiser = nil
                self.browser = nil
                self.session = nil
                self.peerID = nil

                return
            }

            let peerID = MCPeerID(displayName: self.nickname)

            let session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .none)
            session.delegate = self

            let browser = MCNearbyServiceBrowser(peer: peerID, serviceType: Self.serviceType)
            browser.delegate = self
            browser.startBrowsingForPeers()

            let advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: Self.serviceType)
            advertiser.delegate = self
            advertiser.startAdvertisingPeer()

            self.peerID = peerID
            self.session = session
            self.browser = browser
            self.advertiser = advertiser
            self.connectionDebouncer = nil
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

    private func finishDiscovery() {
        self.advertiser?.stopAdvertisingPeer()
        self.browser?.stopBrowsingForPeers()

        self.advertiser = nil
        self.browser = nil

        Task { @MainActor in
            self.availablePlayers.removeAll()
        }
    }
}

extension BroadcastController: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        guard peerID.displayName != self.peerID?.displayName else {
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

    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        Task { @MainActor in
            self.alertDelegate?.handleError(error)
        }
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

        Task { @MainActor in
            if await self.handleInvitation(from: peerID) {
                invitationHandler(true, session)
            } else {
                invitationHandler(false, session)
                self.opponent = nil
            }
        }
    }

    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        Task { @MainActor in
            self.alertDelegate?.handleError(error)
        }
    }
}

extension BroadcastController: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        Task { @MainActor in
            self.opponent = (state == .connected ? peerID : nil)
            self.connectionState = state
        }

        if state == .connected {
            self.finishDiscovery()
        } else if state == .notConnected && (self.advertiser == nil || self.browser == nil) {
            self.broadcast()
        }
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        guard peerID == self.opponent else {
            return
        }

        do {
            let decoder = JSONDecoder()
            let command = try decoder.decode(RPC.self, from: data)
            self.gameDelegate?.receiveCommand(command)
        } catch {
            Task { @MainActor in
                self.alertDelegate?.handleError(error)
            }
        }
    }

    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        // we don't care
    }

    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        // we don't care
    }

    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        // we don't care
    }
}
