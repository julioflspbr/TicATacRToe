//
//  StrikeThrough+Common.swift
//  TicATacRToe
//
//  Created by Julio Flores on 10/01/2023.
//

import Foundation

extension StrikeThrough {
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
