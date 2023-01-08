//
//  SceneControllerDelegates.swift
//  TicATacRToe
//
//  Created by Julio Flores on 08/01/2023.
//

import MultipeerConnectivity

protocol SceneControllerBroadcastDelegate: AnyObject {
    var session: MCSession? { get }
    func send(command: RPC, reliable: Bool)
    func sessionDidConnect()
    func sessionDidDisconnect()
}

protocol SceneControllerGameDelegate: AnyObject {
    func didPlaceActor()
    func didChangeOwner(isOwner: Bool)
}

protocol SceneControllerInterruptionDelegate: AnyObject {
    @MainActor func handleError(_ error: Error)
}

protocol SceneControllerRenderDelegate {
    @MainActor func didChangeGridStatus(isDefined: Bool)
}

