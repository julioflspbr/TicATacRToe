//
//  Actor.swift
//  TicATacRToe
//
//  Created by Júlio César Flores on 25/12/2022.
//

#if targetEnvironment(simulator)
import SceneKit

@MainActor final class Actor: SCNNode {
    enum Avatar: String, Hashable {
        case cross = "✕"
        case circle = "◯"
    }

    init(avatar: Avatar) {
        super.init()

        let characterModel = SCNText(string: avatar.rawValue, extrusionDepth: 1)
        characterModel.flatness = 0
        let node = SCNNode(geometry: characterModel)
        self.addChildNode(node)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
#endif
