//
//  Actor.swift
//  TicATacRToe-SP
//
//  Created by Julio Flores on 17/01/2023.
//

import RealityKit

final class Actor: Entity {
    enum Avatar: String, Hashable {
        case cross = "✕"
        case circle = "◯"
    }

    enum Colour {
        case red
        case blue
    }

    init(avatar: Avatar) {
        super.init()

        let characterMesh = MeshResource.generateText(avatar.rawValue, extrusionDepth: 1.0)
        let characterMaterial = SimpleMaterial(color: avatar.colour.materialColour, isMetallic: false)
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

extension Actor.Avatar {
    var colour: Actor.Colour {
        switch self {
            case .cross:
                return .red
            case .circle:
                return .blue
        }
    }

    var opposite: Self {
        switch self {
            case .circle:
                return .cross
            case .cross:
                return .circle
        }
    }
}

extension Actor.Colour {
    var opposite: Self {
        switch self {
            case .red:
                return .blue
            case .blue:
                return .red
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
