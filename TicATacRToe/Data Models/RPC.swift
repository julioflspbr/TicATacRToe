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

    case matchEnded
    case sessionData(Data)

    init(from decoder: Decoder) throws {
        var decoder = try decoder.unkeyedContainer()
        let command = try decoder.decode(UInt8.self)

        switch command {
            case 0:
                self = .matchEnded
            case 1:
                self = .sessionData(try decoder.decode(Data.self))
            default:
                throw Error.badCommand
        }
    }

    var rawValue: Int {
        switch self {
            case .matchEnded:
                return 0
            case .sessionData:
                return 1
        }
    }

    func encode(to encoder: Encoder) throws {
        var encoder = encoder.unkeyedContainer()
        try encoder.encode(self.rawValue)

        switch self {
            case .matchEnded:
                break
            case let .sessionData(data):
                try encoder.encode(data)
        }
    }
}
