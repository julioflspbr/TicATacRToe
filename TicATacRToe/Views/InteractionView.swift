//
//  InteractionView.swift
//  TicATacRToe
//
//  Created by Julio Flores on 08/01/2023.
//

import SwiftUI

struct InteractiveView: View {
    @State private var deltaDistance: CGFloat = 0.0
    @State private var deltaScale: CGFloat = 0.0
    @State private var isActive = true
    @State private var isGridDefined = false
    @State private var tapPoint: CGPoint?

    var body: some View {
        RenderView(deltaDistance: self.deltaDistance, deltaScale: self.deltaScale,
                   isActive: self.isActive, isGridDefined: $isGridDefined, tapPoint: $tapPoint)
            .ignoresSafeArea()
            .gesture(DragGesture(minimumDistance: 5.0)
                .onChanged { drag in
                    self.deltaDistance = drag.translation.height
                }
            )
            .gesture(MagnificationGesture()
                .onChanged { delta in
                    self.deltaScale = delta
                }
            )
            .onTapGesture(coordinateSpace: .global) { tap in
                self.tapPoint = tap
            }
            .overlay(alignment: .bottom) {
                if !isGridDefined {
                    Button {
                        self.isGridDefined = true
                    } label: {
                        Image(systemName: "checkmark.circle")
                            .resizable()
                            .frame(width: 60.0, height: 60.0)
                            .padding(5)
                            .foregroundColor(.black)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(radius: 10)
                    }
                }
            }
    }
}
