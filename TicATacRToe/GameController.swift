//
//  GameController.swift
//  TicATacRToe
//
//  Created by Julio Flores on 21/12/2022.
//

import SwiftUI
import SceneKit

protocol GameControllerSceneDelegate: AnyObject {
    @MainActor func defineGrid(at: SIMD3<Float>) throws
    @MainActor func makeNewGrid()
    @MainActor func place(for: Place.Position) throws -> Place
    @MainActor func queryPlace(at: CGPoint) -> Place?
    @MainActor func strikeThrough(_: StrikeThrough.StrikeType) -> Void
}

protocol GameControllerInterruptionDelegate: AnyObject {
    @MainActor func allow3DInteraction()
    @MainActor func deny3DInteraction()
    @MainActor func handleError(_ error: Error)
}

protocol GameControllerBroadcastDelegate: AnyObject {
    func send(command: RPC, reliable: Bool)
}

final class GameController: ObservableObject {
    struct Wins {
        var me: UInt = 0
        var opponent: UInt = 0
    }

    weak var broadcastDelegate: GameControllerBroadcastDelegate?
    weak var interruptionDelegate: GameControllerInterruptionDelegate?
    weak var sceneDelegate: GameControllerSceneDelegate?

    @MainActor @Published var isGameSetUp = false {
        didSet {
            if self.isGameSetUp {
                self.interruptionDelegate?.allow3DInteraction()
            } else {
                self.interruptionDelegate?.deny3DInteraction()
            }
        }
    }

    @MainActor @Published private(set) var currentAvatar = Actor.Avatar.cross
    @MainActor @Published private(set) var myAvatar = Actor.Avatar.cross
    @MainActor @Published private(set) var result = Wins()

    private var state = [Actor.Avatar.cross: Set<Place.Position>(), Actor.Avatar.circle: Set<Place.Position>()]

    func handleTap(at point: CGPoint) {
        Task { @MainActor in
            guard self.currentAvatar == self.myAvatar else {
                return
            }
            if let placeNode = self.sceneDelegate?.queryPlace(at: point) {
                self.fill(place: placeNode)
                self.broadcastDelegate?.send(command: .opponentPlaced(placeNode.place), reliable: true)
            }
        }
    }

    @MainActor private func checkVictoryCondition() {
        guard let state = self.state[self.currentAvatar] else {
            return
        }

        let hasVictory: Bool
        if state.contains(elements: [.topLeft, .top, .topRight]) {
            self.sceneDelegate?.strikeThrough(.horizontal(.top))
            hasVictory = true
        } else if state.contains(elements: [.left, .centre, .right]) {
            self.sceneDelegate?.strikeThrough(.horizontal(.centre))
            hasVictory = true
        } else if state.contains(elements: [.bottomLeft, .bottom, .bottomRight]) {
            self.sceneDelegate?.strikeThrough(.horizontal(.bottom))
            hasVictory = true
        } else if state.contains(elements: [.topLeft, .left, .bottomLeft]) {
            self.sceneDelegate?.strikeThrough(.vertical(.left))
            hasVictory = true
        } else if state.contains(elements: [.top, .centre, .bottom]) {
            self.sceneDelegate?.strikeThrough(.vertical(.centre))
            hasVictory = true
        } else if state.contains(elements: [.topRight, .right, .bottomRight]) {
            self.sceneDelegate?.strikeThrough(.vertical(.right))
            hasVictory = true
        } else if state.contains(elements: [.topLeft, .centre, .bottomRight]) {
            self.sceneDelegate?.strikeThrough(.diagonal(.leftTop))
            hasVictory = true
        } else if state.contains(elements: [.topRight, .centre, .bottomLeft]) {
            self.sceneDelegate?.strikeThrough(.diagonal(.rightTop))
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

            self.myAvatar.toggle()
            self.sceneDelegate?.makeNewGrid()
        }
    }

    @MainActor private func defineGridPosition() {
        // simulate simulator defining grid position

        Task {
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

    @MainActor private func fill(place: Place) {
        do {
            try place.fill(with: self.currentAvatar)
            self.state[self.currentAvatar]?.insert(place.place)
            self.checkVictoryCondition()
            self.currentAvatar.toggle()
        } catch {
            self.interruptionDelegate?.handleError(error)
        }
    }
}

extension GameController: BroadcastControllerGameDelegate {
    func didConnect(isHost: Bool) {
        Task { @MainActor in
            self.sceneDelegate?.makeNewGrid()

            if isHost {
                self.defineGridPosition()
                self.myAvatar.toggle()
            }
        }
    }

    func receive(command: RPC) {
        switch command {
            case let .opponentPlaced(position):
                Task { @MainActor in
                    do {
                        guard let placeNode = try self.sceneDelegate?.place(for: position) else {
                            return
                        }
                        self.fill(place: placeNode)
                    } catch {
                        self.interruptionDelegate?.handleError(error)
                    }
                }
            case .gridMoved:
                // disregard on simulator
                break
            case let .gridPositionDefined(position):
                Task { @MainActor in
                    do {
                        try self.sceneDelegate?.defineGrid(at: position)
                    } catch {
                        self.interruptionDelegate?.handleError(error)
                    }
                }
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
