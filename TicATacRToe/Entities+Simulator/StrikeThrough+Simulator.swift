//
//  StrikeThrough+Simulator.swift
//  TicATacRToe
//
//  Created by Júlio César Flores on 25/12/2022.
//

#if targetEnvironment(simulator)
import SceneKit

@MainActor final class StrikeThrough: SCNNode {
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


    init(type: StrikeType) {
        super.init()

        let stripe = SCNBox(width: 1.05, height: 0.02, length: 0.1, chamferRadius: 0.0)
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
