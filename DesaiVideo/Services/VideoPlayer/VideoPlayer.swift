//
//  VideoPlayer.swift
//  DesaiVideo
//
//  Created by Abylaikhan Abilkayr on 23.10.2025.
//

import SwiftUI
import AVFoundation
import AVKit

// MARK: - View

struct SimpleVideoPlayer: View {
    @StateObject private var vm: PlayerVM
    var onFullscreen: (() -> Void)?
    @Binding var isPlayingExternal: Bool

    func play() { vm.play() }
    func pause() { vm.pause() }
    func togglePlay() { vm.togglePlay() }
    func seekForward10() { vm.seekBy(seconds: 10) }
    func seekBackward10() { vm.seekBy(seconds: -10) }
    
    init(url: URL, isPlaying: Binding<Bool>, onFullscreen: (() -> Void)? = nil) {
        _vm = StateObject(wrappedValue: PlayerVM(url: url))
        self.onFullscreen = onFullscreen
        self._isPlayingExternal = isPlaying
    }

    init(player: AVPlayer, isPlaying: Binding<Bool>, onFullscreen: (() -> Void)? = nil) {
        _vm = StateObject(wrappedValue: PlayerVM(player: player))
        self._isPlayingExternal = isPlaying
        self.onFullscreen = onFullscreen
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color(.gray.opacity(0.2)), lineWidth: 2)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.black)
                )
            
            PlayerLayerView(player: vm.player)
                .clipShape(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                )
                .overlay( // затемнение снизу для читаемости
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.3)],
                        startPoint: .center, endPoint: .bottom
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                )
            
            VStack {
                HStack {
                    Spacer()
                    Button(action: { onFullscreen?() }) {
                        Image(.fullScreenIcon)
                            .resizable()
                            .frame(width: 36, height: 36)
                    }
                }
                .padding()
                Spacer()
            }
            
            // Низ: таймлайн и время
            VStack(spacing: 8) {
                ProgressBar(
                    progress: vm.progress,       // 0...1
                    buffered: vm.buffered,       // 0...1 (по желанию)
                    onScrub: { frac in vm.seekFraction(frac) },
                    onScrubBegan: { vm.pauseForScrub() },
                    onScrubEnded: { vm.resumeAfterScrub() }
                )
                .frame(height: 22)
                .padding(.horizontal, 14)
                
                HStack {
                    Text(format(vm.current))  // текущее время
                    Spacer()
                    Text(format(vm.duration)) // длительность
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.95))
                .padding(.horizontal, 14)
                .padding(.bottom, 10)
            }
        }
        .onChange(of: vm.isPlaying) { _, newValue in
            isPlayingExternal = newValue
        }
        .onChange(of: isPlayingExternal) { _, extVal in
            if extVal != vm.isPlaying {
                extVal ? vm.play() : vm.pause()
            }
        }
        .frame(height: 220)
        .onDisappear { vm.cleanup() }
    }
    
    private func format(_ seconds: Double) -> String {
        guard seconds.isFinite else { return "--:--" }
        let s = Int(seconds.rounded())
        return String(format: "%02d:%02d", s/60, s%60)
    }
}


final class PlayerVM: ObservableObject {
    let player: AVPlayer

    @Published var isPlaying: Bool = false
    @Published var current: Double = 0
    @Published var duration: Double = 0
    @Published var progress: Double = 0
    @Published var buffered: Double = 0

    private var timeObs: Any?
    private var endObs: NSObjectProtocol?
    private var wasPlayingBeforeScrub = false
    private var statusObs: NSKeyValueObservation?
    private var itemStatusObs: NSKeyValueObservation?
    private var durationCheckTimer: Timer?
    private var currentItemObs: NSKeyValueObservation?

    // MARK: - Init
    init(url: URL) {
        self.player = AVPlayer()
        configure()

        let item = AVPlayerItem(url: url)
        self.player.replaceCurrentItem(with: item)
        self.observeItem(item)
    }

    init(player: AVPlayer) {
        self.player = player
        configure()

        if let item = player.currentItem {
            observeItem(item)
        }
    }

    // MARK: - Config
    private func configure() {
        player.actionAtItemEnd = .pause
        addObservers()

        // 🔹 Раньше: разовая проверка if let item = player.currentItem { observeItem(item) }
        // 🔹 Теперь: наблюдаем появление/смену currentItem
        currentItemObs = player.observe(\.currentItem, options: [.new, .initial]) { [weak self] player, _ in
            guard let self else { return }
            if let item = player.currentItem {
                self.observeItem(item)           // тут внутри мы грузим duration (через loadValuesAsynchronously)
            }
        }

        statusObs = player.observe(\.timeControlStatus, options: [.new, .initial]) { [weak self] player, _ in
            guard let self else { return }
            DispatchQueue.main.async {
                self.isPlaying = (player.timeControlStatus == .playing)
            }
        }
    }


