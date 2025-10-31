//
//  AudioTimeBar.swift
//  DesaiVideo
//
//  Created by Abylaikhan Abilkayr on 29.10.2025.
//

import Foundation
import SwiftUI

struct AudioTimebar: View {
    @ObservedObject var playerVM: AudioPlayerViewModel
    @State private var isScrubbing = false
    @State private var wasPlayingBeforeScrub = false

    var body: some View {
        VStack(spacing: 8) {
            GeometryReader { geo in
                let w = max(1, geo.size.width)
                let h: CGFloat = 4
                let progress = playerVM.duration > 0 ? max(0, min(1, playerVM.current / playerVM.duration)) : 0
                let knobX = progress * w

                ZStack(alignment: .leading) {
                    Capsule().fill(Color.grayEBECF5)
                        .frame(height: h)
                    Capsule().fill(Color.white.opacity(0.9))
                        .frame(width: knobX, height: h)
                    Circle()
                        .fill(Color.white)
                        .frame(width: 14, height: 14)
                        .overlay(Circle().stroke(Color.green01A274, lineWidth: 2))
                        .shadow(radius: 1)
                        .offset(x: max(0, min(w-18, knobX-9)), y: 0)
                }
                // 👇 важно!
                .contentShape(Rectangle()) // зона нажатий = вся ширина + высота view
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { v in
                            guard playerVM.duration > 0 else { return }
                            if !isScrubbing {
                                isScrubbing = true
                                wasPlayingBeforeScrub = playerVM.player.timeControlStatus == .playing
                                playerVM.pause()
                            }
                            let x = max(0, min(w, v.location.x))
                            playerVM.current = Double(x / w) * playerVM.duration
                        }
                        .onEnded { _ in
                            guard playerVM.duration > 0 else { return }
                            playerVM.seek(to: playerVM.current)
                            if wasPlayingBeforeScrub { playerVM.play() }
                            isScrubbing = false
                        }
                )
            }
            .frame(height: 22) // 🟢 больше площадь для пальца

            
            HStack {
                Text(format(playerVM.current))
                Spacer()
                Text(format(playerVM.duration))
            }
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(.white.opacity(0.95))
        }
    }

    private func format(_ s: Double) -> String {
        guard s.isFinite else { return "--:--" }
        let v = Int(s.rounded())
        return String(format: "%02d:%02d", v/60, v%60)
    }
}
