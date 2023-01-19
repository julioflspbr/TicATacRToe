//
//  Actor+Common.swift
//  TicATacRToe
//
//  Created by Julio Flores on 10/01/2023.
//

import Foundation

extension Actor {
    enum Avatar: String, Hashable {
        case cross = "✕"
        case circle = "◯"
    }

    enum Colour {
        case red
        case blue
    }
}

extension Actor.Avatar {
    var opposite: Self {
        switch self {
            case .circle:
                return .cross
            case .cross:
                return .circle
        }
    }
}

extension Actor.Colour {
    var opposite: Self {
        switch self {
            case .red:
                return .blue
            case .blue:
                return .red
        }
    }
}
