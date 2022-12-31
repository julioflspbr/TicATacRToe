//
//  ContentView.swift
//  TicATacRToe
//
//  Created by Julio Flores on 14/12/2022.
//

import SwiftUI
import MultipeerConnectivity

struct ContentView: View {
    @EnvironmentObject private var gameController: GameController
    @EnvironmentObject private var broadcastController: BroadcastController
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
            if self.interruptionController.isInteractionBlocked {
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
        let broadcastController = BroadcastController()
        let interruptionController = InterruptionController()

        gameController.interruptionDelegate = interruptionController

        let mockPeerID = MCPeerID(displayName: "mock-peer-id")
        let mockServiceBrowser = MCNearbyServiceBrowser(peer: mockPeerID, serviceType: mockPeerID.displayName)
        for name in NameProvider.provide(amount: 2) {
            broadcastController.browser(mockServiceBrowser, foundPeer: name, withDiscoveryInfo: nil)
        }

        return ContentView()
            .environmentObject(gameController)
            .environmentObject(broadcastController)
            .environmentObject(interruptionController)
    }
}
