//
//  Grid.swift
//  TicATacRToe
//
//  Created by Júlio César Flores on 25/12/2022.
//

import SceneKit

final class Grid: SCNNode {
    let topLeftPlaceNode = Place(.topLeft)
    let topPlaceNode = Place(.top)
    let topRightPlaceNode = Place(.topRight)
    let leftPlaceNode = Place(.left)
    let centrePlaceNode = Place(.centre)
    let rightPlaceNode = Place(.right)
    let bottomLeftPlaceNode = Place(.bottomLeft)
    let bottomPlaceNode = Place(.bottom)
    let bottomRightPlaceNode = Place(.bottomRight)

    override init() {
        super.init()

        let placePosition: Float = 0.34

        // top left placement
        self.topLeftPlaceNode.position = SCNVector3(x: -placePosition, y: placePosition, z: 0)
        self.addChildNode(self.topLeftPlaceNode)

        // top placement
        self.topPlaceNode.position = SCNVector3(x: 0, y: placePosition, z: 0)
        self.addChildNode(self.topPlaceNode)

        // top right placement
        self.topRightPlaceNode.position = SCNVector3(x: placePosition, y: placePosition, z: 0)
        self.addChildNode(self.topRightPlaceNode)

        // left placement
        self.leftPlaceNode.position = SCNVector3(x: -placePosition, y: 0, z: 0)
        self.addChildNode(self.leftPlaceNode)

        // centre placement
        self.centrePlaceNode.position = SCNVector3(x: 0, y: 0, z: 0)
        self.addChildNode(self.centrePlaceNode)

        // right placement
        self.rightPlaceNode.position = SCNVector3(x: placePosition, y: 0, z: 0)
        self.addChildNode(self.rightPlaceNode)

        // bottom left placement
        self.bottomLeftPlaceNode.position = SCNVector3(x: -placePosition, y: -placePosition, z: 0)
        self.addChildNode(self.bottomLeftPlaceNode)

        // bottom placement
        self.bottomPlaceNode.position = SCNVector3(x: 0, y: -placePosition, z: 0)
        self.addChildNode(self.bottomPlaceNode)

        // bottom right placement
        self.bottomRightPlaceNode.position = SCNVector3(x: placePosition, y: -placePosition, z: 0)
        self.addChildNode(self.bottomRightPlaceNode)

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
