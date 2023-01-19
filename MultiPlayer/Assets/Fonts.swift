//
//  Fonts.swift
//  TicATacRToe
//
//  Created by Júlio César Flores on 26/12/2022.
//

import SwiftUI

extension Font {
    private static var americanTypewriter: String { "American Typewriter" }

    static var avatar: Font {
        .custom(americanTypewriter, size: 70)
    }

    static var appDefault: Font {
        .custom(americanTypewriter, size: 14)
    }

    static var appTitle: Font {
        .custom(americanTypewriter, size: 18, relativeTo: .title)
        .weight(.bold)
    }
}
