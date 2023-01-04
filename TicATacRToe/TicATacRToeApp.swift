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
    private let informationController = InformationController()
    private let interruptionController = InterruptionController()

    init() {
        self.broadcastController.alertDelegate = self.interruptionController
        self.broadcastController.gameDelegate = self.gameController
        self.broadcastController.informationDelegate = self.informationController

        self.gameController.broadcastDelegate = self.broadcastController
        self.gameController.informationDelegate = self.informationController
        self.gameController.interruptionDelegate = self.interruptionController

        self.informationController.broadcastDelegate = self.broadcastController
        self.informationController.interruptionDelegate = self.interruptionController
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(self.broadcastController)
                .environmentObject(self.gameController)
                .environmentObject(self.informationController)
                .environmentObject(self.interruptionController)
        }
    }
}
