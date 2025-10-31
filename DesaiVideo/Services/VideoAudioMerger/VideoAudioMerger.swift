//
//  VideoAudioMerger.swift
//  DesaiVideo
//
//  Created by Abylaikhan Abilkayr on 29.10.2025.
//

import Foundation
import AVFoundation

enum VideoAudioMergeError: Error {
    case exportFailed
}

struct VideoAudioMerger {
    static func merge(videoURL: URL, with audioURL: URL) async throws -> URL {
        let composition = AVMutableComposition()

        // 1️⃣ Получаем исходный видео ассет
        let videoAsset = AVURLAsset(url: videoURL)
        guard let videoAssetTrack = videoAsset.tracks(withMediaType: .video).first else {
            throw NSError(domain: "VideoMerger", code: -1, userInfo: [NSLocalizedDescriptionKey: "No video track found"])
        }

        // 2️⃣ Добавляем видео-трек
        let videoTrack = composition.addMutableTrack(
            withMediaType: .video,
            preferredTrackID: kCMPersistentTrackID_Invalid
        )
        try videoTrack?.insertTimeRange(
            CMTimeRange(start: .zero, duration: videoAsset.duration),
            of: videoAssetTrack,
            at: .zero
        )

        // ⚙️ 3️⃣ Критически важно: сохранить ориентацию
        videoTrack?.preferredTransform = videoAssetTrack.preferredTransform

        // 4️⃣ Добавляем новое аудио
        let audioAsset = AVURLAsset(url: audioURL)
        if let audioAssetTrack = audioAsset.tracks(withMediaType: .audio).first {
            let audioTrack = composition.addMutableTrack(
                withMediaType: .audio,
                preferredTrackID: kCMPersistentTrackID_Invalid
            )
            try audioTrack?.insertTimeRange(
                CMTimeRange(start: .zero, duration: videoAsset.duration),
                of: audioAssetTrack,
                at: .zero
            )
        }

        // 5️⃣ Экспорт результата
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).mp4")
        if FileManager.default.fileExists(atPath: outputURL.path) {
            try FileManager.default.removeItem(at: outputURL)
        }

        guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
            throw NSError(domain: "VideoMerger", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to create export session"])
        }

        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        exportSession.shouldOptimizeForNetworkUse = true

        try await withCheckedThrowingContinuation { continuation in
            exportSession.exportAsynchronously {
                switch exportSession.status {
                case .completed:
                    continuation.resume(returning: outputURL)
                case .failed, .cancelled:
                    continuation.resume(throwing: exportSession.error ?? NSError(domain: "VideoMerger", code: -3))
                default:
                    break
                }
            }
        }
        return outputURL
    }
}
