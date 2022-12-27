//
//  GameController.swift
//  TicATacRToe
//
//  Created by Julio Flores on 21/12/2022.
//

import SwiftUI
import SceneKit

protocol GameControllerSceneDelegate: AnyObject {
    func queryPlace(at: CGPoint) -> Place?
    func strikeThrough(_: StrikeThrough.StrikeType) -> Void
}

protocol GameControllerInterruptionDelegate: AnyObject {
    func allow3DInteraction()
    func deny3DInteraction()
    func handleError(_ error: Error)
}

final class GameController: ObservableObject {
    weak var sceneDelegate: GameControllerSceneDelegate?
    weak var interruptionDelegate: GameControllerInterruptionDelegate?

    @Published private(set) var currentAvatar = Actor.Avatar.cross

    @Published var availablePlayers = [String]()

    @Published var nickname = "" {
        didSet {
            self.checkSetupState()
        }
    }
    @Published var opponent: String? {
        didSet {
            self.checkSetupState()
        }
    }

    private var state = [Actor.Avatar.cross: Set<Place.Position>(), Actor.Avatar.circle: Set<Place.Position>()]

    var isGameSetUp: Bool {
        self.nickname.count >= 3 && opponent != nil
    }

    func handleTap(at point: CGPoint) {
        do {
            guard let placeNode = self.sceneDelegate?.queryPlace(at: point) else {
                return
            }

            try placeNode.fill(with: self.currentAvatar)
            self.state[self.currentAvatar]?.insert(placeNode.place)
            self.checkVictoryCondition()
            self.currentAvatar.toggle()
        } catch {
            self.interruptionDelegate?.handleError(error)
        }
    }

    private func checkSetupState() {
        if self.isGameSetUp {
            self.interruptionDelegate?.allow3DInteraction()
        } else {
            self.interruptionDelegate?.deny3DInteraction()
        }
    }

    private func checkVictoryCondition() {
        guard let state = self.state[self.currentAvatar] else {
            return
        }

        if state.contains(elements: [.topLeft, .top, .topRight]) {
            self.sceneDelegate?.strikeThrough(.horizontal(.top))
        } else if state.contains(elements: [.left, .centre, .right]) {
            self.sceneDelegate?.strikeThrough(.horizontal(.centre))
        } else if state.contains(elements: [.bottomLeft, .bottom, .bottomRight]) {
            self.sceneDelegate?.strikeThrough(.horizontal(.bottom))
        } else if state.contains(elements: [.topLeft, .left, .bottomLeft]) {
            self.sceneDelegate?.strikeThrough(.vertical(.left))
        } else if state.contains(elements: [.top, .centre, .bottom]) {
            self.sceneDelegate?.strikeThrough(.vertical(.centre))
        } else if state.contains(elements: [.topRight, .right, .bottomRight]) {
            self.sceneDelegate?.strikeThrough(.vertical(.right))
        } else if state.contains(elements: [.topLeft, .centre, .bottomRight]) {
            self.sceneDelegate?.strikeThrough(.diagonal(.leftTop))
        } else if state.contains(elements: [.topRight, .centre, .bottomLeft]) {
            self.sceneDelegate?.strikeThrough(.diagonal(.rightTop))
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
