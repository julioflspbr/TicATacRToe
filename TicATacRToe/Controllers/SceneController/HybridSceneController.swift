//
//  SceneController+Device.swift
//  TicATacRToe
//
//  Created by Julio Flores on 07/01/2023.
//

#if !targetEnvironment(simulator)
import ARKit
import Combine
import Foundation
import RealityKit
import MultipeerConnectivity

final class HybridSceneController: NSObject, SceneController {
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
        case wrongPlace
    }

    private let cameraReference = Entity()

    var renderDelegate: SceneControllerRenderDelegate?

    weak var arView: ARView!
    weak var broadcastDelegate: SceneControllerBroadcastDelegate?
    weak var gameDelegate: SceneControllerGameDelegate?
    weak var interruptionDelegate: SceneControllerInterruptionDelegate?

    private var addingGrid: Grid?
    private var cancellables = Set<AnyCancellable>()
    private var gridDistance = Constraints.Distance.default
    private var gridScale = Constraints.Scale.default
    private var isOwner = false
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

        self.gridDistance = Constraints.Scale.default
        self.gridScale = Constraints.Scale.default
        self.sceneUpdateCancellable = nil
        self.addingGrid = nil
        self.isOwner = true

        self.broadcastDelegate?.send(command: .gridDefined, reliable: true)
        self.renderDelegate?.didChangeGridStatus(isDefined: true)
    }

    @MainActor func handleTap(at point: CGPoint) {
        guard let gameDelegate, self.isOwner else {
            return
        }
        guard let place = self.queryPlace(at: point), place.parent == self.currentGrid else {
            return
        }
        place.fill(with: gameDelegate.myAvatar, colour: gameDelegate.myColour)
    }

    private func queryPlace(at point: CGPoint) -> Place? {
        let queryResults = self.arView.hitTest(point, query: .nearest, mask: .all)
        return queryResults.compactMap({ $0.entity as? Place }).first
    }

    @MainActor private func placeOpponent(at position: Place.Position) {
        do {
            guard let place = self.currentGrid.findPlace(at: position) else {
                throw Error.wrongPlace
            }
            guard let gameDelegate else {
                return
            }
            place.fill(with: gameDelegate.myAvatar.opposite, colour: gameDelegate.myColour.opposite)
        } catch {
            self.interruptionDelegate?.handleError(error)
        }
    }

    private func reportAddedActor(event: SceneEvents.DidAddEntity) {
        if let actor = event.entity as? Actor, let place = actor.parent as? Place {
            self.gameDelegate?.didPlaceActor(at: place.placePosition, isMyTurn: self.isOwner)
            if self.isOwner {
                self.broadcastDelegate?.send(command: .placedActor(place.placePosition), reliable: true)
            }
            self.isOwner.toggle()
        }
    }

    private func sceneUpdate(event: SceneEvents.Update) {
        self.addingGrid?.position.z = -self.gridDistance
        self.addingGrid?.scale = [self.gridScale, self.gridScale, 1.0]
    }

    @MainActor private func spawnGridAsTenant() {
        let cameraAnchor = AnchorEntity(.camera)
        let reference = Entity()

        self.arView.scene.addAnchor(cameraAnchor)
        cameraAnchor.addChild(reference)
        reference.position.z = -2.5
        reference.removeFromParent(preservingWorldTransform: true)
        cameraAnchor.removeFromParent()

        let gridAnchor = AnchorEntity(world: reference.transform.matrix)
        let grid = Grid()
        grid.makeDefaultGrid()

        gridAnchor.addChild(grid)
        self.arView.scene.addAnchor(gridAnchor)

        self.currentGrid = grid
        self.isOwner = false
    }
}

extension HybridSceneController: GameControllerSceneDelegate {
    @MainActor func deleteAllGrids() {
        self.sceneUpdateCancellable = nil
        self.cancellables.removeAll()
        self.arView.scene.anchors.removeAll()
    }

    @MainActor func makeNewGrid() {
        Task { @MainActor in
            self.renderDelegate?.didChangeGridStatus(isDefined: false)
        }

        let grid = Grid()
        grid.makeDefaultGrid()
        grid.position.z = -self.gridDistance
        self.addingGrid = grid

        let anchor = AnchorEntity(.camera)
        anchor.addChild(grid)
        self.arView.scene.addAnchor(anchor)

        self.sceneUpdateCancellable = self.arView.scene
            .publisher(for: SceneEvents.Update.self)
            .sink(receiveValue: self.sceneUpdate(event:))
    }

    @MainActor func paintGrid(with colour: Actor.Colour) throws {
        self.currentGrid.paintGrid(with: colour)
    }

    @MainActor func strikeThrough(_ type: StrikeThrough.StrikeType, colour: Actor.Colour) throws -> Void {
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

extension HybridSceneController: BroadcastControllerSceneDelegate {
    var device: RPC.DeviceType {
        .device
    }

    func didBreakConnection() {
        self.broadcastDelegate?.sessionDidDisconnect()
        self.arView.session.pause()
        self.arView.session.delegate = nil
        self.arView.scene.synchronizationService = nil
    }

    func didEstablishConnection() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.environmentTexturing = .automatic
        self.arView.session.run(configuration)

        self.cancellables.removeAll()

        self.arView.scene
            .publisher(for: SceneEvents.DidAddEntity.self)
            .sink(receiveValue: self.reportAddedActor(event:))
            .store(in: &self.cancellables)
    }

    func receive(command: RPC) {
        Task { @MainActor in
            switch command {
                case .gridDefined:
                    self.spawnGridAsTenant()
                case let .placedActor(position):
                    self.placeOpponent(at: position)
                case .connected:
                    self.broadcastDelegate?.sessionDidConnect()
                default:
                    break
            }
        }
    }
}
#endif
