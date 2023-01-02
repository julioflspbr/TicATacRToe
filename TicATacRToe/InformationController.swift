//
//  InformationController.swift
//  TicATacRToe
//
//  Created by Júlio César Flores on 02/01/2023.
//

import Foundation

protocol InformationControllerBroadcastDelegate: AnyObject {
    func setNickname(_: String)
    func setOpponent(_: String) throws
}

protocol InformationControllerInterruptionDelegate: AnyObject {
    @MainActor func handleError(_ error: Error)
}

final class InformationController: ObservableObject, GameControllerInformationDelegate, BroadcastControllerInformationDelegate {
    weak var broadcastDelegate: InformationControllerBroadcastDelegate?
    weak var interruptionDelegate: InformationControllerInterruptionDelegate?

    // MARK: - GameControllerInformationDelegate
    @MainActor @Published var currentAvatar = Actor.Avatar.cross
    @MainActor @Published var isLobbySetUp: Bool = false
    @MainActor @Published var myAvatar = Actor.Avatar.cross
    @MainActor @Published var result = Wins()

    // MARK: - BroadcastControllerInformationDelegate
    @MainActor @Published var availablePlayers = Set<String>()
    @MainActor @Published var nickname = "" {
        didSet {
            self.broadcastDelegate?.setNickname(self.nickname)
        }
    }
    @MainActor @Published var opponent = "" {
        didSet {
            do {
                try self.broadcastDelegate?.setOpponent(self.opponent)
            } catch {
                Task { @MainActor in
                    self.interruptionDelegate?.handleError(error)
                }
            }
        }
    }
}
