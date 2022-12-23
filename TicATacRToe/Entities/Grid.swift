//
//  Grid.swift
//  TicATacRToe
//
//  Created by Júlio César Flores on 25/12/2022.
//

import SceneKit

final class Grid: SCNNode {
    override init() {
        super.init()

        let placePosition: Float = 0.34

        // top left placement
        let topLeftPlaceNode = Place(.topLeft)
        topLeftPlaceNode.position = SCNVector3(x: -placePosition, y: placePosition, z: 0)
        self.addChildNode(topLeftPlaceNode)

        // top placement
        let topPlaceNode = Place(.top)
        topPlaceNode.position = SCNVector3(x: 0, y: placePosition, z: 0)
        self.addChildNode(topPlaceNode)

        // top right placement
        let topRightPlaceNode = Place(.topRight)
        topRightPlaceNode.position = SCNVector3(x: placePosition, y: placePosition, z: 0)
        self.addChildNode(topRightPlaceNode)

        // left placement
        let leftPlaceNode = Place(.left)
        leftPlaceNode.position = SCNVector3(x: -placePosition, y: 0, z: 0)
        self.addChildNode(leftPlaceNode)

        // centre placement
        let centrePlaceNode = Place(.centre)
        centrePlaceNode.position = SCNVector3(x: 0, y: 0, z: 0)
        self.addChildNode(centrePlaceNode)

        // right placement
        let rightPlaceNode = Place(.right)
        rightPlaceNode.position = SCNVector3(x: placePosition, y: 0, z: 0)
        self.addChildNode(rightPlaceNode)

        // bottom left placement
        let bottomLeftPlaceNode = Place(.bottomLeft)
        bottomLeftPlaceNode.position = SCNVector3(x: -placePosition, y: -placePosition, z: 0)
        self.addChildNode(bottomLeftPlaceNode)

        // bottom placement
        let bottomPlaceNode = Place(.bottom)
        bottomPlaceNode.position = SCNVector3(x: 0, y: -placePosition, z: 0)
        self.addChildNode(bottomPlaceNode)

        // bottom right placement
        let bottomRightPlaceNode = Place(.bottomRight)
        bottomRightPlaceNode.position = SCNVector3(x: placePosition, y: -placePosition, z: 0)
        self.addChildNode(bottomRightPlaceNode)

        let thickness: CGFloat = 0.02
        let length: CGFloat = 1.0
        let stripePosition: Float = 0.17

        let verticalGeometry = SCNPlane(width: thickness, height: length)
        let horizontalGeometry = SCNPlane(width: length, height: thickness)

        // left strip
        let leftStripe = SCNNode(geometry: verticalGeometry)
        leftStripe.position.x = -stripePosition
        self.addChildNode(leftStripe)

        // right strip
        let rightStripe = SCNNode(geometry: verticalGeometry)
        rightStripe.position.x = stripePosition
        self.addChildNode(rightStripe)

        // top strip
        let topStripe = SCNNode(geometry: horizontalGeometry)
        topStripe.position.y = stripePosition
        self.addChildNode(topStripe)

        // bottom strip
        let bottomStripe = SCNNode(geometry: horizontalGeometry)
        bottomStripe.position.y = -stripePosition
        self.addChildNode(bottomStripe)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
