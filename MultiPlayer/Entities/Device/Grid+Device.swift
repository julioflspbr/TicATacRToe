//
//  Grid+Device.swift
//  TicATacRToe
//
//  Created by Julio Flores on 07/01/2023.
//

#if !targetEnvironment(simulator)
import RealityKit

final class Grid: Entity {
    func findPlace(at position: Place.Position) -> Place? {
        self.findEntity(named: position.rawValue) as? Place
    }

    func makeDefaultGrid() {
        self.makeGrid()
        self.makePlaces()
    }
    
    func paintGrid(with colour: Actor.Colour) {
        let gridMaterial = UnlitMaterial(color: colour.materialColour)
        for stripe in self.children {
            if let stripeEntity = stripe as? ModelEntity {
                stripeEntity.model?.materials = [gridMaterial]
            }
        }
    }

    private func makeGrid() {
        let stripeThickness: Float = 0.02
        let stripeLength: Float = 1.0
        let stripePosition: Float = 0.17

        let verticalStripeMesh = MeshResource.generatePlane(width: stripeThickness, height: stripeLength)
        let horizontalStripeMesh = MeshResource.generatePlane(width: stripeLength, height: stripeThickness)
        let gridMaterial = UnlitMaterial(color: .white)

        // top stripe
        let topStripe = ModelEntity(mesh: horizontalStripeMesh, materials: [gridMaterial])
        topStripe.position.y = stripePosition
        self.addChild(topStripe)

        // left stripe
        let leftStripe = ModelEntity(mesh: verticalStripeMesh, materials: [gridMaterial])
        leftStripe.position.x = -stripePosition
        self.addChild(leftStripe)

        // right stripe
        let rightStripe = ModelEntity(mesh: verticalStripeMesh, materials: [gridMaterial])
        rightStripe.position.x = stripePosition
        self.addChild(rightStripe)

        // bottom stripe
        let bottomStripe = ModelEntity(mesh: horizontalStripeMesh, materials: [gridMaterial])
        bottomStripe.position.y = -stripePosition
        self.addChild(bottomStripe)
    }

    private func makePlaces() {
        let position: Float = 0.34

        // top left placement
        let topLeftPlace = Place(at: .topLeft)
        topLeftPlace.position = [-position, position, 0.0]
        self.addChild(topLeftPlace)

        // top placement
        let topPlace = Place(at: .top)
        topPlace.position = [0.0, position, 0.0]
        self.addChild(topPlace)

        // top right placement
        let topRightPlace = Place(at: .topRight)
        topRightPlace.position = [position, position, 0.0]
        self.addChild(topRightPlace)

        // left placement
        let leftPlace = Place(at: .left)
        leftPlace.position = [-position, 0.0, 0.0]
        self.addChild(leftPlace)

        // centre placement
        let centrePlace = Place(at: .centre)
        centrePlace.position = [0.0, 0.0, 0.0]
        self.addChild(centrePlace)

        // right placement
        let rightPlace = Place(at: .right)
        rightPlace.position = [position, 0.0, 0.0]
        self.addChild(rightPlace)

        // bottom peft placement
        let bottomLeftPlace = Place(at: .bottomLeft)
        bottomLeftPlace.position = [-position, -position, 0.0]
        self.addChild(bottomLeftPlace)

        // bottom placement
        let bottomPlace = Place(at: .bottom)
        bottomPlace.position = [0.0, -position, 0.0]
        self.addChild(bottomPlace)

        // bottom right placement
        let bottomRightPlace = Place(at: .bottomRight)
        bottomRightPlace.position = [position, -position, 0.0]
        self.addChild(bottomRightPlace)
    }
}
#endif
