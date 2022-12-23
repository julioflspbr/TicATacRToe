//
//  ContentView.swift
//  TicATacRToe
//
//  Created by Julio Flores on 14/12/2022.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var gameController = GameController()

    var body: some View {
        ZStack {
            RenderView()
                .ignoresSafeArea()
            TapView()
        }
        .environmentObject(gameController)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
