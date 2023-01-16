//
//  Place+Simulator.swift
//  TicATacRToe
//
//  Created by Júlio César Flores on 22/12/22.
//

#if targetEnvironment(simulator)
import SceneKit

final class Place: SCNNode {
    let placePosition: Position

    private var isFilled = false

    init(_ placePosition: Position) {
        self.placePosition = placePosition
        super.init()
        self.name = placePosition.rawValue

        // tap area
        let translucentMaterial = SCNMaterial()
        translucentMaterial.diffuse.intensity = 0.0

        let square = SCNPlane(width: 0.3, height: 0.3)
        square.materials = [translucentMaterial]
        let squareNode = SCNNode(geometry: square)
        self.addChildNode(squareNode)
    }

    func fill(with avatar: Actor.Avatar, colour: Actor.Colour) {
        guard !self.isFilled else {
            return
        }
        let actor = Actor(avatar: avatar, colour: colour)
        self.addChildNode(actor)
        self.isFilled = true
    }

    required init?(coder: NSCoder) {
        fatalError("Please don't decode. Bad idea.")
    }
}
#endif
