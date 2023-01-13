//
//  Place+Device.swift
//  TicATacRToe
//
//  Created by Julio Flores on 07/01/2023.
//

#if !targetEnvironment(simulator)
import RealityKit

final class Place: Entity {
    private var positionComponent: PositionComponent {
        self.components[PositionComponent.self] as! PositionComponent
    }

    var placePosition: Place.Position {
        return positionComponent.position
    }

    init(at position: Position) {
        super.init()
        self.name = position.rawValue

        let tapAreaShape = ShapeResource.generateBox(width: 0.3, height: 0.3, depth: 0.3)
        let tapComponent = CollisionComponent(shapes: [tapAreaShape])
        self.components.set(tapComponent)

        let placeComponent = PositionComponent(position: position, isFilled: false)
        self.components.set(placeComponent)
    }

    required init() {
        super.init()
    }

    func fill(with avatar: Actor.Avatar, colour: Actor.Colour) {
        guard !self.positionComponent.isFilled else {
            return
        }
        let actor = Actor(avatar: avatar, colour: colour)
        self.addChild(actor)

        var positionComponent = self.positionComponent
        positionComponent.isFilled = true
        self.components.set(positionComponent)
    }
}
#endif
