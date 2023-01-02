//
//  GameController.swift
//  TicATacRToe
//
//  Created by Julio Flores on 21/12/2022.
//

import SwiftUI
import SceneKit

protocol GameControllerBroadcastDelegate: AnyObject {
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
}

protocol GameControllerSceneDelegate: AnyObject {
    @MainActor func defineGrid(at: SIMD3<Float>) throws
    @MainActor func makeNewGrid()
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

    func handleTap(at point: CGPoint) {
        guard self.currentAvatar == self.myAvatar else {
            return
        }

        Task {
            if let placeNode = await self.queryPlace(at: point) {
                self.fill(place: placeNode)
                self.broadcastDelegate?.send(command: .opponentPlaced(placeNode.place), reliable: true)
            }
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
            self.makeNewGrid()
            if self.myAvatar == .cross {
                self.defineGridPosition()
            }
        } else {
            self.currentAvatar.toggle()
        }
    }

    private func defineGridPosition() {
        // simulate simulator defining grid position

        Task { @MainActor in
            let attemptCount = 5
            let finalAttempt = 4
            var positionDefined = SIMD3<Float>()

            for i in 0 ..< attemptCount {
                if i < finalAttempt {
                    try await Task.sleep(nanoseconds: 200 * NSEC_PER_MSEC)
                    let fakeX = Float.random(in: -100.0 ... 100.0)
                    let fakeY = Float.random(in: -100.0 ... 100.0)
                    let fakeZ = Float.random(in: -100.0 ... 100.0)
                    positionDefined = SIMD3<Float>(x: fakeX, y: fakeY, z: fakeZ)

                    self.broadcastDelegate?.send(command: .gridMoved(positionDefined), reliable: false)
                    print("Moving grid at: \(positionDefined)")
                } else {
                    try? self.sceneDelegate?.defineGrid(at: positionDefined)
                    self.broadcastDelegate?.send(command: .gridPositionDefined(positionDefined), reliable: true)
                    print("Defining grid at: \(positionDefined)")
                }
            }
        }
    }

    private func fill(place: Place) {
        let currentAvatar = self.currentAvatar
        Task { @MainActor in
            do {
                try place.fill(with: currentAvatar)
            } catch {
                self.handleError(error)
            }
        }

        self.state[currentAvatar]?.insert(place.place)
        self.checkGameEnd()
    }

    private func defineGrid(at position: SIMD3<Float>) {
        Task { @MainActor in
            do {
                try self.sceneDelegate?.defineGrid(at: position)
            } catch {
                self.handleError(error)
            }
        }
    }

    private func handleError(_ error: Error) {
        Task { @MainActor in
            self.interruptionDelegate?.handleError(error)
        }
    }

    private func makeNewGrid() {
        Task { @MainActor in
            self.sceneDelegate?.makeNewGrid()
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

    private func strikeThrough(_ type: StrikeThrough.StrikeType) {
        Task { @MainActor in
            self.sceneDelegate?.strikeThrough(type)
        }
    }
}

extension GameController: BroadcastControllerGameDelegate {
    func didConnect(isHost: Bool) {
        self.makeNewGrid()
        if isHost {
            self.defineGridPosition()
        } else {
            self.myAvatar.toggle()
        }
    }

    func receive(command: RPC) {
        switch command {
            case let .opponentPlaced(position):
                Task {
                    do {
                        if let placeNode = try await self.queryPlace(for: position) {
                            self.fill(place: placeNode)
                        }
                    } catch {
                        self.handleError(error)
                    }
                }
            case .gridMoved:
                // disregard on simulator
                break
            case let .gridPositionDefined(position):
                self.defineGrid(at: position)
            default:
                // TODO: implement RPCs
                break
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
