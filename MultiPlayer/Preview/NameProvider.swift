//
//  NameProvider.swift
//  TicATacRToe
//
//  Created by Júlio César Flores on 26/12/2022.
//

import Foundation

struct NameProvider {
    private static let source = [
        "Ria", "Richmond", "Catrin", "Howell", "Hugo", "Ferguson", "Jonty", "Oconnell", "Tamara", "Welch", "Yasir", "King", "Rajan",
        "Mercado", "Wilbur", "Gilmore", "Laurence", "Ware", "Mackenzie", "Frazier", "Umair", "Deleon", "Ajay", "Salas", "Lachlan",
        "Powell", "Diego", "Murphy", "Kristian", "Cervantes", "Luke", "Mcintosh", "Fay", "Hartley", "Denise", "Newton", "Tiffany",
        "Kaufman", "Ashwin", "Nielsen", "Eugene", "Vasquez", "Allen", "Mullen", "Saad", "Hurst", "Amirah", "Haley", "Annie", "Kline",
        "Hafsah", "Briggs", "Deacon", "Griffin", "Ruth", "Butler", "Oliwia", "Cohen", "Lucia", "Bruce", "Miya", "Nunez", "Rosanna",
        "Ayala", "Aamir", "Mitchell", "Alan", "Harvey", "Preston", "Thomson", "Samia", "Douglas", "Joanne", "Cole", "Ishaan", "Crawford",
        "Kurtis", "Hubbard", "Julius", "Hebert", "Skyla", "Baird", "Jay", "Mata", "Amina", "Reynolds", "Harmony", "Chapman", "Ahmad",
        "Hensley", "Grace", "Green", "Ameer", "Leon", "Archie", "Barton", "Sumaya", "Marks", "Suzanne", "Hooper"
    ]

    static func provide(amount: Int) -> Set<String> {
        let amount = min(amount, 50)
        var usedIndices = Set<Int>()
        var names = Set<String>()

        while names.count < amount {
            var currentIndex = -1
            repeat {
                currentIndex = Int(arc4random_uniform(UInt32(source.count)))
            } while usedIndices.contains(currentIndex)

            names.insert(source[currentIndex].lowercased())
            usedIndices.insert(currentIndex)
        }

        return names
    }
}
