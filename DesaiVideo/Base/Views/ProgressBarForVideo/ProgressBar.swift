//
//  ProgressBar.swift
//  DesaiVideo
//
//  Created by Abylaikhan Abilkayr on 23.10.2025.
//

import SwiftUI

struct ProgressBar: View {
    var progress: Double
    var buffered: Double = 0
    var onScrub: (Double) -> Void
    var onScrubBegan: () -> Void
    var onScrubEnded: () -> Void
    
    @State private var localProgress: Double = 0
    @State private var isDragging = false
    
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            
            ZStack(alignment: .leading) {
                Capsule().fill(Color.grayEBECF5).frame(height: 4)
                
                // буфер
                Capsule().fill(Color.grayEBECF5)
                    .frame(width: CGFloat(buffered) * w, height: 4)
                
                // заполнение
                Capsule().fill(Color.white.opacity(0.9))
                    .frame(width: CGFloat(currentFrac) * w, height: 4)
                
                // кружок
                Circle()
                    .fill(Color.white)
                    .frame(width: 14, height: 14)
                    .overlay(Circle().stroke(Color.green01A274, lineWidth: 2))
                    .shadow(radius: 1)
                    .offset(x: max(0, min(w, CGFloat(currentFrac) * w)) - 8, y: (h-20)/2)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if !isDragging { isDragging = true; onScrubBegan() }
                        let frac = max(0, min(1, value.location.x / w))
                        localProgress = frac
                        onScrub(frac)
                    }
                    .onEnded { _ in
                        isDragging = false
                        onScrubEnded()
                    }
            )
        }
    }
    
    private var currentFrac: Double {
        isDragging ? localProgress : progress
    }
}
