//
//  SceneController.swift
//  TicATacRToe
//
//  Created by Julio Flores on 09/01/2023.
//

import Foundation

#if targetEnvironment(simulator)
import SceneKit
#else
import RealityKit
#endif

protocol SceneController: GameControllerSceneDelegate, BroadcastControllerSceneDelegate {
    var broadcastDelegate: SceneControllerBroadcastDelegate? { get set }
    var gameDelegate: SceneControllerGameDelegate? { get set }
    var interruptionDelegate: SceneControllerInterruptionDelegate? { get set }
    var renderDelegate: SceneControllerRenderDelegate? { get set }

#if targetEnvironment(simulator)
    var sceneView: SCNView! { get set }
#else
    var arView: ARView! { get set }
#endif

    @MainActor func adjustGrid(distance: Float, scale: Float)
    @MainActor func defineGridPosition() throws
    @MainActor func handleTap(at point: CGPoint)

}
