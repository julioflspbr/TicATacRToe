//
//  GameController.swift
//  TicATacRToe
//
//  Created by Julio Flores on 21/12/2022.
//

import SwiftUI
import SceneKit

protocol GameControllerBroadcastDelegate: AnyObject {
    var playerName: String { get }
    var opponentName: String { get }
    func disconnect()
    func send(command: RPC, reliable: Bool)
}

protocol GameControllerInformationDelegate: AnyObject {
    @MainActor var isLobbySetUp: Bool { get set }
    @MainActor var currentAvatar: Actor.Avatar { get set }
    @MainActor var myAvatar: Actor.Avatar { get set }
    @MainActor var result: Wins { get set }
}

protocol GameControllerInterruptionDelegate: AnyObject {
    @MainActor func allow3DInteraction()
    @MainActor func deny3DInteraction()
    @MainActor func handleError(_ error: Error)
    @MainActor func showAlert(title: String, description: String, actions: [InterruptingAlert.Action])
}

protocol GameControllerSceneDelegate: AnyObject {
    @MainActor func deleteAllGrids()
    @MainActor func defineGridPosition() throws
    @MainActor func makeNewGrid()
    @MainActor func moveGrid(by: SIMD3<Float>) throws
    @MainActor func queryPlace(for: Place.Position) throws -> Place
    @MainActor func queryPlace(at: CGPoint) -> Place?
    @MainActor func strikeThrough(_: StrikeThrough.StrikeType) -> Void
}

final class GameController: ObservableObject {
    weak var broadcastDelegate: GameControllerBroadcastDelegate?
    weak var informationDelegate: GameControllerInformationDelegate?
    weak var interruptionDelegate: GameControllerInterruptionDelegate?
    weak var sceneDelegate: GameControllerSceneDelegate?

    var isLobbySetUp = false {
        didSet {
            Task { @MainActor in
                self.informationDelegate?.isLobbySetUp = self.isLobbySetUp

                if self.isLobbySetUp {
                    self.interruptionDelegate?.allow3DInteraction()
                } else {
                    self.interruptionDelegate?.deny3DInteraction()
                }
            }
        }
    }

    private(set) var currentAvatar = Actor.Avatar.cross {
        didSet {
            Task { @MainActor in
                self.informationDelegate?.currentAvatar = self.currentAvatar
            }
        }
    }
    private(set) var myAvatar = Actor.Avatar.cross {
        didSet {
            Task { @MainActor in
                self.informationDelegate?.myAvatar = self.myAvatar
            }
        }
    }
    private(set) var result = Wins() {
        didSet {
            Task { @MainActor in
                self.informationDelegate?.result = self.result
            }
        }
    }

    private var state = [Actor.Avatar.cross: Set<Place.Position>(), Actor.Avatar.circle: Set<Place.Position>()]

    func alertRejection(opponent: String, recover: (@escaping () -> Void)) {
        Task { @MainActor in
            let title = "Rejected"
            let description = "\(opponent) doesn't want to play with you"
            let okAction = InterruptingAlert.Action(title: "OK", action: recover)
            self.interruptionDelegate?.showAlert(title: title, description: description, actions: [okAction])
        }
    }

    func alertUnexpectedDisconnection(me: String, opponent: String, result: Wins, recover: (@escaping () -> Void)) {
        Task { @MainActor in
            let title = "Unexpected Disconnection"
            let description = "Result\n\(me): \(result.me)\n\(opponent): \(result.opponent)"
            let okAction = InterruptingAlert.Action(title: "OK", action: recover)
            self.interruptionDelegate?.showAlert(title: title, description: description, actions: [okAction])
        }
    }

    func handleTap(at point: CGPoint) {
        guard self.currentAvatar == self.myAvatar else {
            return
        }

        Task {
            if let placeNode = await self.queryPlace(at: point) {
                self.fill(place: placeNode)
//                self.broadcastDelegate?.send(command: .opponentPlaced(placeNode.place), reliable: true)
            }
        }
    }

    func endMatch() {
        Task { @MainActor in
            let disconnectAction = InterruptingAlert.Action(title: "Yes", role: .destructive) {
                self.broadcastDelegate?.disconnect()
            }
            let cancelAction = InterruptingAlert.Action(title: "No", role: .cancel, action: {})
            self.interruptionDelegate?.showAlert(title: "End match", description: "Are you sure?", actions: [disconnectAction, cancelAction])
        }
    }

