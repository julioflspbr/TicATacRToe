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
    @MainActor func makeNewGrid()
    @MainActor func paintGrid(with: Actor.Colour) throws
    @MainActor func strikeThrough(_ type: StrikeThrough.StrikeType, colour: Actor.Colour) throws
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

    private var colour = Actor.Colour.red
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

    func endMatch() {
        Task { @MainActor in
            let disconnectAction = InterruptingAlert.Action(title: "Yes", role: .destructive) {
                self.broadcastDelegate?.disconnect()
            }
            let cancelAction = InterruptingAlert.Action(title: "No", role: .cancel, action: {})
            self.interruptionDelegate?.showAlert(title: "End match", description: "Are you sure?", actions: [disconnectAction, cancelAction])
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

    private func strikeThrough(_ type: StrikeThrough.StrikeType, colour: Actor.Colour) {
        Task { @MainActor in
            do {
                try self.sceneDelegate?.strikeThrough(type, colour: colour)
            } catch {
                self.interruptionDelegate?.handleError(error)
            }
        }
    }
}

extension GameController: BroadcastControllerGameDelegate {
    func didConnect(isHost: Bool) {
        Task { @MainActor in
            if isHost {
                self.colour = .red
                self.sceneDelegate?.makeNewGrid()
            } else {
                self.colour = .blue
                self.myAvatar.toggle()
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
}

extension GameController: SceneControllerGameDelegate {
    func didChangeOwner(isOwner: Bool) {
        var avatar = self.myAvatar
        if !isOwner {
            avatar.toggle()
        }
        self.currentAvatar = avatar
    }

    func didPlaceActor() {
        guard let state = self.state[self.currentAvatar] else {
            return
        }

        let hasWinner: Bool
        if state.contains(elements: [.topLeft, .top, .topRight]) {
            self.strikeThrough(.horizontal(.top), colour: self.colour)
            hasWinner = true
        } else if state.contains(elements: [.left, .centre, .right]) {
            self.strikeThrough(.horizontal(.centre), colour: self.colour)
            hasWinner = true
        } else if state.contains(elements: [.bottomLeft, .bottom, .bottomRight]) {
            self.strikeThrough(.horizontal(.bottom), colour: self.colour)
            hasWinner = true
        } else if state.contains(elements: [.topLeft, .left, .bottomLeft]) {
            self.strikeThrough(.vertical(.left), colour: self.colour)
            hasWinner = true
        } else if state.contains(elements: [.top, .centre, .bottom]) {
            self.strikeThrough(.vertical(.centre), colour: self.colour)
            hasWinner = true
        } else if state.contains(elements: [.topRight, .right, .bottomRight]) {
            self.strikeThrough(.vertical(.right), colour: self.colour)
            hasWinner = true
        } else if state.contains(elements: [.topLeft, .centre, .bottomRight]) {
            self.strikeThrough(.diagonal(.leftTop), colour: self.colour)
            hasWinner = true
        } else if state.contains(elements: [.topRight, .centre, .bottomLeft]) {
            self.strikeThrough(.diagonal(.rightTop), colour: self.colour)
            hasWinner = true
        } else {
            hasWinner = false
        }

        if hasWinner {
            if self.currentAvatar == self.myAvatar {
                self.result.me += 1
                Task { @MainActor in
                    do {
                        try self.sceneDelegate?.paintGrid(with: self.colour)
                    } catch {
                        self.interruptionDelegate?.handleError(error)
                    }
                }
            } else {
                self.result.opponent += 1
            }
        }

        let allPlacesFilled = 9
        let filledWithCircles = self.state[.circle]?.count ?? 0
        let filledWithCrosses = self.state[.cross]?.count ?? 0
        let isDraw = (filledWithCircles + filledWithCrosses == allPlacesFilled)
        if hasWinner || isDraw {
            self.state[.cross]?.removeAll()
            self.state[.circle]?.removeAll()
            self.currentAvatar = .cross
            self.myAvatar.toggle()

            Task { @MainActor in
                if self.myAvatar == .cross {
                    self.sceneDelegate?.makeNewGrid()
                }
            }
        }
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
