//
//  TicATacRToe_SinglePlayerApp.swift
//  TicATacRToe-SP
//
//  Created by Julio Flores on 17/01/2023.
//

import SwiftUI

@main
struct TicATacRToeSPApp: App {
    private let gameController = GameController()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(self.gameController)
        }
    }
}
