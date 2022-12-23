//
//  Place.swift
//  TicATacRToe
//
//  Created by Júlio César Flores on 22/12/22.
//

import SceneKit

final class Place: SCNNode {
    enum Position: Hashable {
        case topLeft, top, topRight, left, centre, right, bottomLeft, bottom, bottomRight
    }

    enum Error: Swift.Error {
        case placeAlreadyTaken(Position)
    }

    let place: Position

    private let crossTemplate: SCNNode
    private let circleTemplate: SCNNode
    private var isFilled = false

    init(_ place: Position) {
        self.place = place

        // actor material
        let whiteMaterial = SCNMaterial()
        whiteMaterial.diffuse.contents = UIColor.white

        // cross actor
        let crossGeometry = SCNText(string: Actor.Avatar.cross.rawValue, extrusionDepth: 0.1)
        crossGeometry.font = .systemFont(ofSize: 1)
        crossGeometry.flatness = 0
        crossGeometry.materials = [whiteMaterial]

        self.crossTemplate = SCNNode(geometry: crossGeometry)
        self.crossTemplate.scale = SCNVector3(x: 0.4, y: 0.4, z: 0.4)
        self.crossTemplate.position = SCNVector3(x: -0.15, y: -0.54, z: 0)

        // circle actor
        let circleGeometry = SCNText(string: Actor.Avatar.circle.rawValue, extrusionDepth: 0.1)
        circleGeometry.font = .systemFont(ofSize: 0.75)
        circleGeometry.flatness = 0
        circleGeometry.materials = [whiteMaterial]

        self.circleTemplate = SCNNode(geometry: circleGeometry)
        self.circleTemplate.scale = SCNVector3(x: 0.4, y: 0.4, z: 0.4)
        self.circleTemplate.position = SCNVector3(x: -0.15, y: -0.52, z: 0)

        // tap area
        let translucentMaterial = SCNMaterial()
        translucentMaterial.diffuse.intensity = 0.0

        let square = SCNPlane(width: 0.3, height: 0.3)
        square.materials = [translucentMaterial]
        let squareNode = SCNNode(geometry: square)

        super.init()
        self.addChildNode(squareNode)
    }

    func fill(with actor: Actor.Avatar) throws {
        guard !isFilled else {
            throw Error.placeAlreadyTaken(self.place)
        }
        switch actor {
        case .cross:
            self.addChildNode(self.crossTemplate)
        case .circle:
            self.addChildNode(self.circleTemplate)
        }
        self.isFilled = true
    }

    required init?(coder: NSCoder) {
        fatalError("Please don't decode. Bad idea.")
    }
}
