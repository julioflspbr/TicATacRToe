//
//  SceneController+Simulator.swift
//  TicATacRToe
//
//  Created by Júlio César Flores on 04/01/23.
//

#if targetEnvironment(simulator)
import SceneKit

@MainActor final class SceneController: GameControllerSceneDelegate {
    enum Error: Swift.Error {
        case gridNotDefined
    }

    let scene: SCNScene

    weak var gameDelegate: SceneControllerGameDelegate?
    weak var sceneView: SCNView?

    private var grid: Grid?

    init() {
        self.scene = SCNScene()

        let camera = SCNCamera()
        camera.automaticallyAdjustsZRange = true

        let cameraNode = SCNNode()
        cameraNode.position.z = 2.5
        cameraNode.camera = camera
        self.scene.rootNode.addChildNode(cameraNode)
    }

    func defineGridPosition() throws {
        guard let grid else {
            throw Error.gridNotDefined
        }
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

                    print("Moving grid at: \(positionDefined)")
                    self.gameDelegate?.didMoveGrid(by: positionDefined)
                } else {
                    print("Grid defined at: \(positionDefined)")
                    self.gameDelegate?.didDefineGridPosition(at: positionDefined)

                    // but it is the simulator, we only want the grid visible on the screen
                    self.scene.rootNode.addChildNode(grid)
                }
            }
        }
    }

    func deleteAllGrids() {
        self.grid?.removeFromParentNode()
        self.grid = nil
    }

    func makeNewGrid() {
        self.grid?.removeFromParentNode()
        let grid = Grid()
        self.grid = grid
    }

    func moveGrid(by position: SIMD3<Float>) throws {
        guard let grid else {
            throw Error.gridNotDefined
        }

        // nothing to do on simulator, except throwing the appropriate error if necessary
        print("Moving grid at: \(position)")

        // but it is the simulator, we only want the grid visible on the screen
        self.scene.rootNode.addChildNode(grid)
    }

    func queryPlace(for place: Place.Position) throws -> Place {
        guard let grid else {
            throw Error.gridNotDefined
        }

        switch place {
            case .topLeft:
                return grid.topLeftPlaceNode
            case .top:
                return grid.topPlaceNode
            case .topRight:
                return grid.topRightPlaceNode
            case .left:
                return grid.leftPlaceNode
            case .centre:
                return grid.centrePlaceNode
            case .right:
                return grid.rightPlaceNode
            case .bottomLeft:
                return grid.bottomLeftPlaceNode
            case .bottom:
                return grid.bottomPlaceNode
            case .bottomRight:
                return grid.bottomRightPlaceNode
        }
    }

    func queryPlace(at point: CGPoint) -> Place? {
        let hitTestResults = self.sceneView?.hitTest(point)
        let results = hitTestResults?.compactMap({ $0.node.parent as? Place })
        return results?.first
    }

    func strikeThrough(_ type: StrikeThrough.StrikeType) {
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

        self.grid?.addChildNode(strikeThrough)
    }
}
#endif
