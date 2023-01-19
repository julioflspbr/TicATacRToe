//
//  StrikeThrough.swift
//  TicATacRToe-SP
//
//  Created by Julio Flores on 17/01/2023.
//

import RealityKit

final class StrikeThrough: Entity {
    enum VerticalPosition {
        case left
        case centre
        case right
    }

    enum HorizontalPosition {
        case top
        case centre
        case bottom
    }

    enum DiagonalType {
        case leftTop
        case rightTop
    }

    enum StrikeType {
        case horizontal(HorizontalPosition)
        case vertical(VerticalPosition)
        case diagonal(DiagonalType)
    }

    init(type: StrikeType, colour: Actor.Colour) {
        super.init()

        let stripeMesh = MeshResource.generateBox(width: 1.05, height: 0.02, depth: 0.03)
        let stripeMaterial = SimpleMaterial(color: colour.materialColour, isMetallic: false)
        let stripeModel = ModelEntity(mesh: stripeMesh, materials: [stripeMaterial])

        switch type {
            case .horizontal:
                self.addChild(stripeModel)
            case .vertical:
                stripeModel.orientation = simd_quatf(angle: .pi / 2, axis: [0.0, 0.0, 1.0])
                self.addChild(stripeModel)
            case let .diagonal(type):
                stripeModel.scale.x = sqrtf(2)
                switch type {
                    case .leftTop:
                        stripeModel.orientation = simd_quatf(angle: .pi * 0.75, axis: [0.0, 0.0, 1.0])
                    case .rightTop:
                        stripeModel.orientation = simd_quatf(angle: .pi * 0.25, axis: [0.0, 0.0, 1.0])
                }
                self.addChild(stripeModel)
        }
    }

    required init() {
        super.init()
    }
}
