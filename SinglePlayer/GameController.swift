//
//  GameController.swift
//  TicATacRToe-SP
//
//  Created by Julio Flores on 17/01/2023.
//

import SwiftUI
import SceneKit

protocol GameControllerSceneDelegate: AnyObject {
    @MainActor func strikeThrough(_: StrikeThrough.StrikeType, colour: Actor.Colour)
    @MainActor func paintGrid(with: Actor.Colour)
    @MainActor func makeNewGrid()
}

final class GameController: ObservableObject {
    weak var sceneDelegate: GameControllerSceneDelegate?

    private(set) var myAvatar = Actor.Avatar.cross

    private var state = [Actor.Avatar.cross: Set<Place.Position>(), Actor.Avatar.circle: Set<Place.Position>()]

    private func wrapUp(avatar: Actor.Avatar, strikeThrough: StrikeThrough.StrikeType?, gridColour: Actor.Colour) {
        Task { @MainActor in
            if let strikeThrough {
                self.sceneDelegate?.strikeThrough(strikeThrough, colour: gridColour)
                self.sceneDelegate?.paintGrid(with: gridColour)
            }
            self.sceneDelegate?.makeNewGrid()
        }
    }

    func didPlaceActor(at position: Place.Position) {
        self.state[self.myAvatar]?.insert(position)
        let state = self.state[self.myAvatar]!

        let strikeThrough: StrikeThrough.StrikeType?
        if state.contains(elements: [.topLeft, .top, .topRight]) {
            strikeThrough = .horizontal(.top)
        } else if state.contains(elements: [.left, .centre, .right]) {
            strikeThrough = .horizontal(.centre)
        } else if state.contains(elements: [.bottomLeft, .bottom, .bottomRight]) {
            strikeThrough = .horizontal(.bottom)
        } else if state.contains(elements: [.topLeft, .left, .bottomLeft]) {
            strikeThrough = .vertical(.left)
        } else if state.contains(elements: [.top, .centre, .bottom]) {
            strikeThrough = .vertical(.centre)
        } else if state.contains(elements: [.topRight, .right, .bottomRight]) {
            strikeThrough = .vertical(.right)
        } else if state.contains(elements: [.topLeft, .centre, .bottomRight]) {
            strikeThrough = .diagonal(.leftTop)
        } else if state.contains(elements: [.topRight, .centre, .bottomLeft]) {
            strikeThrough = .diagonal(.rightTop)
        } else {
            strikeThrough = nil
        }

        let hasWinner = (strikeThrough != nil)
        let allPlacesFilled = 9
        let filledWithCircles = self.state[.circle]?.count ?? 0
        let filledWithCrosses = self.state[.cross]?.count ?? 0
        let isDraw = (filledWithCircles + filledWithCrosses == allPlacesFilled)
        if hasWinner || isDraw {
            self.wrapUp(avatar: self.myAvatar, strikeThrough: strikeThrough, gridColour: self.myAvatar.colour)
            self.state[.cross]?.removeAll()
            self.state[.circle]?.removeAll()
            self.myAvatar = .cross
        } else {
            self.myAvatar.toggle()
        }
    }
}

private extension Set where Element == Place.Position {
    func contains<C: Collection>(elements: C) -> Bool where C.Element == Element {
        let intersection = self.intersection(elements)
        return intersection.count == elements.count
    }
}

private extension Actor.Avatar {
    mutating func toggle() {
        self = self.opposite
    }
}
