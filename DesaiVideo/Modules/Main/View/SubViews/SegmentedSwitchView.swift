//
//  SegmentedSwitchView.swift
//  DesaiVideo
//
//  Created by Abylaikhan Abilkayr on 22.10.2025.
//

import Foundation
import SwiftUI

enum Segment {
    case audio, video
}

struct SegmentedSwitchView: View {
    @Binding var selectedSegment: Segment

    var body: some View {
        HStack(spacing: 0) {
            segmentButton(title: "Audio", segment: .audio)
            segmentButton(title: "Video", segment: .video)
        }
        .padding(2)
        .background(
            Capsule()
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.12))
                    )
        )
    }

    @ViewBuilder
    private func segmentButton(title: String, segment: Segment) -> some View {
        Button(action: {
            withAnimation(.spring) {
                selectedSegment = segment
            }
        }) {
            Text(title)
                .font(.system(size: 13, weight: selectedSegment == segment ? .semibold : .regular))
                .foregroundColor(.white)
                .frame(width: 176.fitW, height: 28)
                .background(
                    Group {
                        if selectedSegment == segment {
                            Color.green01A274
                                .clipShape(Capsule())
                        } else {
                            Color.clear
                        }
                    }
                )
        }
    }
}
