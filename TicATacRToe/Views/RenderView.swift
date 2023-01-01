//
//  RenderView.swift
//  TicATacRToe
//
//  Created by Julio Flores on 14/12/2022.
//

import SceneKit
import SwiftUI

struct RenderView: UIViewRepresentable {
    @EnvironmentObject private var gameController: GameController

    func makeUIView(context: Context) -> SCNView {
        let sceneView = SCNView(frame: .zero, options: nil)
        context.coordinator.sceneView = sceneView

        sceneView.scene = context.coordinator.scene
        sceneView.backgroundColor = .black
        sceneView.autoenablesDefaultLighting = true
        sceneView.allowsCameraControl = false

        return sceneView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        // nothing at the moment
    }

    func makeCoordinator() -> SceneController {
        let sceneController = SceneController()
        self.gameController.sceneDelegate = sceneController
        return sceneController
    }
}

@MainActor final class SceneController: GameControllerSceneDelegate {
    enum Error: Swift.Error {
        case gridNotDefined
    }

    weak var sceneView: SCNView?

    let scene: SCNScene

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

    func defineGrid(at: SIMD3<Float>) throws {
        // disregard *position* on simulator
        guard let grid else {
            throw Error.gridNotDefined
        }
        self.scene.rootNode.addChildNode(grid)
    }

    func makeNewGrid() {
        self.grid?.removeFromParentNode()
        let grid = Grid()
        self.grid = grid
    }

    func place(for place: Place.Position) throws -> Place {
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
