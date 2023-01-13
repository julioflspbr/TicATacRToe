//
//  Place+Common.swift
//  TicATacRToe
//
//  Created by Julio Flores on 10/01/2023.
//

import RealityKit

extension Place  {
    enum Position: String, Hashable, Codable {
        case topLeft, top, topRight, left, centre, right, bottomLeft, bottom, bottomRight
    }

    struct PositionComponent: Codable, Component {
        let position: Place.Position
        var isFilled: Bool
    }
}
