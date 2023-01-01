//
//  TicATacRToeApp.swift
//  TicATacRToe
//
//  Created by Julio Flores on 14/12/2022.
//

import SwiftUI

@main
struct TicATacRToeApp: App {
    private let gameController = GameController()
    private let broadcastController = BroadcastController()
    private let interruptionController = InterruptionController()

    init() {
        self.gameController.interruptionDelegate = self.interruptionController
        self.broadcastController.alertDelegate = self.interruptionController
        self.broadcastController.gameDelegate = self.gameController
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(self.gameController)
                .environmentObject(self.broadcastController)
                .environmentObject(self.interruptionController)
        }
    }
}
