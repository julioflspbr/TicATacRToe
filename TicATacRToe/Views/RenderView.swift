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
        if let tapPoint {
            Task {
                self.tapPoint = nil
                if self.isGridDefined {
                    context.coordinator.handleTap(at: tapPoint)
                }
            }
        }
        if self.isGridDefined && !self.isGridDefinitionMethodTriggered {
            Task {
                self.isGridDefinitionMethodTriggered = true
                do {
                    try context.coordinator.defineGridPosition()
                } catch {
                    self.interruptionController.handleError(error)
                }
            }
        }
        context.coordinator.adjustGrid(distance: Float(self.deltaDistance), scale: Float(self.deltaScale))
    }

    static func dismantleUIView(_: UIView, coordinator: SceneCoordinator) {
        coordinator.clearRenderDelegate()
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

@MainActor final class SceneCoordinator {
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

    func clearRenderDelegate() {
        self.sceneController?.renderDelegate = nil
        self.renderDelegate = nil
    }

    func defineGridPosition() throws {
        try self.sceneController?.defineGridPosition()
    }

    func handleTap(at point: CGPoint) {
        self.sceneController?.handleTap(at: point)
    }

    func receive(command: RPC) {
        if case let .connected(type) = command {
            self.defineOpponentDevice(type: type)
        }
        self.sceneController?.receive(command: command)
    }

    private func defineOpponentDevice(type: RPC.DeviceType) {
        self.sceneController?.renderDelegate = nil
#if targetEnvironment(simulator)
        self.sceneController = SimulatorSceneController()
        self.sceneController?.sceneView = self.sceneView
#else
        switch type {
            case .simulator:
                self.sceneController = HybridSceneController()
            case .device:
                self.sceneController = DeviceSceneController()
        }
        self.sceneController?.arView = self.arView
#endif
        self.sceneController?.renderDelegate = self.renderDelegate
        self.sceneController?.broadcastDelegate = self.broadcastDelegate
        self.sceneController?.gameDelegate = self.gameDelegate
        self.sceneController?.interruptionDelegate = self.interruptionDelegate
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
    var device: RPC.DeviceType {
#if targetEnvironment(simulator)
        .simulator
#else
        .device
#endif
    }

    func didBreakConnection() {
        self.sceneController?.didBreakConnection()
    }

    func didEstablishConnection() {
        self.sceneController?.didEstablishConnection()
    }
}
