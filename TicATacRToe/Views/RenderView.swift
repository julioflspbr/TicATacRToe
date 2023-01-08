//
//  RenderView.swift
//  TicATacRToe
//
//  Created by Julio Flores on 14/12/2022.
//

import SwiftUI

#if targetEnvironment(simulator)
import SceneKit
#else
import ARKit
import RealityKit
#endif

struct RenderView: UIViewRepresentable {
    let deltaDistance: CGFloat
    let deltaScale: CGFloat

    @Binding var isGridDefined: Bool
    @Binding var tapPoint: CGPoint?

    @State private var isGridDefinitionMethodTriggered = false

    @EnvironmentObject private var broadcastController: BroadcastController
    @EnvironmentObject private var gameController: GameController
    @EnvironmentObject private var interruptionController: InterruptionController

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
#else
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        context.coordinator.arView = arView
        return arView
    }

    func updateUIView(_ arView: ARView, context: Context) {
        do {
            if let tapPoint {
                Task {
                    self.tapPoint = nil
                }
                if self.isGridDefined {
                    try context.coordinator.handleTap(at: tapPoint)
                }
            }
            if self.isGridDefined && !self.isGridDefinitionMethodTriggered {
                Task {
                    self.isGridDefinitionMethodTriggered = true
                }
                try context.coordinator.defineGridPosition()
            }
            context.coordinator.adjustGrid(distance: Float(self.deltaDistance), scale: Float(self.deltaScale))
        } catch {
            self.interruptionController.handleError(error)
        }
    }

    static func dismantleUIView(_ uiView: ARView, coordinator: SceneController) {
        coordinator.renderDelegate = nil
    }
#endif

    func makeCoordinator() -> SceneController {
        let sceneController = SceneController()
        sceneController.renderDelegate = self
        sceneController.broadcastDelegate = self.broadcastController
        sceneController.gameDelegate = self.gameController
        sceneController.interruptionDelegate = self.interruptionController

        self.gameController.sceneDelegate = sceneController
        self.broadcastController.sceneDelegate = sceneController

        return sceneController
    }
}

extension RenderView: SceneControllerRenderDelegate {
    @MainActor func didChangeGridStatus(isDefined: Bool) {
        self.isGridDefined = isDefined
        self.isGridDefinitionMethodTriggered = isDefined
    }
}
