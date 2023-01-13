//
//  SceneControllerDelegates.swift
//  TicATacRToe
//
//  Created by Julio Flores on 08/01/2023.
//

import MultipeerConnectivity

protocol SceneControllerBroadcastDelegate: AnyObject {
    var session: MCSession? { get }
    func disconnect()
    func send(command: RPC, reliable: Bool)
    func sessionDidConnect()
    func sessionDidDisconnect()
}

protocol SceneControllerGameDelegate: AnyObject {
    var myAvatar: Actor.Avatar { get }
    var myColour: Actor.Colour { get }
    func didPlaceActor(at: Place.Position, isMyTurn: Bool)
}

protocol SceneControllerInterruptionDelegate: AnyObject {
    @MainActor func handleError(_ error: Error)
}

protocol SceneControllerRenderDelegate {
    @MainActor func didChangeGridStatus(isDefined: Bool)
}

