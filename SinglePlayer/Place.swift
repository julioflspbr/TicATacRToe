//
//  Place.swift
//  TicATacRToe-SP
//
//  Created by Julio Flores on 17/01/2023.
//

import Foundation

import RealityKit

final class Place: Entity {
    enum Position: String, Hashable, Codable {
        case topLeft, top, topRight, left, centre, right, bottomLeft, bottom, bottomRight
    }

    struct PositionComponent: Codable, Component {
        let position: Place.Position
        var isFilled: Bool
    }

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

    func fill(with avatar: Actor.Avatar) {
        guard !self.positionComponent.isFilled else {
            return
        }
        let actor = Actor(avatar: avatar)
        self.addChild(actor)

        var positionComponent = self.positionComponent
        positionComponent.isFilled = true
        self.components.set(positionComponent)
    }
}
