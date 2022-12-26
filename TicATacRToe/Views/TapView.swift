//
//  TapView.swift
//  TicATacRToe
//
//  Created by Júlio César Flores on 23/12/22.
//

import SwiftUI

struct TapView: View {
    let action: ((CGPoint) -> Void)

    var body: some View {
        Color.clear
            .contentShape(Rectangle())
            .onTapGesture(coordinateSpace: .global, perform: self.action)
    }
}
