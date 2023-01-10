//
//  Place+Common.swift
//  TicATacRToe
//
//  Created by Julio Flores on 10/01/2023.
//

import Foundation

extension Place  {
    enum Position: String, Hashable {
        case topLeft, top, topRight, left, centre, right, bottomLeft, bottom, bottomRight
    }
}
