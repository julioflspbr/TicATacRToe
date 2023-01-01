//
//  RPC.swift
//  TicATacRToe
//
//  Created by Júlio César Flores on 01/01/2023.
//

import Foundation

enum RPC: Codable {
    enum Error: Swift.Error {
        case badAvatarChoice
        case badPositionChoice
        case badCommand
    }

    case gridMoved(SIMD3<Float>)
    case gridPositionDefined(SIMD3<Float>)
    case opponentPlaced(Place.Position)
    case matchEnded

    init(from decoder: Decoder) throws {
        var decoder = try decoder.unkeyedContainer()
        let command = try decoder.decode(UInt8.self)

        switch command {
            case 0:
                let position = try decoder.decode(SIMD3<Float>.self)
                self = .gridMoved(position)
            case 1:
                let position = try decoder.decode(SIMD3<Float>.self)
                self = .gridPositionDefined(position)
            case 2:
                let rawPosition = try decoder.decode(Int.self)
                guard let position = Place.Position(rawValue: rawPosition) else {
                    throw Error.badPositionChoice
                }
                self = .opponentPlaced(position)

            case 3:
                self = .matchEnded
            default:
                throw Error.badCommand
        }
    }

    var rawValue: Int {
        switch self {
            case .gridMoved:
                return 0
            case .gridPositionDefined:
                return 1
            case .opponentPlaced:
                return 2
            case .matchEnded:
                return 3
        }
    }

    func encode(to encoder: Encoder) throws {
        var encoder = encoder.unkeyedContainer()

        try encoder.encode(self.rawValue)

        switch self {
            case let .gridMoved(position):
                try encoder.encode(position)
            case let .gridPositionDefined(position):
                try encoder.encode(position)
            case let .opponentPlaced(position):
                try encoder.encode(position.rawValue)
            case .matchEnded:
                break
        }
    }
}
