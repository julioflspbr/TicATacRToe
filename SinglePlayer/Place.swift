//
//  Place.swift
//  TicATacRToe-SP
//
//  Created by Julio Flores on 17/01/2023.
//

import Foundation

enum Place {
    enum Position: String, Hashable, Codable {
        case topLeft, top, topRight, left, centre, right, bottomLeft, bottom, bottomRight
    }
}
