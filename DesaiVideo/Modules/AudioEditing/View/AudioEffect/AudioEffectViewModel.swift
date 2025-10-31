//
//  AudioEffectViewModel.swift
//  DesaiVideo
//
//  Created by Abylaikhan Abilkayr on 28.10.2025.
//

import SwiftUI

final class AudioEffectViewModel: ObservableObject {
    @Published var barHeights: [CGFloat] = Array(repeating: 30, count: 30)
    private var visualizationTimer: Timer?

    func setAnimating(_ on: Bool) {
        on ? start() : stop()
    }

    private func start() {
        stop()
        visualizationTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            guard let self else { return }
            withAnimation {
                self.barHeights = self.barHeights.map { _ in CGFloat.random(in: 10...107) }
            }
        }
        // чтобы не залипало при скролле/жестах
        RunLoop.main.add(visualizationTimer!, forMode: .common)
    }

    private func stop() {
        visualizationTimer?.invalidate()
        visualizationTimer = nil
    }

    deinit { stop() }
}


struct AudioEffectView: View {
    
    // MARK: - Public Properties
    
    @ObservedObject var viewModel: AudioEffectViewModel
    
    // MARK: - Private Properties
    
    private let barWidth: CGFloat = 5
    private let corner: CGFloat = 2.5
    private let minOpacity: CGFloat = 0.05
    private let maxOpacity: CGFloat = 1.0
    
    // MARK: - Body
    
    var body: some View {
        GeometryReader { geo in
            let count = viewModel.barHeights.count
            let spacing = (geo.size.width - barWidth * CGFloat(count)) / CGFloat(max(count - 1, 1))
            let center  = CGFloat(count - 1) / 2
            HStack(alignment: .center, spacing: spacing) {
                ForEach(viewModel.barHeights.indices, id: \.self) { idx in
                    
                    let distance = abs(CGFloat(idx) - center) / center
                    let alpha = maxOpacity - (maxOpacity - minOpacity) * distance
                    
                    RoundedRectangle(cornerRadius: corner)
                        .fill(Color.white)
                        .opacity(alpha)
                        .frame(width: barWidth, height: viewModel.barHeights[idx])
                }
            }
        }
        .frame(height: 110)
    }
}
