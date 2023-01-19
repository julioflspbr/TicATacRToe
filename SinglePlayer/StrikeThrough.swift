//
//  StrikeThrough.swift
//  TicATacRToe-SP
//
//  Created by Julio Flores on 17/01/2023.
//

import Foundation

enum StrikeThrough {
    enum VerticalPosition {
        case left
        case centre
        case right
    }

    enum HorizontalPosition {
        case top
        case centre
        case bottom
    }

    enum DiagonalType {
        case leftTop
        case rightTop
    }

    enum StrikeType {
        case horizontal(HorizontalPosition)
        case vertical(VerticalPosition)
        case diagonal(DiagonalType)
    }
}
