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
    let isActive: Bool

    @Binding var isGridDefined: Bool
    @Binding var tapPoint: CGPoint?

    @State private var isSceneRunning = false
    @State private var isGridDefinitionMethodTriggered = false

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
        if self.isActive {
            do {
                if !self.isSceneRunning {
                    Task {
                        self.isSceneRunning = true
                        context.coordinator.start()

                        // TODO: temp code please remove
                        context.coordinator.makeNewGrid()
                    }
                }
                if let tapPoint {
                    if self.isGridDefined {
                        try context.coordinator.handleTap(at: tapPoint)
                    }
                    Task {
                        self.tapPoint = nil
                    }
                }
                if self.isGridDefined && !self.isGridDefinitionMethodTriggered {
                    try context.coordinator.defineGridPosition()
                    Task { @MainActor in
                        self.isGridDefinitionMethodTriggered = true
                    }
                }
                context.coordinator.adjustGrid(distance: Float(self.deltaDistance), scale: Float(self.deltaScale))
            } catch {
                self.interruptionController.handleError(error)
            }
        } else {
            Task {
                context.coordinator.pause()
                self.isSceneRunning = false
            }
        }
    }
#endif

    func makeCoordinator() -> SceneController {
        let sceneController = SceneController()
//        self.gameController.sceneDelegate = sceneController
//        sceneController.gameDelegate = self.gameController
        return sceneController
    }
}

extension RenderView: SceneControllerRenderDelegate {
    @MainActor func didChangeGridStatus(isDefined: Bool) {
        self.isGridDefined = isDefined
        self.isGridDefinitionMethodTriggered = isDefined
    }
}
