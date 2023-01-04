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

#if targetEnvironment(simulator)
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
#endif

    func makeCoordinator() -> SceneController {
        let sceneController = SceneController()
        self.gameController.sceneDelegate = sceneController
        sceneController.gameDelegate = self.gameController
        return sceneController
    }
}