    private func checkGameEnd() {
        guard let state = self.state[self.currentAvatar] else {
            return
        }

        let hasVictory: Bool
        if state.contains(elements: [.topLeft, .top, .topRight]) {
            self.strikeThrough(.horizontal(.top))
            hasVictory = true
        } else if state.contains(elements: [.left, .centre, .right]) {
            self.strikeThrough(.horizontal(.centre))
            hasVictory = true
        } else if state.contains(elements: [.bottomLeft, .bottom, .bottomRight]) {
            self.strikeThrough(.horizontal(.bottom))
            hasVictory = true
        } else if state.contains(elements: [.topLeft, .left, .bottomLeft]) {
            self.strikeThrough(.vertical(.left))
            hasVictory = true
        } else if state.contains(elements: [.top, .centre, .bottom]) {
            self.strikeThrough(.vertical(.centre))
            hasVictory = true
        } else if state.contains(elements: [.topRight, .right, .bottomRight]) {
            self.strikeThrough(.vertical(.right))
            hasVictory = true
        } else if state.contains(elements: [.topLeft, .centre, .bottomRight]) {
            self.strikeThrough(.diagonal(.leftTop))
            hasVictory = true
        } else if state.contains(elements: [.topRight, .centre, .bottomLeft]) {
            self.strikeThrough(.diagonal(.rightTop))
            hasVictory = true
        } else {
            hasVictory = false
        }

        if hasVictory {
            if self.currentAvatar == self.myAvatar {
                self.result.me += 1
            } else {
                self.result.opponent += 1
            }
        }

        let allPlacesFilled = 9
        let filledWithCircles = self.state[.circle]?.count ?? 0
        let filledWithCrosses = self.state[.cross]?.count ?? 0
        if hasVictory || filledWithCircles + filledWithCrosses == allPlacesFilled {
            self.state[.cross]?.removeAll()
            self.state[.circle]?.removeAll()
            self.currentAvatar = .cross
            self.myAvatar.toggle()

            Task { @MainActor in
                do {
                    self.sceneDelegate?.makeNewGrid()
                    if self.myAvatar == .cross {
                        try self.sceneDelegate?.defineGridPosition()
                    }
                } catch {
                    self.handleError(error)
                }
            }
        } else {
            self.currentAvatar.toggle()
        }
    }

    private func fill(place: Place) {
        let currentAvatar = self.currentAvatar
        Task { @MainActor in
            do {
//                try place.fill(with: currentAvatar)
            } catch {
                self.handleError(error)
            }
        }

//        self.state[currentAvatar]?.insert(place.place)
        self.checkGameEnd()
    }

    private func handleError(_ error: Swift.Error) {
        Task { @MainActor in
            self.interruptionDelegate?.handleError(error)
        }
    }

    private func moveGrid(by position: SIMD3<Float>) {
        Task { @MainActor in
            do {
                try self.sceneDelegate?.moveGrid(by: position)
            } catch {
                self.handleError(error)
            }
        }
    }

    private func place(at position: Place.Position) {
        Task {
            do {
                if let placeNode = try await self.queryPlace(for: position) {
                    self.fill(place: placeNode)
                }
            } catch {
                self.handleError(error)
            }
        }
    }

    private func queryPlace(at point: CGPoint) async -> Place? {
        await MainActor.run {
            self.sceneDelegate?.queryPlace(at: point)
        }
    }

    private func queryPlace(for position: Place.Position) async throws -> Place? {
        try await MainActor.run {
            try self.sceneDelegate?.queryPlace(for: position)
        }
    }

    private func showResults(me: String, opponent: String, result: Wins, recover: (@escaping () -> Void)) {
        Task { @MainActor in
            let title: String
            if result.me > result.opponent {
                title = "You win!"
            } else if result.me < result.opponent {
                title = "You loose!"
            } else {
                title = "It's a draw!"
            }

            let description = "\(me): \(result.me)\n\(opponent): \(result.opponent)"
            let okAction = InterruptingAlert.Action(title: "OK", action: recover)
            self.interruptionDelegate?.showAlert(title: title, description: description, actions: [okAction])
        }
    }

    private func strikeThrough(_ type: StrikeThrough.StrikeType) {
        Task { @MainActor in
            self.sceneDelegate?.strikeThrough(type)
        }
    }
}

extension GameController: BroadcastControllerGameDelegate {
    func didConnect(isHost: Bool) {
        Task { @MainActor in
            do {
                self.sceneDelegate?.makeNewGrid()

                if isHost {
                    try self.sceneDelegate?.defineGridPosition()
                } else {
                    self.myAvatar.toggle()
                }
            } catch {
                self.handleError(error)
            }
        }
    }

    func didDisconnect(isExpected: Bool, recover: (@escaping () -> Void)) {
        let me = self.broadcastDelegate?.playerName ?? ""
        let opponent = self.broadcastDelegate?.opponentName ?? ""
        if isExpected {
            self.showResults(me: me, opponent: opponent, result: self.result, recover: recover)
        } else if self.isLobbySetUp {
            self.alertUnexpectedDisconnection(me: me, opponent: opponent, result: self.result, recover: recover)
        } else {
            self.alertRejection(opponent: opponent, recover: recover)
        }

        self.isLobbySetUp = false
        self.currentAvatar = Actor.Avatar.cross
        self.myAvatar = Actor.Avatar.cross
        self.result = Wins()
        self.state[.cross]?.removeAll()
        self.state[.circle]?.removeAll()

        Task { @MainActor in
            self.sceneDelegate?.deleteAllGrids()
        }
    }

    func receive(command: RPC) {
        switch command {
            case let .opponentPlaced(position):
                self.place(at: position)
            case .gridMoved:
                break // disregard on simulator
            case let .gridPositionDefined(position):
                self.moveGrid(by: position)
            default:
                // RPCs handled by other entities
                break
        }
    }
}

extension GameController: SceneControllerGameDelegate {
    func didMoveGrid(by position: SIMD3<Float>) {
        self.broadcastDelegate?.send(command: .gridMoved(position), reliable: false)
    }

    func didDefineGridPosition(at position: SIMD3<Float>) {
        self.broadcastDelegate?.send(command: .gridPositionDefined(position), reliable: true)
    }
}

private extension Set where Element == Place.Position {
    func contains<C: Collection>(elements: C) -> Bool where C.Element == Element {
        let intersection = self.intersection(elements)
        return intersection.count == elements.count
    }
}

private extension Actor.Avatar {
    mutating func toggle() {
        switch self {
        case .circle:
            self = .cross
        case .cross:
            self = .circle
        }
    }
}
