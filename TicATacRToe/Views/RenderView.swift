//
//  RenderView.swift
//  TicATacRToe
//
//  Created by Julio Flores on 14/12/2022.
//

import SceneKit
import SwiftUI

struct RenderView: UIViewRepresentable {
    let scene: SCNScene
    @Binding private(set) var sceneController: SceneController?

    func makeUIView(context: Context) -> SCNView {
        let sceneView = SCNView(frame: .zero, options: nil)
        sceneView.scene = self.scene
        sceneView.backgroundColor = .black
        sceneView.autoenablesDefaultLighting = true
        sceneView.allowsCameraControl = false
        context.coordinator.sceneView = sceneView
        return sceneView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        // nothing at the moment
    }

    func makeCoordinator() -> SceneController {
        let sceneController = SceneController()
        self.sceneController = sceneController
        return sceneController
    }
}

final class SceneController {
    fileprivate var sceneView: SCNView?

    func queryPlaceNode(at point: CGPoint) -> Place? {
        let hitTestResults = self.sceneView?.hitTest(point)
        let results = hitTestResults?.compactMap({ $0.node.parent as? Place })
        return results?.first
    }
}
