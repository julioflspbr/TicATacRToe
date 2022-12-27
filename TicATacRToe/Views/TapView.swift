//
//  TapView.swift
//  TicATacRToe
//
//  Created by Júlio César Flores on 23/12/22.
//

import SwiftUI

struct TapView: View {
    @EnvironmentObject private var gameController: GameController

    var body: some View {
        Color.clear
            .contentShape(Rectangle())
            .onTapGesture(coordinateSpace: .global, perform: self.gameController.handleTap(at:))
    }
}
