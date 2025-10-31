//
//  EnhanceSheetView.swift
//  DesaiVideo
//
//  Created by Abylaikhan Abilkayr on 28.10.2025.
//

import SwiftUI

struct EnhanceOptions {
    var removeFillerWords: Bool
    var trimLongPauses: Bool
    var reduceRepetition: Bool
    var reduceNoise: Bool
    var enhanceSound: Bool

    /// Бэку подходит один флаг sound_studio — включаем его,
    /// если пользователь хочет улучшение звука и/или шумоподавление.
    var soundStudioFlag: Bool { enhanceSound || reduceNoise }
}


struct EnhanceSheetView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var removeFillerWords = true
    @State private var trimLongPauses = true
    @State private var reduceRepetition = true
    @State private var reduceNoise = true
    @State private var enhanceSound = true

    var onGenerate: (EnhanceOptions) -> Void

    var body: some View {
        ZStack {
            VisualEffectBlur(style: .systemUltraThinMaterial)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                Capsule()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 51, height: 5)
                    .padding(.top, 8)
                
                Text("Enhance")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.bottom, 4)
                
                VStack(spacing: 12) {
                    EnhanceToggleRow(
                        title: "Remove filler words",
                        subtitle: "Cleans up “um”, “uh”, “like” and similar",
                        isOn: $removeFillerWords
                    )
                    
                    EnhanceToggleRow(
                        title: "Trim long pauses",
                        subtitle: "Cuts silences over 2–3 seconds",
                        isOn: $trimLongPauses
                    )
                    
                    EnhanceToggleRow(
                        title: "Reduce word repetition",
                        subtitle: "Removes repeated words or phrases",
                        isOn: $reduceRepetition
                    )
                    
                    EnhanceToggleRow(
                        title: "Reduce background noise",
                        subtitle: "Softens ambient sounds and distractions",
                        isOn: $reduceNoise
                    )
                    
                    EnhanceToggleRow(
                        title: "Enhance sound",
                        subtitle: "Improves clarity and balance",
                        isOn: $enhanceSound
                    )
                }
                
                Spacer(minLength: 8)
                
                Button {
                    let opts = EnhanceOptions(
                        removeFillerWords: removeFillerWords,
                        trimLongPauses: trimLongPauses,
                        reduceRepetition: reduceRepetition,
                        reduceNoise: reduceNoise,
                        enhanceSound: enhanceSound
                    )
                    onGenerate(opts)
                    dismiss()
                } label: {
                    Text("Generate")
                        .font(.system(size: 17, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .foregroundColor(.black)
                }
                .buttonStyle(.plain)
                .padding(.bottom, 24)
            }
            .padding(.horizontal)
        }
        .background(ClearBackground())
        .overlay {
            TopRoundedBorder(radius: 24)
                .stroke(
                    Color.white,
                    style: StrokeStyle(
                        lineWidth: 2,
                        lineCap: .round,
                        lineJoin: .round
                    )
                )
        }
    }
}

struct EnhanceToggleRow: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
            }
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .toggleStyle(SwitchToggleStyle(tint: .green))
        }
        .padding()
        .frame(height: 70)
        .background(Color.gray7C7C7C)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
