//
//  SceneController.swift
//  TicATacRToe-SP
//
//  Created by Julio Flores on 17/01/2023.
//

import Foundation

import ARKit
import Combine
import Foundation
import RealityKit

protocol SceneControllerGameDelegate: AnyObject {
    var myAvatar: Actor.Avatar { get }
    func didPlaceActor(at: Place.Position)
}

protocol SceneControllerRenderDelegate {
    @MainActor func didChangeGridStatus(isDefined: Bool)
}

final class SceneController {
    private enum Constraints {
        enum Distance {
            static var `default`: Float { 2.0 }
            static var max: Float { 5.0 }
            static var min: Float { 0.5 }
        }

        enum Scale {
            static var `default`: Float { 1.0 }
            static var max: Float { 3.0 }
            static var min: Float { 0.5 }
        }
    }

    enum Error: Swift.Error {
        case notAddingGrid
    }

    private let cameraReference = Entity()

    var renderDelegate: SceneControllerRenderDelegate?

    weak var arView: ARView!
    weak var gameDelegate: SceneControllerGameDelegate?

    private var addingGrid: Grid?
    private var addPlaceCancellable: AnyCancellable?
    private var gridDistance = Constraints.Distance.default
    private var gridScale = Constraints.Scale.default
    private var sceneUpdateCancellable: AnyCancellable?

    private weak var currentGrid: Grid!

    @MainActor func adjustGrid(distance: Float, scale: Float) {
        guard self.addingGrid != nil else {
            return
        }
        self.gridDistance = (self.gridDistance - (distance * 0.001)).fenced(min: Constraints.Distance.min, max: Constraints.Distance.max)
        self.gridScale = (self.gridScale + (scale - 1.0) * 0.2).fenced(min: Constraints.Scale.min, max: Constraints.Scale.max)
    }

    @MainActor func defineGridPosition() throws {
        guard let addingGrid else {
            throw Error.notAddingGrid
        }
        let temporaryAnchor = addingGrid.parent
        let currentGridTransform = addingGrid.convert(transform: .identity, to: nil)
        let permanentAnchor = AnchorEntity(.world(transform: currentGridTransform.matrix))

        temporaryAnchor?.removeFromParent()
        addingGrid.removeFromParent()

        addingGrid.transform = .identity
        permanentAnchor.addChild(addingGrid)
        self.arView.scene.addAnchor(permanentAnchor)
        self.currentGrid = addingGrid

        self.addPlaceCancellable = self.arView.scene
            .publisher(for: SceneEvents.DidAddEntity.self)
            .sink { [weak self] event in
                self?.reportAddedActor(event: event)
            }

        self.gridDistance = Constraints.Scale.default
        self.gridScale = Constraints.Scale.default
        self.sceneUpdateCancellable = nil
        self.addingGrid = nil

        Task {
            self.renderDelegate?.didChangeGridStatus(isDefined: true)
        }
    }

    @MainActor func handleTap(at point: CGPoint) {
        guard let gameDelegate, self.currentGrid?.isOwner == true else {
            return
        }
        guard let place = self.queryPlace(at: point), place.parent == self.currentGrid else {
            return
        }
        place.fill(with: gameDelegate.myAvatar)
    }

    private func queryPlace(at point: CGPoint) -> Place? {
        let queryResults = self.arView.hitTest(point, query: .nearest, mask: .all)
        return queryResults.compactMap({ $0.entity as? Place }).first
    }

    private func reportAddedActor(event: SceneEvents.DidAddEntity) {
        if let actor = event.entity as? Actor, let place = actor.parent as? Place {
            self.gameDelegate?.didPlaceActor(at: place.placePosition)
        }
    }

    private func sceneUpdate(event: SceneEvents.Update) {
        self.addingGrid?.position.z = -self.gridDistance
        self.addingGrid?.scale = [self.gridScale, self.gridScale, 1.0]
    }
}

extension SceneController: GameControllerSceneDelegate {
    @MainActor func makeNewGrid() {
        Task {
            self.renderDelegate?.didChangeGridStatus(isDefined: false)
        }

        let grid = Grid()
        grid.makeDefaultGrid()
        grid.position.z = -self.gridDistance
        self.addingGrid = grid

        let anchor = AnchorEntity(.camera)
        anchor.addChild(grid)
        self.arView.scene.addAnchor(anchor)

        self.addPlaceCancellable = nil
        self.sceneUpdateCancellable = self.arView.scene
            .publisher(for: SceneEvents.Update.self)
            .sink(receiveValue: self.sceneUpdate(event:))
    }

    @MainActor func paintGrid(with colour: Actor.Colour) {
        self.currentGrid.paintGrid(with: colour)
    }

    @MainActor func strikeThrough(_ type: StrikeThrough.StrikeType, colour: Actor.Colour) -> Void {
        let shift: Float = 0.34
        let strikeThrough = StrikeThrough(type: type, colour: colour)

        switch type {
            case let .horizontal(position):
                switch position {
                    case .top:
                        strikeThrough.position = [0.0, shift, 0.0]
                    case .centre:
                        strikeThrough.position = [0.0, 0.0, 0.0]
                    case .bottom:
                        strikeThrough.position = [0.0, -shift, 0.0]
                }
            case let .vertical(position):
                switch position {
                    case .left:
                        strikeThrough.position = [-shift, 0.0, 0.0]
                    case .centre:
                        strikeThrough.position = [0.0, 0.0, 0.0]
                    case .right:
                        strikeThrough.position = [shift, 0.0, 0.0]
                }
            case .diagonal:
                strikeThrough.position = [0.0, 0.0, 0.0]
        }

        self.currentGrid.addChild(strikeThrough)
    }
}

extension FloatingPoint {
    func fenced(min: Self, max: Self) -> Self {
        Self.minimum(Self.maximum(self, min), max)
    }
}
