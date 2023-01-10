//
//  Grid+Device.swift
//  TicATacRToe
//
//  Created by Julio Flores on 07/01/2023.
//

#if !targetEnvironment(simulator)
import RealityKit

final class Grid: Entity {
    let topLeftPlace = Place(at: .topLeft)
    let topPlace = Place(at: .top)
    let topRightPlace = Place(at: .topRight)
    let leftPlace = Place(at: .left)
    let centrePlace = Place(at: .centre)
    let rightPlace = Place(at: .right)
    let bottomLeftPlace = Place(at: .bottomLeft)
    let bottomPlace = Place(at: .bottom)
    let bottomRightPlace = Place(at: .bottomRight)

    private var grid: Entity

    required init() {
        self.grid = Entity()
        super.init()
        self.addChild(self.grid)
        self.makeGrid(colour: .white)
        self.makePlaces()
    }

    func findPlace(at position: Place.Position) -> Place? {
        self.findEntity(named: position.rawValue) as? Place
    }
    
    func paintGrid(with colour: Actor.Colour) {
        self.grid.removeFromParent()
        self.grid = Entity()
        self.addChild(self.grid)
        self.makeGrid(colour: colour.materialColour)
    }

    private func makeGrid(colour: Material.Color) {
        let stripeThickness: Float = 0.02
        let stripeLength: Float = 1.0
        let stripePosition: Float = 0.17

        let verticalStripeMesh = MeshResource.generatePlane(width: stripeThickness, height: stripeLength)
        let horizontalStripeMesh = MeshResource.generatePlane(width: stripeLength, height: stripeThickness)
        let gridMaterial = UnlitMaterial(color: colour)

        // top stripe
        let topStripe = ModelEntity(mesh: horizontalStripeMesh, materials: [gridMaterial])
        topStripe.position.y = stripePosition
        self.grid.addChild(topStripe)

        // left stripe
        let leftStripe = ModelEntity(mesh: verticalStripeMesh, materials: [gridMaterial])
        leftStripe.position.x = -stripePosition
        self.grid.addChild(leftStripe)

        // right stripe
        let rightStripe = ModelEntity(mesh: verticalStripeMesh, materials: [gridMaterial])
        rightStripe.position.x = stripePosition
        self.grid.addChild(rightStripe)

        // bottom stripe
        let bottomStripe = ModelEntity(mesh: horizontalStripeMesh, materials: [gridMaterial])
        bottomStripe.position.y = -stripePosition
        self.grid.addChild(bottomStripe)
    }

    private func makePlaces() {
        let position: Float = 0.34

        // top left placement
        self.topLeftPlace.position = [-position, position, 0.0]
        self.addChild(self.topLeftPlace)

        // top placement
        self.topPlace.position = [0.0, position, 0.0]
        self.addChild(self.topPlace)

        // top right placement
        self.topRightPlace.position = [position, position, 0.0]
        self.addChild(self.topRightPlace)

        // left placement
        self.leftPlace.position = [-position, 0.0, 0.0]
        self.addChild(self.leftPlace)

        // centre placement
        self.centrePlace.position = [0.0, 0.0, 0.0]
        self.addChild(self.centrePlace)

        // right placement
        self.rightPlace.position = [position, 0.0, 0.0]
        self.addChild(self.rightPlace)

        // bottom peft placement
        self.bottomLeftPlace.position = [-position, -position, 0.0]
        self.addChild(self.bottomLeftPlace)

        // bottom placement
        self.bottomPlace.position = [0.0, -position, 0.0]
        self.addChild(self.bottomPlace)

        // bottom right placement
        self.bottomRightPlace.position = [position, -position, 0.0]
        self.addChild(self.bottomRightPlace)
    }
}
#endif
