//
//  LobbyView.swift
//  TicATacRToe
//
//  Created by Júlio César Flores on 26/12/2022.
//

import SwiftUI
import MultipeerConnectivity

struct LobbyView: View {
    @EnvironmentObject private var broadcastController: BroadcastController

    var body: some View {
        VStack {
            Text("Lobby")
                .font(.appTitle)

            SwiftUI.Grid(alignment: .leading) {
                GridRow {
                    Text("nickname:")
                        .font(.appDefault)
                        .fontWeight(.bold)

                    TextField("choose nickname", text: $broadcastController.nickname)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .font(.appDefault)
                        .lineLimit(1)
                }

                GridRow {
                    Text("opponent:")
                        .font(.appDefault)
                        .fontWeight(.bold)
                    Text(self.broadcastController.opponentNickname ?? "pick opponent below")
                        .font(.appDefault)
                        .foregroundColor(self.broadcastController.opponentNickname == nil ? .secondary.opacity(0.45) : .primary)
                }
            }
            .padding(.horizontal)

            PickView(source: Array(self.broadcastController.availablePlayers.values), selected: $broadcastController.opponent)
                .frame(minHeight: 60)
                .padding(.bottom)
        }
        .padding(.top)
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(5)
        .padding(.horizontal)
    }
}

struct LobbyView_Previews: PreviewProvider {
    static var previews: some View {
        let gameController = GameController()
        let broadcastController = BroadcastController()

        let mockPeerID = MCPeerID(displayName: "mock-peer-id")
        let mockServiceBrowser = MCNearbyServiceBrowser(peer: mockPeerID, serviceType: mockPeerID.displayName)
        for name in NameProvider.provide(amount: 7) {
            broadcastController.browser(mockServiceBrowser, foundPeer: name, withDiscoveryInfo: nil)
        }

        return LobbyView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                Color.gray
                    .ignoresSafeArea()
            }
        .environmentObject(gameController)
        .environmentObject(broadcastController)
    }
}
