//
//  FloatingPoint+Fenced.swift
//  TicATacRToe
//
//  Created by Julio Flores on 09/01/2023.
//

import Foundation

extension FloatingPoint {
    func fenced(min: Self, max: Self) -> Self {
        Self.minimum(Self.maximum(self, min), max)
    }
}
