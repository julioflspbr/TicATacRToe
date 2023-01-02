//
//  PickView.swift
//  TicATacRToe
//
//  Created by Júlio César Flores on 26/12/2022.
//

import SwiftUI

struct PickView: View {
    private let source: [[String]]

    @Binding private(set) var selected: String

    @Environment(\.colorScheme) private var colourScheme

    init(source: Set<String>, selected: Binding<String>) {
        var flatSource = source
        let lineItemLimit = 4
        var groupedSource = [[String]]()

        while flatSource.count > 0 {
            var line = [String]()
            while line.count < lineItemLimit && flatSource.count > 0 {
                line.append(flatSource.removeFirst())
            }
            groupedSource.append(line)
        }
        self.source = groupedSource
        self._selected = selected
    }

    var body: some View {
        if !self.selected.isEmpty {
            ProgressView(label: { Text("Waiting for \(selected)'s response") })
                .progressViewStyle(.circular)
                .font(.appDefault)
        } else if self.source.isEmpty {
            ProgressView(label: { Text("Searching for players") })
                .progressViewStyle(.circular)
                .font(.appDefault)
        } else if self.source.count > 0 {
            VStack {
                ForEach(self.source, id: \.self) { line in
                    HStack {
                        ForEach(line, id: \.self) { item in
                            PickButton(foreground: self.buttonTextColour, background: self.generateRandomColour(), item: item) { selected in
                                self.selected = selected
                            }
                        }
                    }
                }
            }
        }
    }

    private func generateRandomColour() -> Color {
        let colourRange: ClosedRange<Double>
        switch self.colourScheme {
            case .light:
                colourRange = 0 ... 0.5
            case .dark:
                colourRange = 0.5 ... 1.0
            @unknown default:
                colourRange = 0 ... 0.5
        }

        return Color(red: .random(in: colourRange), green: .random(in: colourRange), blue: .random(in: colourRange))
    }

    private var buttonTextColour: Color {
        switch self.colourScheme {
            case .light:
                return .white
            case .dark:
                return .black
            @unknown default:
                return .white
        }
    }
}

private struct PickButton: View {
    @State private(set) var foreground: Color
    @State private(set) var background: Color

    let item: String
    let select: (String) -> Void

    var body: some View {
        Button(self.item) {
            select(self.item)
        }
        .font(.appDefault)
        .padding(.vertical, 3)
        .padding(.horizontal, 10)
        .foregroundColor(self.foreground)
        .background {
            Capsule()
                .foregroundColor(self.background)
        }
    }
}

struct PickView_Preview: PreviewProvider {
    static var previews: some View {
        PickView(source: NameProvider.provide(amount: 20), selected: .constant(""))
    }
}
