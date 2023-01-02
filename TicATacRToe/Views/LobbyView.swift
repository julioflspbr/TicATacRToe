//
//  LobbyView.swift
//  TicATacRToe
//
//  Created by Júlio César Flores on 26/12/2022.
//

import SwiftUI
import MultipeerConnectivity

struct LobbyView: View {
    @EnvironmentObject private var informationController: InformationController

    var body: some View {
        VStack {
            Text("Lobby")
                .font(.appTitle)

            SwiftUI.Grid(alignment: .leading) {
                GridRow {
                    Text("nickname:")
                        .font(.appDefault)
                        .fontWeight(.bold)

                    TextField("choose nickname", text: $informationController.nickname)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .font(.appDefault)
                        .lineLimit(1)
                }

                GridRow {
                    Text("opponent:")
                        .font(.appDefault)
                        .fontWeight(.bold)
                    Text(self.informationController.opponent.isEmpty ? "pick opponent below" : self.informationController.opponent)
                        .font(.appDefault)
                        .foregroundColor(self.informationController.opponent.isEmpty ? .secondary.opacity(0.45) : .primary)
                }
            }
            .padding(.horizontal)

            PickView(source: self.informationController.availablePlayers, selected: $informationController.opponent)
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
            broadcastController.browser(mockServiceBrowser, foundPeer: MCPeerID(displayName: name), withDiscoveryInfo: nil)
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
