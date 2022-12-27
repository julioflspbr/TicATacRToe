//
//  ContentView.swift
//  TicATacRToe
//
//  Created by Julio Flores on 14/12/2022.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var gameController: GameController
    @EnvironmentObject private var interruptionController: InterruptionController

    var body: some View {
        ZStack {
            threeDeeArea
            interruptionBackground
            lobby
        }
        .alertHandler()
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
            if self.interruptionController.is3DInteractionDenied {
                Rectangle()
                    .ignoresSafeArea()
                    .background(.ultraThinMaterial)
            }
        }
    }

    var lobby: some View {
        VStack {
            Spacer()
            
            if !self.gameController.isGameSetUp {
                LobbyView()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let gameController = GameController()
        let interruptionController = InterruptionController()

        gameController.interruptionDelegate = interruptionController
        gameController.availablePlayers = NameProvider.provide(amount: 2)

        return ContentView()
            .environmentObject(gameController)
            .environmentObject(interruptionController)
    }
}
