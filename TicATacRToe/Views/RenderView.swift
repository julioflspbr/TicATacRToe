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
    func makeUIView(context: Context) -> UIView {
        let sceneView = SCNView(frame: .zero, options: nil)
        context.coordinator.sceneView = sceneView

        sceneView.scene = context.coordinator.scene
        sceneView.backgroundColor = .black
        sceneView.autoenablesDefaultLighting = true
        sceneView.allowsCameraControl = false

        return sceneView
    }
#else
    func makeUIView(context: Context) -> UIView {
        let arView = ARView(frame: .zero)
        context.coordinator.arView = arView
        return arView
    }
#endif

    func updateUIView(_: UIView, context: Context) {
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

    static func dismantleUIView(_: UIView, coordinator: SceneCoordinator) {
        coordinator.renderDelegate = nil
    }

    func makeCoordinator() -> SceneCoordinator {
        let sceneController = SceneCoordinator()
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

final class SceneCoordinator {
    var renderDelegate: SceneControllerRenderDelegate?

#if targetEnvironment(simulator)
    var sceneView: SCNView?
#else
    var arView: ARView?
#endif

    weak var broadcastDelegate: SceneControllerBroadcastDelegate?
    weak var gameDelegate: SceneControllerGameDelegate?
    weak var interruptionDelegate: SceneControllerInterruptionDelegate?

    private var sceneController: SceneController?

    func adjustGrid(distance: Float, scale: Float) {
        self.sceneController?.adjustGrid(distance: distance, scale: scale)
    }

    func defineGridPosition() throws {
        try self.sceneController?.defineGridPosition()
    }

    func handleTap(at point: CGPoint) throws {
        try self.sceneController?.handleTap(at: point)
    }

    func receive(command: RPC) {
        self.sceneController?.receive(command: command)

        if case let .opponentDevice(type) = command {
            self.defineOpponentDevice(type: type)
        }
    }

    private func defineOpponentDevice(type: RPC.DeviceType) {
#if targetEnvironment(simulator)
        self.sceneController = SimulatorSceneController()
#else
        switch type {
            case .simulator:
                self.sceneController = HybridSceneController()
            case .device:
                self.sceneController = DeviceSceneController()
        }
#endif
    }
}

extension SceneCoordinator: GameControllerSceneDelegate {
    func deleteAllGrids() {
        self.sceneController?.deleteAllGrids()
    }

    func makeNewGrid() {
        self.sceneController?.makeNewGrid()
    }

    func paintGrid(with colour: Actor.Colour) throws {
        try self.sceneController?.paintGrid(with: colour)
    }

    func strikeThrough(_ type: StrikeThrough.StrikeType, colour: Actor.Colour) throws {
        try self.sceneController?.strikeThrough(type, colour: colour)
    }
}

extension SceneCoordinator: BroadcastControllerSceneDelegate {
    func didBreakConnection() {
        self.sceneController?.didBreakConnection()
    }

    func didEstablishConnection() {
        self.sceneController?.didEstablishConnection()
    }
}
