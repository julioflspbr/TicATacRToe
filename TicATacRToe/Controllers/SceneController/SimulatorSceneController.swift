//
//  SceneController+Simulator.swift
//  TicATacRToe
//
//  Created by Júlio César Flores on 04/01/23.
//

#if targetEnvironment(simulator)
import SceneKit

final class SimulatorSceneController: SceneController {
    enum Error: Swift.Error {
        case notAddingGrid
        case wrongPlace
    }

    var broadcastDelegate: SceneControllerBroadcastDelegate?
    var gameDelegate: SceneControllerGameDelegate?
    var interruptionDelegate: SceneControllerInterruptionDelegate?
    var renderDelegate: SceneControllerRenderDelegate?

    weak var sceneView: SCNView! {
        didSet {
            self.sceneView.backgroundColor = .black
            self.sceneView.autoenablesDefaultLighting = true
            self.sceneView.allowsCameraControl = false
        }
    }

    private var addingGrid: Grid?
    private var isOwner = false

    private weak var currentGrid: Grid!

    @MainActor func adjustGrid(distance: Float, scale: Float) {
        guard self.addingGrid != nil else {
            return
        }
        // the grid does not move on simulator
        print("Adjust grid on Simulator - distance: \(distance), scale: \(scale)")
    }

    @MainActor func defineGridPosition() throws {
        guard let addingGrid else {
            throw Error.notAddingGrid
        }
        self.sceneView.scene?.rootNode.addChildNode(addingGrid)
        self.currentGrid = addingGrid
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
        self.isOwner = false
        place.fill(with: gameDelegate.myAvatar, colour: gameDelegate.myColour)
        gameDelegate.didPlaceActor(at: place.placePosition, isMyTurn: true)
        self.broadcastDelegate?.send(command: .placedActor(place.placePosition), reliable: true)
    }

    @MainActor private func placeOpponent(at position: Place.Position) {
        do {
            guard let place = self.currentGrid.findPlace(at: position) else {
                throw Error.wrongPlace
            }
            guard let gameDelegate else {
                return
            }
            self.isOwner = true
            place.fill(with: gameDelegate.myAvatar.opposite, colour: gameDelegate.myColour.opposite)
            gameDelegate.didPlaceActor(at: position, isMyTurn: false)
        } catch {
            self.interruptionDelegate?.handleError(error)
        }
    }

    private func queryPlace(at point: CGPoint) -> Place? {
        let hitTestResults = self.sceneView.hitTest(point)
        return hitTestResults.compactMap({ $0.node.parent as? Place }).first
    }

    @MainActor private func spawnGridAsTenant() {
        self.currentGrid?.removeFromParentNode()
        
        let grid = Grid()
        self.sceneView.scene?.rootNode.addChildNode(grid)
        self.currentGrid = grid
        self.isOwner = false
    }
}

extension SimulatorSceneController: GameControllerSceneDelegate {
    @MainActor func deleteAllGrids() {
        self.currentGrid?.removeFromParentNode()
        self.currentGrid = nil
    }

    @MainActor func makeNewGrid() {
        Task { @MainActor in
            self.renderDelegate?.didChangeGridStatus(isDefined: false)
        }
        self.currentGrid?.removeFromParentNode()
        self.currentGrid = nil
        self.addingGrid = Grid()
    }

    @MainActor func paintGrid(with colour: Actor.Colour) throws {
        self.currentGrid.paintGrid(with: colour)
    }

    @MainActor func strikeThrough(_ type: StrikeThrough.StrikeType, colour: Actor.Colour) throws {
        let shift: Float = 0.34
        let strikeThrough = StrikeThrough(type: type, colour: colour)

        switch type {
            case let .horizontal(position):
                switch position {
                    case .top:
                        strikeThrough.position = SCNVector3([0.0, shift, 0.0])
                    case .centre:
                        strikeThrough.position = SCNVector3([0.0, 0.0, 0.0])
                    case .bottom:
                        strikeThrough.position = SCNVector3([0.0, -shift, 0.0])
                }
            case let .vertical(position):
                switch position {
                    case .left:
                        strikeThrough.position = SCNVector3([-shift, 0.0, 0.0])
                    case .centre:
                        strikeThrough.position = SCNVector3([0.0, 0.0, 0.0])
                    case .right:
                        strikeThrough.position = SCNVector3([shift, 0.0, 0.0])
                }
            case .diagonal:
                strikeThrough.position = SCNVector3([0.0, 0.0, 0.0])
        }

        self.currentGrid.addChildNode(strikeThrough)
    }
}

extension SimulatorSceneController: BroadcastControllerSceneDelegate {
    var device: RPC.DeviceType {
        .simulator
    }

    @MainActor func didBreakConnection() {
        self.renderDelegate?.didChangeGridStatus(isDefined: true)
        self.broadcastDelegate?.sessionDidDisconnect()
        self.sceneView.scene = nil
    }

    @MainActor func didEstablishConnection() {
        let scene = SCNScene()

        let camera = SCNCamera()
        camera.automaticallyAdjustsZRange = true

        let cameraNode = SCNNode()
        cameraNode.position.z = 2.5
        cameraNode.camera = camera

        scene.rootNode.addChildNode(cameraNode)
        self.sceneView.scene = scene
    }

    func receive(command: RPC) {
        switch command {
            case .gridDefined:
                Task { @MainActor in
                    self.spawnGridAsTenant()
                }
            case let .placedActor(position):
                Task { @MainActor in
                    self.placeOpponent(at: position)
                }
            case .connected:
                self.broadcastDelegate?.sessionDidConnect()
            default:
                break
        }
    }
}
#endif
