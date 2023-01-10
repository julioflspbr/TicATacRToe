//
//  Place+Device.swift
//  TicATacRToe
//
//  Created by Julio Flores on 07/01/2023.
//

#if !targetEnvironment(simulator)
import RealityKit

final class Place: Entity {
    let placePosition: Position

    private var isFilled = false

    init(at position: Position) {
        self.placePosition = position
        super.init()
        self.name = position.rawValue

        let tapAreaShape = ShapeResource.generateBox(width: 0.3, height: 0.3, depth: 0.3)
        let tapComponent = CollisionComponent(shapes: [tapAreaShape])
        self.components.set(tapComponent)
    }

    func fill(with avatar: Actor.Avatar, colour: Actor.Colour) {
        guard !self.isFilled else {
            return
        }
        let actor = Actor(avatar: avatar, colour: colour)
        self.addChild(actor)
        self.isFilled = true
    }

    required init() {
        fatalError("init() has not been implemented")
    }
}
#endif
