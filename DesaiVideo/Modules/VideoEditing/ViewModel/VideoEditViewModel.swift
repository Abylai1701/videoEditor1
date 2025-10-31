//
//  VideoEditViewModel.swift
//  DesaiVideo
//
//  Created by Abylaikhan Abilkayr on 28.10.2025.
//

import Foundation
import AVFoundation

@MainActor
final class VideoEditViewModel: ObservableObject {
    
    @Published var showPaywall = false

    let url: URL
    private var router: Router
    
    init(url: URL, router: Router) {
        self.url = url
        self.router = router
        
        print("Мой URL \(url)")
    }
    
    @MainActor
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
                
                // 1️⃣ Извлекаем аудио
                let audioURL = try await AudioExtractor.extractAudio(from: url)
                
                // 2️⃣ Отправляем на сервер
                let resp = try await NetworkManager.shared.createTask(
                    fileURL: audioURL,
                    fileType: "audio/m4a",
                    summarize: true,
                    soundStudio: options.soundStudioFlag,
                    socialContent: false,
                    exportTimestamps: false,
                    removeDeadAir: options.trimLongPauses,
                    muted: true,
                    transcription: true,
                    removeFillerWords: options.removeFillerWords,
                    merge: false,
                    video: false,
                    exportFormat: "mp3"
                )
                
                let permanentURL = try ProjectManager.shared.moveSourceToPersistentStorage(
                    sourceURL: url,
                    id: UUID(uuidString: resp.id) ?? UUID(),
                    fileType: .video
                )
                
                // 3️⃣ Создаём локальный проект
                ProjectManager.shared.createQueuedProject(
                    response: resp,
                    fileType: .video,
                    taskType: .editing,
                    localFilePath: permanentURL.path,
                    duration: durationInSeconds
                )
                
                guard let id = UUID(uuidString: resp.id) else {
                    print("❌ Invalid backend ID")
                    return
                }
                
                // ✅ 5️⃣ Переход на LoaderScreen
                await MainActor.run {
                    router.push(.loader(type: .videoEdit, id: id))
                }
                
                // 4️⃣ Запускаем поллинг
                if let id = UUID(uuidString: resp.id) {
                    await TaskPoller.shared.startPolling(
                        id: id,
                        interval: 5,
                        timeout: 600,
                        fileType: .video,
                        taskType: .editing,
                        localFilePath: url.path,
                        duration: durationInSeconds
                    ) { taskId in
                        try await NetworkManager.shared.fetchTaskStatus(taskId: taskId)
                    }
                }
            } catch {
                print("❌ Generate failed:", error)
            }
        }
    }
}
