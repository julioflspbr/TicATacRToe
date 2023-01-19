//
//  Actor+Device.swift
//  TicATacRToe
//
//  Created by Julio Flores on 07/01/2023.
//

#if !targetEnvironment(simulator)
import RealityKit

final class Actor: Entity {
    init(avatar: Avatar, colour: Colour) {
        super.init()

        let characterMesh = MeshResource.generateText(avatar.rawValue, extrusionDepth: 1.0)
        let characterMaterial = SimpleMaterial(color: colour.materialColour, isMetallic: false)
        let characterEntity = ModelEntity(mesh: characterMesh, materials: [characterMaterial])

        self.addChild(characterEntity)

        characterEntity.position = avatar.position
        characterEntity.scale = avatar.scale
    }

    required init() {
        super.init()
    }
}

extension Actor.Colour {
    var materialColour: Material.Color {
        switch self {
            case .red:
                return .red
            case .blue:
                return .blue
        }
    }
}

fileprivate extension Actor.Avatar {
    var position: SIMD3<Float> {
        switch self {
            case .cross:
                return [-0.16, -0.22, 0.0]
            case .circle:
                return [-0.155, -0.155, 0.0]
        }
    }

    var scale: SIMD3<Float> {
        switch self {
            case .cross:
                return [0.03, 0.03, 0.02]
            case .circle:
                return [0.022, 0.022, 0.01]
        }
    }
}
#endif
