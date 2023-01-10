//
//  StrikeThrough+Simulator.swift
//  TicATacRToe
//
//  Created by Júlio César Flores on 25/12/2022.
//

#if targetEnvironment(simulator)
import SceneKit

final class StrikeThrough: SCNNode {
    init(type: StrikeType, colour: Actor.Colour) {
        super.init()

        let material = SCNMaterial()
        material.diffuse.contents = colour.materialColour

        let stripe = SCNBox(width: 1.05, height: 0.02, length: 0.1, chamferRadius: 0.0)
        stripe.materials = [material]
        
        let template = SCNNode(geometry: stripe)

        switch type {
            case .horizontal:
                self.addChildNode(template)
            case .vertical:
                template.rotation = SCNVector4(0.0, 0.0, 1.0, .pi / 2)
                self.addChildNode(template)
            case let .diagonal(type):
                template.scale.x = sqrtf(2)
                switch type {
                    case .leftTop:
                        template.rotation = SCNVector4(0.0, 0.0, 1.0, .pi * 0.75)
                    case .rightTop:
                        template.rotation = SCNVector4(0.0, 0.0, 1.0, .pi * 0.25)
                }
                self.addChildNode(template)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
#endif
