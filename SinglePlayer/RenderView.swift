//
//  RenderView.swift
//  TicATacRToe-SP
//
//  Created by Julio Flores on 17/01/2023.
//

import ARKit
import RealityKit
import SwiftUI

struct RenderView: UIViewRepresentable {
    let deltaDistance: CGFloat
    let deltaScale: CGFloat

    @Binding var defineGrid: (() -> Void)?
    @Binding var isGridDefined: Bool
    @Binding var tapPoint: CGPoint?

    @EnvironmentObject private var gameController: GameController

    func makeUIView(context: Context) -> UIView {
        let configuration = ARWorldTrackingConfiguration()
        configuration.environmentTexturing = .automatic
        configuration.isCollaborationEnabled = true

        let arView = ARView(frame: .zero)
        arView.session.run(configuration)

        context.coordinator.arView = arView
        context.coordinator.makeNewGrid()

        Task {
            self.defineGrid = { self.defineGridPosition(coordinator: context.coordinator) }
        }

        return arView
    }

    func updateUIView(_: UIView, context: Context) {
        if let tapPoint {
            Task {
                self.tapPoint = nil
                if self.isGridDefined {
                    context.coordinator.handleTap(at: tapPoint)
                }
            }
        }
        context.coordinator.adjustGrid(distance: Float(self.deltaDistance), scale: Float(self.deltaScale))
    }

    static func dismantleUIView(_: UIView, coordinator: SceneController) {
        coordinator.renderDelegate = nil
    }

    func makeCoordinator() -> SceneController {
        let sceneController = SceneController()
        sceneController.renderDelegate = self
        sceneController.gameDelegate = self.gameController
        self.gameController.sceneDelegate = sceneController

        return sceneController
    }

    private func defineGridPosition(coordinator: SceneController) {
        Task {
            do {
                try coordinator.defineGridPosition()
            } catch {
                assertionFailure(error.localizedDescription)
            }
        }
    }
}

extension RenderView: SceneControllerRenderDelegate {
    @MainActor func didChangeGridStatus(isDefined: Bool) {
        self.isGridDefined = isDefined
    }
}
