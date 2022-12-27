//
//  LobbyView.swift
//  TicATacRToe
//
//  Created by Júlio César Flores on 26/12/2022.
//

import SwiftUI

struct LobbyView: View {
    @EnvironmentObject private var gameController: GameController

    var body: some View {
        VStack {
            Text("Lobby")
                .font(.appTitle)

            VStack(alignment: .leading) {
                HStack {
                    Text("nickname:")
                        .font(.appDefault)
                        .fontWeight(.bold)

                    TextField("choose nickname", text: $gameController.nickname)
                    .font(.appDefault)
                    .lineLimit(1)
                }
                .padding(.horizontal)
                .padding(.vertical, 5)

                HStack {
                    Text("opponent:")
                        .font(.appDefault)
                        .fontWeight(.bold)
                    Text(self.gameController.opponent ?? "pick opponent below")
                        .font(.appDefault)
                        .foregroundColor(self.gameController.opponent == nil ? .secondary : .primary)
                }
                .padding(.horizontal)
            }

            PickView(source: self.gameController.availablePlayers, selected: $gameController.opponent)
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
        LobbyView()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            Color.gray
                .ignoresSafeArea()
        }
        .environmentObject(GameController())
    }
}
