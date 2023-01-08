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

protocol SceneControllerRenderDelegate {
    @MainActor func didChangeGridStatus(isDefined: Bool)
}

final class SceneController: NSObject {
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
        case gridNotDefined
        case notAddingGrid
        case placeNotDefined(Place.Position)
    }

    private let cameraReference = Entity()

    var renderDelegate: SceneControllerRenderDelegate?

    weak var arView: ARView! {
        didSet {
            self.cancellables.removeAll(keepingCapacity: true)

            self.arView.scene
                .publisher(for: SynchronizationEvents.OwnershipChanged.self)
                .sink(receiveValue: self.receiveOwnership(event:))
                .store(in: &self.cancellables)

            self.arView.scene
                .publisher(for: SceneEvents.DidAddEntity.self)
                .sink(receiveValue: self.reportAddedPlace(event:))
                .store(in: &self.cancellables)
        }
    }

    private var addingGrid: Grid?
    private var cancellables = [AnyCancellable]()
    private var currentGrid: Grid?
    private var gridDistance: Float = Constraints.Distance.default
    private var gridScale: Float = Constraints.Scale.default

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
    }

    func handleTap(at point: CGPoint) throws {
        guard let place = try self.queryPlace(at: point) else {
            return
        }
        try place.fill(with: .circle, colour: .blue)
        try self.strikeThrough(.diagonal(.rightTop), colour: .red)
    }

    func deleteAllGrids() {
        self.arView.scene.anchors.forEach { element in
            element.removeFromParent()
        }
    }

    func makeNewGrid() {
        Task { @MainActor in
            self.renderDelegate?.didChangeGridStatus(isDefined: false)
        }

        let grid = Grid()
        grid.position.z = -self.gridDistance
        self.addingGrid = grid

        let anchor = AnchorEntity(.camera)
        anchor.addChild(grid)
        self.arView.scene.addAnchor(anchor)
    }

    func pause() {
        self.arView.session.pause()
        self.arView.session.delegate = nil
    }

    func queryPlace(for position: Place.Position) throws -> Place {
        guard let currentGrid else {
            throw Error.gridNotDefined
        }
        guard let place = currentGrid.findPlace(at: position) else {
            throw Error.placeNotDefined(position)
        }
        return place
    }

    func start() {
        let configuration = ARWorldTrackingConfiguration()
        // TODO: enable collaboration
        //configuration.isCollaborationEnabled = true
        self.arView.session.run(configuration)
        self.arView.session.delegate = self
    }

    func strikeThrough(_ type: StrikeThrough.StrikeType, colour: Actor.Colour) throws -> Void {
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

    private func queryPlace(at point: CGPoint) throws -> Place? {
        guard currentGrid != nil else {
            throw Error.gridNotDefined
        }
        let queryResults = self.arView.hitTest(point, query: .nearest, mask: .all)
        return queryResults.compactMap({ $0.entity as? Place }).first
    }

    private func receiveOwnership(event: SynchronizationEvents.OwnershipChanged) {

    }

    private func reportAddedPlace(event: SceneEvents.DidAddEntity) {

    }
}

extension SceneController: ARSessionDelegate {
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {

    }

    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        guard let addingGrid else {
            return
        }
        addingGrid.position.z = -self.gridDistance
        addingGrid.scale = [self.gridScale, self.gridScale, 1.0]
    }
}

extension FloatingPoint {
    func fenced(min: Self, max: Self) -> Self {
        Self.minimum(Self.maximum(self, min), max)
    }
}
#endif
