//
//  ContentView.swift
//  TicATacRToe
//
//  Created by Julio Flores on 14/12/2022.
//

import SwiftUI
import MultipeerConnectivity

struct ContentView: View {
    @EnvironmentObject private var informationController: InformationController
    @EnvironmentObject private var interruptionController: InterruptionController
    @EnvironmentObject private var gameController: GameController

    var body: some View {
        ZStack {
            threeDeeArea
            hud
            interruptionBackground
            lobby
        }
        .alertHandler()

    }

    private var hud: some View {
        VStack(spacing: 8) {
            ZStack {
                Text("Floating Tic Tac Toe")
                    .font(.appTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .background(Color.black)

                HStack {
                    Spacer()
                    Button(action: self.gameController.endMatch, label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white)
                    })
                    .padding()
                }
            }

            ZStack {
                HStack {
                    SwiftUI.Grid(alignment: .leading, verticalSpacing: 8) {
                        GridRow {
                            Text("My Score:")
                                .font(.appDefault)
                                .foregroundColor(.white)
                            Text("\(self.informationController.result.me)")
                                .font(.appDefault)
                                .foregroundColor(.white)
                        }
                        GridRow {
                            Text("Opponent's:")
                                .font(.appDefault)
                                .foregroundColor(.white)
                            Text("\(self.informationController.result.opponent)")
                                .font(.appDefault)
                                .foregroundColor(.white)
                        }
                    }

                    Spacer()
                }

                Text(self.informationController.myAvatar.rawValue)
                    .font(.avatar)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }

            Spacer()
        }
    }

    private var lobby: some View {
        VStack {
            Spacer()
            
            if !self.informationController.isLobbySetUp {
                LobbyView()
            }
        }
    }

    private var interruptionBackground: some View {
        Group {
            if self.interruptionController.isInteractionBlocked {
                Rectangle()
                    .ignoresSafeArea()
                    .background(.ultraThinMaterial)
            }
        }
    }

    private var threeDeeArea: some View {
        Group {
            RenderView()
                .ignoresSafeArea()

            TapView()
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
            broadcastController.browser(mockServiceBrowser, foundPeer: MCPeerID(displayName: name), withDiscoveryInfo: nil)
        }

        return ContentView()
            .environmentObject(gameController)
            .environmentObject(broadcastController)
            .environmentObject(interruptionController)
    }
}
