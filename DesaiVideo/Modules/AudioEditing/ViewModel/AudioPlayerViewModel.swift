//
//  AudioPlayerViewModel.swift
//  DesaiVideo
//
//  Created by Abylaikhan Abilkayr on 29.10.2025.
//

import Foundation
import AVFoundation

final class AudioPlayerViewModel: ObservableObject {
    let player: AVPlayer
    @Published var current: Double = 0
    @Published var duration: Double = 0
    
    private var timeObs: Any?
    
    init(url: URL) {
        self.player = AVPlayer(url: url)
        addObservers()
    }
    
    private func addObservers() {
        timeObs = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.1, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            guard let self else { return }
            current = time.seconds
            if let d = player.currentItem?.duration.seconds, d.isFinite {
                duration = d
            }
        }
    }
    
    func play() { player.play() }
    func pause() { player.pause() }
    func seek(to seconds: Double) {
        let cm = CMTime(seconds: seconds, preferredTimescale: 600)
        player.seek(to: cm, toleranceBefore: .zero, toleranceAfter: .zero)
    }
    
    deinit {
        if let t = timeObs { player.removeTimeObserver(t) }
    }
}
