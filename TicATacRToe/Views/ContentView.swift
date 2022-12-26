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
            threeDeeArea
            interruptionBackground
            lobby
        }
    }

    var threeDeeArea: some View {
        Group {
            RenderView(
                scene: self.gameController.scene,
                sceneController: $gameController.sceneController
            )
            .ignoresSafeArea()

            TapView(action: self.gameController.handleTap(at:))
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
                LobbyView(
                    nickname: $gameController.nickname,
                    opponent: $gameController.opponent,
                    availablePlayers: $gameController.availablePlayers
                )
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
