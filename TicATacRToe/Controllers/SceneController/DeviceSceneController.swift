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

final class DeviceSceneController: NSObject, SceneController {
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
        case connectivityNotSet
        case gridNotDefined
        case notAddingGrid
        case placeNotDefined(Place.Position)
    }

    private let cameraReference = Entity()

    var renderDelegate: SceneControllerRenderDelegate?

    weak var broadcastDelegate: SceneControllerBroadcastDelegate?
    weak var gameDelegate: SceneControllerGameDelegate?
    weak var interruptionDelegate: SceneControllerInterruptionDelegate?

    weak var arView: ARView! {
        didSet {
            self.cancellables.removeAll()

            self.arView.scene
                .publisher(for: SynchronizationEvents.OwnershipChanged.self)
                .sink(receiveValue: self.handleOwnershipChange(event:))
                .store(in: &self.cancellables)

            self.arView.scene
                .publisher(for: SceneEvents.DidAddEntity.self)
                .sink(receiveValue: self.reportAddedPlace(event:))
                .store(in: &self.cancellables)
        }
    }

    private var addingGrid: Grid?
    private var cancellables = Set<AnyCancellable>()
    private var currentGrid: Grid?
    private var gridDistance: Float = Constraints.Distance.default
    private var gridScale: Float = Constraints.Scale.default
    private var sceneUpdateCancellable: AnyCancellable?

    func adjustGrid(distance: Float, scale: Float) {
        guard self.addingGrid != nil else {
            return
        }
        self.gridDistance = (self.gridDistance - (distance * 0.001)).fenced(min: Constraints.Distance.min, max: Constraints.Distance.max)
        self.gridScale = (self.gridScale + (scale - 1.0) * 0.2).fenced(min: Constraints.Scale.min, max: Constraints.Scale.max)
    }

    func defineGridPosition() throws {
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
        self.addingGrid = nil

        Task { @MainActor in
            self.renderDelegate?.didChangeGridStatus(isDefined: true)
        }

        self.sceneUpdateCancellable = nil
    }

    func handleTap(at point: CGPoint) throws {
        try self.queryPlace(at: point)?.fill(with: .circle, colour: .blue)
    }

    private func handleError(_ error: Swift.Error) {
        Task { @MainActor in
            self.interruptionDelegate?.handleError(error)
        }
    }

    private func queryPlace(at point: CGPoint) throws -> Place? {
        guard self.currentGrid != nil else {
            throw Error.gridNotDefined
        }
        let queryResults = self.arView.hitTest(point, query: .nearest, mask: .all)
        return queryResults.compactMap({ $0.entity as? Place }).first
    }

    private func handleOwnershipChange(event: SynchronizationEvents.OwnershipChanged) {
        self.gameDelegate?.didChangeOwner(isOwner: event.entity.isOwner)
    }

    private func reportAddedPlace(event: SceneEvents.DidAddEntity) {
        if event.entity is Place {
            self.gameDelegate?.didPlaceActor()
        }
    }

    private func sceneUpdate(event: SceneEvents.Update) {
        self.addingGrid?.position.z = -self.gridDistance
        self.addingGrid?.scale = [self.gridScale, self.gridScale, 1.0]
    }
}

extension DeviceSceneController: ARSessionDelegate {
    func session(_ session: ARSession, didOutputCollaborationData collabotationData: ARSession.CollaborationData) {
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: collabotationData, requiringSecureCoding: true)
            self.broadcastDelegate?.send(command: .sessionData(data), reliable: (collabotationData.priority == .critical))
        } catch {
            self.handleError(error)
        }
    }

    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        if let participant = anchors.compactMap({ $0 as? ARParticipantAnchor }).first, participant.sessionIdentifier != session.identifier {
            self.broadcastDelegate?.sessionDidConnect()
        }
    }

    func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        if let participant = anchors.compactMap({ $0 as? ARParticipantAnchor }).first, participant.sessionIdentifier != session.identifier {
            self.broadcastDelegate?.sessionDidDisconnect()
        }
    }
}

extension DeviceSceneController: GameControllerSceneDelegate {
    @MainActor func deleteAllGrids() {
        self.arView.scene.anchors.forEach { element in
            element.removeFromParent()
        }
    }

    @MainActor func makeNewGrid() {
        self.renderDelegate?.didChangeGridStatus(isDefined: false)

        let grid = Grid()
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
        guard let currentGrid else {
            throw Error.gridNotDefined
        }
        currentGrid.paintGrid(with: colour)
    }

    @MainActor func strikeThrough(_ type: StrikeThrough.StrikeType, colour: Actor.Colour) throws -> Void {
        guard let currentGrid else {
            throw Error.gridNotDefined
        }

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

        currentGrid.addChild(strikeThrough)
    }
}

extension DeviceSceneController: BroadcastControllerSceneDelegate {
    func didBreakConnection() {
        self.arView.session.pause()
        self.arView.session.delegate = nil
        self.arView.scene.synchronizationService = nil
    }

    func didEstablishConnection() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.environmentTexturing = .automatic
        configuration.isCollaborationEnabled = true

        self.arView.session.run(configuration)
        self.arView.session.delegate = self

        do {
            guard let session = self.broadcastDelegate?.session else {
                throw Error.connectivityNotSet
            }
            self.arView.scene.synchronizationService = try MultipeerConnectivityService(session: session)
        } catch {
            self.handleError(error)
        }
    }

    func receive(command: RPC) {
        guard case let .sessionData(data) = command else {
            return
        }
        do {
            if let collabotationData = try NSKeyedUnarchiver.unarchivedObject(ofClass: ARSession.CollaborationData.self, from: data) {
                self.arView.session.update(with: collabotationData)
            }
        } catch {
            self.handleError(error)
        }
    }
}
#endif
