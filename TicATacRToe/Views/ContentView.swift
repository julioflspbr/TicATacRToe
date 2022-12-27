//
//  ContentView.swift
//  TicATacRToe
//
//  Created by Julio Flores on 14/12/2022.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var gameController: GameController

    var body: some View {
        ZStack {
            threeDeeArea
            interruptionBackground
            lobby
        }
    }

    var threeDeeArea: some View {
        Group {
            RenderView()
                .ignoresSafeArea()

            TapView()
        }
    }

    var interruptionBackground: some View {
        Group {
            if !self.gameController.isGameSetup {
                Rectangle()
                    .ignoresSafeArea()
                    .background(.ultraThinMaterial)
            }
        }
    }

    var lobby: some View {
        VStack {
            Spacer()
            
            if !self.gameController.isGameSetup {
                LobbyView()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(GameController())
    }
}
