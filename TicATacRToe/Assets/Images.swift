//
//  Image+Named.swift
//  TicATacRToe
//
//  Created by Júlio César Flores on 26/12/2022.
//

import SwiftUI

extension Image {
    enum Asset: String {
        case livingRoomPreview = "living-room-preview"
    }

    init(_ asset: Asset) {
        self.init(asset.rawValue)
    }
}
