import SwiftUI
import AVFoundation

struct AudioTranscribeView: View {
    
    @StateObject var viewModel: AudioTranscribeViewModel
    @State private var isPlaying = false
    @StateObject private var player: AudioProgressPlayer
    
    init(viewModel: AudioTranscribeViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
        _player = StateObject(wrappedValue: AudioProgressPlayer(url: viewModel.url))
    }
    
    var body: some View {
        ZStack {
            BackgroundViewForOthers()
            
            VStack(spacing: 0) {
                header
                    .padding(.top, 16)
                    .padding(.horizontal)
                    .padding(.bottom, 38)
                
                HStack(spacing: 14) {
                    Button {
                        togglePlayback()
                    } label: {
                        Circle()
                            .fill(Color.green01A274)
                            .frame(width: 44, height: 44)
                            .overlay {
                                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundStyle(.white)
                                    .padding(.leading, isPlaying ? 0 : 4)
                            }
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()

                    DynamicWaveformView(progress: player.progress)
                        .frame(height: 44)
                        .frame(maxWidth: .infinity)
                    
                    Spacer()
                }
                .padding(6)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.1))
                )
                .padding(.horizontal)
                .padding(.bottom, 24)
                
                Text("Transcript")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.green01A274)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                
                if !viewModel.transcriptions.isEmpty {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {
                            ForEach(viewModel.transcriptions.indices, id: \.self) { i in
                                TranscriptBubbleView(transcription: viewModel.transcriptions[i])
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 30)
                        .padding(.top)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.1))
                    )
                    .padding(.horizontal)
                } else {
                    Spacer(minLength: 0)

                    Text("Transcriptions not found")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(.white)
                }
                
                Spacer(minLength: 0)
            }
        }
        .onAppear {
            player.play()
            isPlaying = true
        }
        .navigationBarHidden(true)
    }
    
    // MARK: - Header
    private var header: some View {
        HStack {
            Button {
                viewModel.pop()
            } label: {
                HStack {
                    Image(.arrowBackIcon)
                        .resizable()
                        .frame(width: 13, height: 22)
                    Text("Back")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            Spacer()
        }
        .overlay {
            Text("Track")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white)
        }
    }
    
    // MARK: - Player Logic
    private func togglePlayback() {
        if isPlaying {
            player.pause()
        } else {
            player.play()
        }
        isPlaying.toggle()
    }
}


struct TranscriptBubbleView: View {
    let transcription: Transcription
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("\(formatTime(transcription.start)) → \(formatTime(transcription.end))")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.green01A274)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(Color.green01A274.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                Spacer()
            }
            
            Text(transcription.text)
                .font(.system(size: 15))
                .foregroundStyle(.white.opacity(0.9))
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func formatTime(_ seconds: Double) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}

struct DynamicWaveformView: View {
    /// Прогресс воспроизведения (0.0 ... 1.0)
    var progress: Double
    
    private let barCount = 50
    private let heights: [CGFloat]
    
    init(progress: Double) {
        self.progress = progress
        // Генерируем статичный, устойчивый набор высот (одинаковый при каждом создании)
        self.heights = DynamicWaveformView.generateHeights(count: barCount)
    }
    
    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<barCount, id: \.self) { index in
                let ratio = Double(index) / Double(barCount)
                Capsule()
                    .fill(ratio <= progress ? Color.green01A274 : Color.grayEBECF5)
                    .frame(width: 2, height: heights[index])
            }
        }
        .animation(.easeInOut(duration: 0.15), value: progress)
    }
    
    // MARK: - Helpers
    
    private static func generateHeights(count: Int) -> [CGFloat] {
        // Слегка случайная, но сбалансированная волна (одинаковая при каждом запуске)
        var rng = SeededRandomGenerator(seed: 12345)
        var values: [CGFloat] = []
        for i in 0..<count {
            let base: CGFloat = 10
            let variation = CGFloat.random(in: 8...38, using: &rng)
            let smoothWave = sin(Double(i) / 4) * 10 + 20
            values.append(base + variation * 0.3 + CGFloat(smoothWave * 0.6))
        }
        return values
    }
}

// MARK: - Seeded Random (чтобы форма волны всегда одинаковая)
struct SeededRandomGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { self.state = seed }
    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1
        return state
    }
}


import Foundation
import AVFoundation

final class AudioProgressPlayer: ObservableObject {
    private var player: AVAudioPlayer?
    private var timer: Timer?
    
    @Published var progress: Double = 0
    
    init(url: URL) {
        setupPlayer(url: url)
    }
    
    private func setupPlayer(url: URL) {
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay()
        } catch {
            print("❌ Failed to load audio:", error)
        }
    }
    
    func play() {
        player?.play()
        startTimer()
    }
    
    func pause() {
        player?.pause()
        stopTimer()
    }
    
    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self, let player else { return }
            self.progress = player.currentTime / player.duration
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}
