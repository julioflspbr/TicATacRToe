//
//  Actor+Simulator.swift
//  TicATacRToe
//
//  Created by Júlio César Flores on 25/12/2022.
//

#if targetEnvironment(simulator)
import SceneKit

final class Actor: SCNNode {
    init(avatar: Avatar, colour: Colour) {
        super.init()

        let characterMaterial = SCNMaterial()
        characterMaterial.diffuse.contents = colour.materialColour

        let characterModel = SCNText(string: avatar.rawValue, extrusionDepth: 1)
        characterModel.flatness = 0
        characterModel.materials = [characterMaterial]
        
        let node = SCNNode(geometry: characterModel)
        self.addChildNode(node)

        self.position = avatar.position
        self.scale = avatar.scale
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension Actor.Colour {
    var materialColour: UIColor {
        switch self {
            case .red:
                return .red
            case .blue:
                return .blue
        }
    }
}

fileprivate extension Actor.Avatar {
    var position: SCNVector3 {
        switch self {
            case .cross:
                return SCNVector3(x: -0.16, y: -0.25, z: 0.0)
            case .circle:
                return SCNVector3(x: -0.15, y: -0.16, z: 0.0)
        }
    }

    var scale: SCNVector3 {
        switch self {
            case .cross:
                return SCNVector3(SIMD3(repeating: 0.035))
            case .circle:
                return SCNVector3(SIMD3(repeating: 0.025))
        }
    }
}
#endif
