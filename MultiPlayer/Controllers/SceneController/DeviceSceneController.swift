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
        case notAddingGrid
        case ownershipTransferError
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
    private var sceneUpdateCancellable: AnyCancellable?

    private var connectivity: MultipeerConnectivityService? {
        self.arView.scene.synchronizationService as? MultipeerConnectivityService
    }

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

        self.gridDistance = Constraints.Scale.default
        self.gridScale = Constraints.Scale.default
        self.sceneUpdateCancellable = nil
        self.addingGrid = nil

        self.renderDelegate?.didChangeGridStatus(isDefined: true)
    }

    @MainActor func handleTap(at point: CGPoint) {
        guard let gameDelegate, self.currentGrid?.isOwner == true else {
            return
        }
        guard let place = self.queryPlace(at: point), place.parent == self.currentGrid else {
            return
        }
        place.fill(with: gameDelegate.myAvatar, colour: gameDelegate.myColour)
        self.broadcastDelegate?.send(command: .placedActor(place.placePosition), reliable: true)
    }

    private func handleError(_ error: Swift.Error) {
        self.broadcastDelegate?.disconnect()
        Task { @MainActor in
            self.interruptionDelegate?.handleError(error)
        }
    }

    private func queryPlace(at point: CGPoint) -> Place? {
        let queryResults = self.arView.hitTest(point, query: .nearest, mask: .all)
        return queryResults.compactMap({ $0.entity as? Place }).first
    }

    private func reportAddedActor(event: SceneEvents.DidAddEntity) {
        if let grid = event.entity as? Grid {
            self.currentGrid = grid
        }
        if let actor = event.entity as? Actor, let place = actor.parent as? Place, let grid = place.parent as? Grid {
            self.gameDelegate?.didPlaceActor(at: place.placePosition, isMyTurn: grid.isOwner)
            if !grid.isOwner {
                self.requestOwnership()
            }
        }
    }

    private func requestOwnership() {
        self.currentGrid.requestOwnership { [weak self] failure in
            if case .timedOut = failure {
                self?.handleError(Error.ownershipTransferError)
            }
        }
    }

    private func sceneUpdate(event: SceneEvents.Update) {
        self.addingGrid?.position.z = -self.gridDistance
        self.addingGrid?.scale = [self.gridScale, self.gridScale, 1.0]
    }

    private func updateSession(with data: Data) {
        do {
            if let collabotationData = try NSKeyedUnarchiver.unarchivedObject(ofClass: ARSession.CollaborationData.self, from: data) {
                self.arView.session.update(with: collabotationData)
            }
        } catch {
            self.handleError(error)
        }
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
}

extension DeviceSceneController: GameControllerSceneDelegate {
    @MainActor func deleteAllGrids() {
        self.sceneUpdateCancellable = nil
        self.cancellables.removeAll()

        self.arView.scene.anchors.forEach { element in
            element.removeFromParent()
        }
    }

    @MainActor func makeNewGrid() {
        self.renderDelegate?.didChangeGridStatus(isDefined: false)

        let grid = Grid()
        grid.makeDefaultGrid()
        grid.position.z = -self.gridDistance
        self.addingGrid = grid

        let anchor = AnchorEntity(.camera)
        anchor.addChild(grid)
        self.arView.scene.addAnchor(anchor)

        self.sceneUpdateCancellable = self.arView.scene
            .publisher(for: SceneEvents.Update.self)
            .sink { [weak self] event in
                self?.sceneUpdate(event: event)
            }
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

extension DeviceSceneController: BroadcastControllerSceneDelegate {
    var device: RPC.DeviceType {
        .device
    }

    @MainActor func didBreakConnection() {
        self.renderDelegate?.didChangeGridStatus(isDefined: true)
        self.broadcastDelegate?.sessionDidDisconnect()
        self.arView.scene.synchronizationService = nil

        self.sceneUpdateCancellable = nil
        self.cancellables.removeAll()
        self.connectivity?.stopSync()

        self.arView.session.pause()
        self.arView.session.delegate = nil

    }

    @MainActor func didEstablishConnection() {
        do {
            guard let session = self.broadcastDelegate?.session else {
                throw Error.connectivityNotSet
            }

            let configuration = ARWorldTrackingConfiguration()
            configuration.environmentTexturing = .automatic
            configuration.isCollaborationEnabled = true

            let connectivity = try MultipeerConnectivityService(session: session)
            connectivity.startSync()

            self.arView.session.run(configuration)
            self.arView.session.delegate = self
            self.arView.scene.synchronizationService = connectivity

            self.cancellables.removeAll()

            self.arView.scene
                .publisher(for: SceneEvents.DidAddEntity.self)
                .sink(receiveValue: { [weak self] event in
                    self?.reportAddedActor(event: event)
                })
                .store(in: &self.cancellables)
        } catch {
            self.handleError(error)
        }
    }

    func receive(command: RPC) {
        if case let .sessionData(data) = command {
            self.updateSession(with: data)
        }
    }
}
#endif
