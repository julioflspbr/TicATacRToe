//
//  RPC.swift
//  TicATacRToe
//
//  Created by Júlio César Flores on 01/01/2023.
//

import Foundation

enum RPC {
    case matchEnded
    case connected(DeviceType)
    case placedActor(Place.Position)
    case sessionData(Data)

    // for simulator
    case gridDefined
}

extension RPC: Codable {
    enum Error: Swift.Error {
        case badCommand
        case badOpponentDeviceType
        case badPlacePosition
    }

    enum DeviceType: Int {
        case device
        case simulator
    }

    init(from decoder: Decoder) throws {
        var decoder = try decoder.unkeyedContainer()
        let command = try decoder.decode(UInt8.self)

        switch command {
            case 0:
                self = .matchEnded
            case 1:
                let rawOpponentDeviceType = try decoder.decode(Int.self)
                guard let opponentDeviceType = DeviceType(rawValue: rawOpponentDeviceType) else {
                    throw Error.badOpponentDeviceType
                }
                self = .connected(opponentDeviceType)
            case 2:
                let rawPlacePosition = try decoder.decode(String.self)
                guard let placePosition = Place.Position(rawValue: rawPlacePosition) else {
                    throw Error.badPlacePosition
                }
                self = .placedActor(placePosition)
            case 3:
                self = .sessionData(try decoder.decode(Data.self))
            case 4:
                self = .gridDefined
            default:
                throw Error.badCommand
        }
    }

    var rawValue: Int {
        switch self {
            case .matchEnded:
                return 0
            case .connected:
                return 1
            case .placedActor:
                return 2
            case .sessionData:
                return 3
            case .gridDefined:
                return 4
        }
    }

    func encode(to encoder: Encoder) throws {
        var encoder = encoder.unkeyedContainer()
        try encoder.encode(self.rawValue)

        switch self {
            case let .connected(deviceType):
                try encoder.encode(deviceType.rawValue)
            case let .placedActor(position):
                try encoder.encode(position.rawValue)
            case let .sessionData(data):
                try encoder.encode(data)
            default:
                break
        }
    }
}
