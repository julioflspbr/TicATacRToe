//
//  TicATacRToeApp.swift
//  TicATacRToe
//
//  Created by Julio Flores on 14/12/2022.
//

import SwiftUI

@main
struct TicATacRToeApp: App {
    @StateObject private var gameController = GameController()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(self.gameController)
        }
    }
}
