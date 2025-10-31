//
//  AudioExtractor.swift
//  DesaiVideo
//
//  Created by Abylaikhan Abilkayr on 29.10.2025.
//

import Foundation
import AVFoundation

enum AudioExtractorError: Error {
    case noAudioTrack, exportFailed
}

struct AudioExtractor {
    static func extractAudio(from videoURL: URL) async throws -> URL {
        let asset = AVAsset(url: videoURL)
        guard let audioTrack = asset.tracks(withMediaType: .audio).first else {
            throw AudioExtractorError.noAudioTrack
        }

        let composition = AVMutableComposition()
        let compTrack = composition.addMutableTrack(withMediaType: .audio,
                                                    preferredTrackID: kCMPersistentTrackID_Invalid)
        try compTrack?.insertTimeRange(.init(start: .zero, duration: asset.duration),
                                       of: audioTrack, at: .zero)

        let outURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("m4a")

        try? FileManager.default.removeItem(at: outURL)
        guard let exporter = AVAssetExportSession(asset: composition,
                                                  presetName: AVAssetExportPresetAppleM4A) else {
            throw AudioExtractorError.exportFailed
        }
        exporter.outputURL = outURL
        exporter.outputFileType = .m4a
        exporter.shouldOptimizeForNetworkUse = true

        try await withCheckedThrowingContinuation { cont in
            exporter.exportAsynchronously {
                switch exporter.status {
                case .completed:
                    cont.resume(returning: ())
                default:
                    cont.resume(throwing: exporter.error ?? AudioExtractorError.exportFailed)
                }
            }
        }
        return outURL
    }
}
