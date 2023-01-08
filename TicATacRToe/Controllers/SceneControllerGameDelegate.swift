//
//  SceneControllerGameDelegate.swift
//  TicATacRToe
//
//  Created by Julio Flores on 07/01/2023.
//

import Foundation

protocol SceneControllerGameDelegate: AnyObject {
    func didMoveGrid(by: SIMD3<Float>)
    func didDefineGridPosition(at: SIMD3<Float>)
}
