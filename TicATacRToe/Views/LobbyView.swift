//
//  LobbyView.swift
//  TicATacRToe
//
//  Created by Júlio César Flores on 26/12/2022.
//

import SwiftUI

struct LobbyView: View {
    @Binding private(set) var nickname: String
    @Binding private(set) var opponent: String?
    @Binding private(set) var availablePlayers: [String]

    var body: some View {
        VStack {
            Text("Lobby")
                .font(.appTitle)

            VStack(alignment: .leading) {
                HStack {
                    Text("nickname:")
                        .font(.appDefault)
                        .fontWeight(.bold)

                    TextField("choose nickname", text: Binding(
                        get: {
                            self.nickname.lowercased()
                        },
                        set: { newValue in
                            self.nickname = String(newValue.prefix(10))
                        })
                    )
                    .font(.appDefault)
                    .lineLimit(1)
                }
                .padding(.horizontal)
                .padding(.vertical, 5)

                HStack {
                    Text("opponent:")
                        .font(.appDefault)
                        .fontWeight(.bold)
                    Text(self.opponent ?? "pick opponent below")
                        .font(.appDefault)
                        .foregroundColor(self.opponent == nil ? .secondary : .primary)
                }
                .padding(.horizontal)
            }

            PickView(source: self.availablePlayers, selected: $opponent)
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
        LobbyView(
            nickname: .constant("jessica"),
            opponent: .constant(nil),
            availablePlayers: .constant(NameProvider.provide(amount: 3))
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            Color.gray
                .ignoresSafeArea()
        }
    }
}
