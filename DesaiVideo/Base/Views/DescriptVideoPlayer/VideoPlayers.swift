////
////  VideoPlayer.swift
////  Scripty
////
////  Created by Илья Тимченко on 6/30/25.
////
//
//import AVKit
//import SwiftUI
//
//struct VideoPlayer: UIViewControllerRepresentable {
//    
//    // MARK: - Public Properties
//    
//    @Binding var isPlaying: Bool
//    let isLooping: Bool
//    
//    // MARK: - Private Properties
//    
//    private let player: AVQueuePlayer
//    private var looper: AVPlayerLooper?
//    
//    // MARK: - Initializer
//    
//    init(videoURL: URL, isPlaying: Binding<Bool>, isLooping: Bool = true, volume: Float = .zero) {
//        self._isPlaying = isPlaying
//        self.isLooping = isLooping
//        let asset = AVAsset(url: videoURL)
//        let item = AVPlayerItem(asset: asset)
//        let player = AVQueuePlayer(playerItem: item)
//        self.player = player
//        player.volume = volume
//        if isLooping {
//            self.looper = AVPlayerLooper(player: player, templateItem: item)
//        } else {
//            self.looper = nil
//        }
//    }
//    
//    // MARK: - Make UI View Controller
//    
//    func makeUIViewController(context: Context) -> AVPlayerViewController {
//        let controller = AVPlayerViewController()
//        controller.player = player
//        controller.showsPlaybackControls = false
//        controller.videoGravity = .resizeAspectFill
//        controller.allowsVideoFrameAnalysis = false
//        addTimeObserver(to: player)
//        return controller
//    }
//    
//    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
//        if isPlaying {
//            uiViewController.player?.play()
//        } else {
//            uiViewController.player?.pause()
//        }
//    }
//    
//    // MARK: - Private Methods
//    
//    private func addTimeObserver(to player: AVQueuePlayer) {
//        let interval = CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
//        player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { time in
//            if let currentItem = player.currentItem {
//                let duration = currentItem.duration
//                let epsilon = CMTime(seconds: 0.2, preferredTimescale: 600)
//                if duration.isNumeric && time >= duration - epsilon {
//                    player.seek(to: .zero)
//                    if isLooping {
//                        player.play()
//                    } else {
//                        player.pause()
//                        isPlaying = false
//                    }
//                }
//            }
//        }
//    }
//}
