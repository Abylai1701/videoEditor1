//
//  AudioEditingViewModel.swift
//  DesaiVideo
//
//  Created by Abylaikhan Abilkayr on 28.10.2025.
//

import Foundation
import AVFoundation

@MainActor
final class AudioEditingViewModel: ObservableObject {
    
    @Published var showPaywall: Bool = false

    let url: URL
    private let router: Router
    let audioEffectViewModel = AudioEffectViewModel()
    
    init(url: URL, router: Router) {
        self.url = url
        self.router = router
        print("🎧 Audio file URL: \(url)")
    }
    
    func pop() {
        router.pop()
    }
    
    func generate(with options: EnhanceOptions) {
        
        if !PurchaseManager.shared.isSubscribed {
            showPaywall = true
            return
        }
        
        Task {
            do {
                let asset = AVAsset(url: url)
                let durationInSeconds = CMTimeGetSeconds(asset.duration)
                
                // 1️⃣ Подготавливаем аудио (в случае, если это не .m4a)
                let audioURL = try await prepareAudioForUpload(from: url)
                
                // 2️⃣ Отправляем аудио на сервер
                let response = try await NetworkManager.shared.createTask(
                    fileURL: audioURL,
                    fileType: "audio/m4a",
                    summarize: true,
                    soundStudio: options.soundStudioFlag,
                    socialContent: false,
                    exportTimestamps: false,
                    removeDeadAir: options.trimLongPauses,
                    muted: false,
                    transcription: true,
                    removeFillerWords: options.removeFillerWords,
                    merge: false,
                    video: false,
                    exportFormat: "mp3"
                )
                
                let permanentURL = try ProjectManager.shared.moveSourceToPersistentStorage(
                    sourceURL: url,
                    id: UUID(uuidString: response.id) ?? UUID(),
                    fileType: .video
                )
                // 3️⃣ Создаём локальный проект
                ProjectManager.shared.createQueuedProject(
                    response: response,
                    fileType: .audio,
                    taskType: .editing,
                    localFilePath: permanentURL.path,
                    duration: durationInSeconds
                )
                
                guard let id = UUID(uuidString: response.id) else {
                    print("❌ Invalid backend ID")
                    return
                }
                
                // ✅ 5️⃣ Переход на LoaderScreen
                await MainActor.run {
                    router.push(.loader(type: .audioEdit, id: id))
                }
                
                // 4️⃣ Запускаем поллинг (ожидание результата)
                if let id = UUID(uuidString: response.id) {
                    await TaskPoller.shared.startPolling(
                        id: id,
                        interval: 5,
                        timeout: 600,
                        fileType: .audio,
                        taskType: .editing,
                        localFilePath: url.path,
                        duration: durationInSeconds
                    ) { taskId in
                        try await NetworkManager.shared.fetchTaskStatus(taskId: taskId)
                    }
                }
                
                print("✅ Audio generation started for \(url.lastPathComponent)")
            } catch {
                print("❌ Audio generation failed:", error)
            }
        }
    }
    
    // MARK: - Private helpers
    
    /// Если аудио не в формате .m4a — конвертируем
    private func prepareAudioForUpload(from url: URL) async throws -> URL {
        let ext = url.pathExtension.lowercased()
        if ext == "m4a" {
            return url
        }
        // Можно добавить логику перекодирования, если требуется
        return url
    }
}
