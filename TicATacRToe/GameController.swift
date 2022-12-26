//
//  GameController.swift
//  TicATacRToe
//
//  Created by Julio Flores on 21/12/2022.
//

import SwiftUI
import SceneKit

final class GameController: ObservableObject {
    let scene: SCNScene

    @Published var sceneController: SceneController?
    @Published var currentAvatar = Actor.Avatar.cross
    @Published var nickname = ""
    @Published var opponent: String?
    @Published var availablePlayers = [String]()
    @Published var isGameSetup = false

    private let camera: SCNNode

    private var state: [Actor.Avatar : Set<Place.Position>]

    init() {
        self.state = [.cross: [], .circle: []]

        self.scene = SCNScene()
        self.scene.rootNode.addChildNode(Grid())

        let camera = SCNCamera()
        camera.automaticallyAdjustsZRange = true

        self.camera = SCNNode()
        self.camera.position.z = 2.5
        self.camera.camera = camera
        self.scene.rootNode.addChildNode(self.camera)
    }

    func handleTap(at point: CGPoint) {
        do {
            guard let placeNode = self.sceneController?.queryPlaceNode(at: point) else {
                return
            }

            try placeNode.fill(with: self.currentAvatar)
            state[self.currentAvatar]?.insert(placeNode.place)
            self.checkVictoryCondition()
            self.currentAvatar.toggle()
        } catch {
            // TODO: implement error handler
            assertionFailure(error.localizedDescription)
        }
    }

    private func checkVictoryCondition() {
        guard let state = self.state[self.currentAvatar] else {
            return
        }

        if state.contains(elements: [.topLeft, .top, .topRight]) {
            self.createStrikeThrough(type: .horizontal(.top))
        } else if state.contains(elements: [.left, .centre, .right]) {
            self.createStrikeThrough(type: .horizontal(.centre))
        } else if state.contains(elements: [.bottomLeft, .bottom, .bottomRight]) {
            self.createStrikeThrough(type: .horizontal(.bottom))
        } else if state.contains(elements: [.topLeft, .left, .bottomLeft]) {
            self.createStrikeThrough(type: .vertical(.left))
        } else if state.contains(elements: [.top, .centre, .bottom]) {
            self.createStrikeThrough(type: .vertical(.centre))
        } else if state.contains(elements: [.topRight, .right, .bottomRight]) {
            self.createStrikeThrough(type: .vertical(.right))
        } else if state.contains(elements: [.topLeft, .centre, .bottomRight]) {
            self.createStrikeThrough(type: .diagonal(.leftTop))
        } else if state.contains(elements: [.topRight, .centre, .bottomLeft]) {
            self.createStrikeThrough(type: .diagonal(.rightTop))
        }
    }

    private func createStrikeThrough(type: StrikeThrough.StrikeType) {
        let shift: Float = 0.33
        let strikeThrough = StrikeThrough(type: type)

        switch type {
            case let .horizontal(position):
                switch position {
                    case .top:
                        strikeThrough.position = SCNVector3(0.0, shift, 0.0)
                    case .centre:
                        strikeThrough.position = SCNVector3(0.0, 0.0, 0.0)
                    case .bottom:
                        strikeThrough.position = SCNVector3(0.0, -shift, 0.0)
                }
            case let .vertical(position):
                switch position {
                    case .left:
                        strikeThrough.position = SCNVector3(-shift, 0.0, 0.0)
                    case .centre:
                        strikeThrough.position = SCNVector3(0.0, 0.0, 0.0)
                    case .right:
                        strikeThrough.position = SCNVector3(shift, 0.0, 0.0)
                }
            case .diagonal:
                strikeThrough.position = SCNVector3(0.0, 0.0, 0.0)
        }

        self.scene.rootNode.addChildNode(strikeThrough)
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
