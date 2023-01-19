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
    @MainActor var myAvatar: Actor.Avatar { get set }
    @MainActor var result: Wins { get set }
}

protocol GameControllerInterruptionDelegate: AnyObject {
    @MainActor func allow3DInteraction()
    @MainActor func deny3DInteraction()
    @MainActor func showAlert(title: String, description: String, actions: [InterruptingAlert.Action])
}

protocol GameControllerSceneDelegate: AnyObject {
    @MainActor func deleteAllGrids()
    @MainActor func makeNewGrid()
    @MainActor func paintGrid(with: Actor.Colour)
    @MainActor func strikeThrough(_ type: StrikeThrough.StrikeType, colour: Actor.Colour)
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

    private(set) var myColour = Actor.Colour.red

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

    func endMatch() {
        Task { @MainActor in
            let disconnectAction = InterruptingAlert.Action(title: "Yes", role: .destructive) {
                self.broadcastDelegate?.disconnect()
            }
            let cancelAction = InterruptingAlert.Action(title: "No", role: .cancel, action: {})
            self.interruptionDelegate?.showAlert(title: "End match", description: "Are you sure?", actions: [disconnectAction, cancelAction])
        }
    }

    private func wrapUp(avatar: Actor.Avatar, strikeThrough: StrikeThrough.StrikeType?, gridColour: Actor.Colour) {
        Task { @MainActor in
            if let strikeThrough {
                self.sceneDelegate?.strikeThrough(strikeThrough, colour: gridColour)
                self.sceneDelegate?.paintGrid(with: gridColour)
            }
            if avatar == .circle {
                self.sceneDelegate?.makeNewGrid()
            }
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
}

extension GameController: BroadcastControllerGameDelegate {
    func didConnect(isHost: Bool) {
        Task { @MainActor in
            if isHost {
                self.myColour = .red
                self.sceneDelegate?.makeNewGrid()
            } else {
                self.myColour = .blue
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
    func didPlaceActor(at position: Place.Position, isMyTurn: Bool) {
        let currentAvatar = (isMyTurn ? self.myAvatar : self.myAvatar.opposite)
        self.state[currentAvatar]?.insert(position)
        let state = self.state[currentAvatar]!

        let strikeThrough: StrikeThrough.StrikeType?
        let strikeThroughColour: Actor.Colour = (isMyTurn ? self.myColour : self.myColour.opposite)
        if state.contains(elements: [.topLeft, .top, .topRight]) {
            strikeThrough = .horizontal(.top)
        } else if state.contains(elements: [.left, .centre, .right]) {
            strikeThrough = .horizontal(.centre)
        } else if state.contains(elements: [.bottomLeft, .bottom, .bottomRight]) {
            strikeThrough = .horizontal(.bottom)
        } else if state.contains(elements: [.topLeft, .left, .bottomLeft]) {
            strikeThrough = .vertical(.left)
        } else if state.contains(elements: [.top, .centre, .bottom]) {
            strikeThrough = .vertical(.centre)
        } else if state.contains(elements: [.topRight, .right, .bottomRight]) {
            strikeThrough = .vertical(.right)
        } else if state.contains(elements: [.topLeft, .centre, .bottomRight]) {
            strikeThrough = .diagonal(.leftTop)
        } else if state.contains(elements: [.topRight, .centre, .bottomLeft]) {
            strikeThrough = .diagonal(.rightTop)
        } else {
            strikeThrough = nil
        }

        let hasWinner = (strikeThrough != nil)
        if hasWinner {
            if isMyTurn {
                self.result.me += 1
            } else {
                self.result.opponent += 1
            }
        }

        let allPlacesFilled = 9
        let filledWithCircles = self.state[.circle]?.count ?? 0
        let filledWithCrosses = self.state[.cross]?.count ?? 0
        let isDraw = (filledWithCircles + filledWithCrosses == allPlacesFilled)
        if hasWinner || isDraw {
            self.wrapUp(avatar: self.myAvatar, strikeThrough: strikeThrough, gridColour: strikeThroughColour)
            self.state[.cross]?.removeAll()
            self.state[.circle]?.removeAll()
            self.myAvatar.toggle()
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
        self = self.opposite
    }
}
