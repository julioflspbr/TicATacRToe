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

final class SceneController: GameControllerSceneDelegate {
    weak var sceneView: SCNView?

    let scene: SCNScene

    private let grid: Grid

    init() {
        self.scene = SCNScene()

        self.grid = Grid()
        self.scene.rootNode.addChildNode(self.grid)

        let camera = SCNCamera()
        camera.automaticallyAdjustsZRange = true

        let cameraNode = SCNNode()
        cameraNode.position.z = 2.5
        cameraNode.camera = camera
        self.scene.rootNode.addChildNode(cameraNode)
    }

    func place(for place: Place.Position) -> Place {
        switch place {
            case .topLeft:
                return self.grid.topLeftPlaceNode
            case .top:
                return self.grid.topPlaceNode
            case .topRight:
                return self.grid.topRightPlaceNode
            case .left:
                return self.grid.leftPlaceNode
            case .centre:
                return self.grid.centrePlaceNode
            case .right:
                return self.grid.rightPlaceNode
            case .bottomLeft:
                return self.grid.bottomLeftPlaceNode
            case .bottom:
                return self.grid.bottomPlaceNode
            case .bottomRight:
                return self.grid.bottomRightPlaceNode
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

        self.scene.rootNode.addChildNode(strikeThrough)
    }
}