    // MARK: - Observe item
    private func observeItem(_ item: AVPlayerItem) {
        // ✅ Периодически проверяем duration, пока он не станет числом
        durationCheckTimer?.invalidate()
        durationCheckTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] timer in
            guard let self else { return }
            let d = item.duration.seconds
            if d.isFinite, d > 0 {
                self.duration = d
                timer.invalidate()
            }
        }

        itemStatusObs = item.observe(\.status, options: [.new, .initial]) { [weak self] item, _ in
            guard let self else { return }
            if item.status == .readyToPlay {
                let d = item.asset.duration.seconds
                if d.isFinite {
                    DispatchQueue.main.async { self.duration = d }
                }
            }
        }
    }

    // MARK: - Observers
    private func addObservers() {
        timeObs = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.1, preferredTimescale: 600),
            queue: .main
        ) { [weak self] t in
            guard let self else { return }
            current = t.seconds
            if let d = player.currentItem?.duration.seconds, d.isFinite, d > 0 {
                duration = d
                progress = max(0, min(1, current / d))
            }

            if let range = player.currentItem?.loadedTimeRanges.first?.timeRangeValue {
                let bufferedEnd = CMTimeGetSeconds(range.start + range.duration)
                if duration > 0 { buffered = max(0, min(1, bufferedEnd / duration)) }
            }
        }

        endObs = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: nil, queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            self.pause()
            self.seek(to: 0)
        }

        NotificationCenter.default.addObserver(
            forName: .seekBackward10, object: nil, queue: .main
        ) { [weak self] _ in self?.seekBy(seconds: -10) }

        NotificationCenter.default.addObserver(
            forName: .seekForward10, object: nil, queue: .main
        ) { [weak self] _ in self?.seekBy(seconds: 10) }
    }

    // MARK: - Controls
    func play() { player.play(); isPlaying = true }
    func pause() { player.pause(); isPlaying = false }
    func togglePlay() { isPlaying ? pause() : play() }

    func pauseForScrub() {
        wasPlayingBeforeScrub = isPlaying
        pause()
    }
    func resumeAfterScrub() {
        if wasPlayingBeforeScrub { play() }
    }

    func seekFraction(_ frac: Double) {
        guard duration > 0 else { return }
        seek(to: duration * frac)
    }

    func seek(to seconds: Double) {
        let cm = CMTime(seconds: seconds, preferredTimescale: 600)
        player.seek(to: cm, toleranceBefore: .zero, toleranceAfter: .zero)
    }

    func seekBy(seconds delta: Double) {
        guard duration > 0 else { return }
        let newTime = max(0, min(duration, current + delta))
        seek(to: newTime)
    }

    // MARK: - Cleanup
    func cleanup() {
        if let t = timeObs { player.removeTimeObserver(t) }
        timeObs = nil
        if let endObs { NotificationCenter.default.removeObserver(endObs) }
        endObs = nil

        statusObs?.invalidate()
        statusObs = nil
        
        itemStatusObs?.invalidate()
        itemStatusObs = nil

        durationCheckTimer?.invalidate()
        durationCheckTimer = nil
        
        currentItemObs?.invalidate()
        currentItemObs = nil
    }

    deinit { cleanup() }
}


struct PlayerLayerView: UIViewRepresentable {
    let player: AVPlayer
    
    func makeUIView(context: Context) -> PlayerUIView {
        let v = PlayerUIView()
        v.playerLayer.player = player
        v.playerLayer.videoGravity = .resizeAspectFill
        return v
    }
    func updateUIView(_ uiView: PlayerUIView, context: Context) {
        uiView.playerLayer.player = player
    }
}

final class PlayerUIView: UIView {
    override static var layerClass: AnyClass { AVPlayerLayer.self }
    var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
}
//
//#Preview {
//    ZStack {
//        Color.white.ignoresSafeArea()
//        VStack {
//            if let url = Bundle.main.url(forResource: "demo", withExtension: "mp4") {
//                SimpleVideoPlayer(url: url)
//                    .padding()
//            }
//
//        }
//    }
//}

import AVKit

struct SimpleVideoView: View {
    let player: AVPlayer
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .topLeading) {
            VideoPlayer(player: player)
                .ignoresSafeArea()
                .background(Color.black)

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.white)
                    .shadow(radius: 6)
                    .padding(.top, 40)
                    .padding(.leading, 20)
            }
        }
    }
}
