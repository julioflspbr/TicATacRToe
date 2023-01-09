//
//  RPC.swift
//  TicATacRToe
//
//  Created by Júlio César Flores on 01/01/2023.
//

import Foundation

enum RPC {
    case matchEnded
    case opponentDevice(DeviceType)
    case sessionData(Data)
}

extension RPC: Codable {
    enum Error: Swift.Error {
        case badCommand
        case badOpponentDeviceType
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
                self = .opponentDevice(opponentDeviceType)
            case 2:
                self = .sessionData(try decoder.decode(Data.self))
            default:
                throw Error.badCommand
        }
    }

    var rawValue: Int {
        switch self {
            case .matchEnded:
                return 0
            case .opponentDevice:
                return 1
            case .sessionData:
                return 2
        }
    }

    func encode(to encoder: Encoder) throws {
        var encoder = encoder.unkeyedContainer()
        try encoder.encode(self.rawValue)

        switch self {
            case .matchEnded:
                break
            case let .opponentDevice(deviceType):
                try encoder.encode(deviceType.rawValue)
            case let .sessionData(data):
                try encoder.encode(data)
        }
    }
}
