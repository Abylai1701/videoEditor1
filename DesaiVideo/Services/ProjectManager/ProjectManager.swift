//
//  ProjectManager.swift
//  DesaiVideo
//
//  Created by Abylaikhan Abilkayr on 23.10.2025.
//

import SwiftData
import Foundation

// MARK: - ProjectManager

@MainActor
final class ProjectManager {
    static let shared = ProjectManager()
    
    private let context: ModelContext
    
    private init() {
        // Инициализация SwiftData контейнера
        context = try! ModelContext(
            ModelContainer(for: Project.self, Transcription.self, SummaryChapter.self)
        )
    }
    
    // MARK: - Project Creation
    
    /// Создание проекта при получении `queued` от бэка
    func createQueuedProject(
        response: BackendResponse,
        fileType: Project.FileType,
        taskType: Project.TaskType,
        localFilePath: String?,
        duration: Double?
    ) {
        guard let id = UUID(uuidString: response.id) else { return }
        
        if let existing = try? fetchById(id), existing != nil {
            print("⚠️ Project already exists with id: \(id)")
            return
        }
        
        let project = Project(
            id: id,
            fileType: fileType,
            taskType: taskType,
            status: .queued,
            duration: duration,
            localFilePath: localFilePath
        )
        
        context.insert(project)
        save()
        print("📦 Created project (queued) id: \(id)")
    }
    
    // MARK: - Status Handling
    
    /// Обрабатывает ответ от бэка и обновляет Project в SwiftData
    
    func handleBackendResponse(
        _ response: BackendResponse,
        fileType: Project.FileType,
        taskType: Project.TaskType,
        localFilePath: String?,
        duration: Double?
    ) {        
        guard let id = UUID(uuidString: response.id) else {
            print("❌ Invalid UUID in response")
            return
        }

        // Если проекта нет — создаём при queued
        if (try? fetchById(id)) == nil, response.status == "queued" {
            createQueuedProject(
                response: response,
                fileType: fileType,
                taskType: taskType,
                localFilePath: localFilePath,
                duration: duration
            )
            return
        }
        
        switch response.status {
        case "started":
            updateStatus(for: id, to: .started)
            
        case "failed":
            updateStatus(for: id, to: .failed)
            
        case "finished":
            updateStatus(for: id, to: .finished)
            updateResult(for: id, result: response.result)

            Task {
                do {
                    // 0) Снимок полей ДО любого await
                    guard let snap = await MainActor.run(body: { self.snapshot(for: id) }) else { return }
                    let fileType = snap.fileType
                    var localPath = snap.localFilePath // можно менять локальную переменную
                    // let taskType = snap.taskType // если понадобится
                    // let duration = snap.duration  // если понадобится

                    // 1) Проверяем result
                    guard let urlStr = response.result,
                          let remoteURL = URL(string: urlStr) else {
                        // нет результата → уведомим и удалим по id
                        NotificationCenter.default.post(name: .cancelTask, object: nil, userInfo: ["id": id])
                        await MainActor.run { self.deleteById(id) }
                        return
                    }

                    // 2) Качаем файл (await — уже безопасно, модель мы не трогаем)
                    let downloadedFile = try await NetworkManager.shared.downloadFile(from: remoteURL.absoluteString)

                    switch fileType {
                    case .video:
                        // 3) Работаем с локальной копией пути, а не с project
                        if let path = localPath, !FileManager.default.fileExists(atPath: path) {
                            // пробуем восстановить по id
                            let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                            let restored = docs.appendingPathComponent("Projects/\(id.uuidString).mp4")
                            if FileManager.default.fileExists(atPath: restored.path) {
                                print("♻️ Restored missing video file for \(id)")
                                localPath = restored.path
                                await MainActor.run {
                                    self.updateLocalPath(for: id, path: restored.path)
                                }
                            } else {
                                print("⚠️ Video file not found anywhere for \(id)")
                                // можно послать cancel / удалить проект
                                NotificationCenter.default.post(name: .cancelTask, object: nil, userInfo: ["id": id])
                                await MainActor.run { self.deleteById(id) }
                                return
                            }
                        }

                        guard let path = localPath else {
                            print("❌ No local video path for project \(id)")
                            return
                        }

                        // 4) Мердж (тяжёлый await — всё ещё безопасно)
                        let videoURL = URL(fileURLWithPath: path)
                        let mergedURL = try await VideoAudioMerger.merge(videoURL: videoURL, with: downloadedFile)
                        let permanentURL = try moveToPersistentStorage(fileURL: mergedURL, id: id)

                        // 5) Обновляем модель ТОЛЬКО через методы по id
                        await MainActor.run {
                            self.updateLocalPath(for: id, path: permanentURL.path)
                            self.updateName(for: id, name: permanentURL.lastPathComponent)
                            self.save()
                            print("✅ Video merged and saved at: \(permanentURL.lastPathComponent)")
                        }

                    case .audio:
                        let permanentURL = try self.moveAudioToPersistentStorage(fileURL: downloadedFile, id: id)
                        await MainActor.run {
                            self.updateLocalPath(for: id, path: permanentURL.path)
                            self.updateName(for: id, name: permanentURL.lastPathComponent)
                            self.save()
                            print("✅ Audio saved at: \(permanentURL.lastPathComponent)")
                        }
                    }

                    // 6) UI уведомления
                    NotificationCenter.default.post(name: .taskDidFinish, object: nil, userInfo: ["id": id])

                    // 7) Транскрипции/главы — только методами по id (они @MainActor)
                    if let trans = response.transcriptions {
                        await MainActor.run {
                            self.updateTranscriptions(for: id, transcriptions: trans.map {
                                Transcription(speaker: $0.speaker, text: $0.text, start: $0.start, end: $0.end)
                            })
                        }
                    }
                    if let chapters = response.summaryChapters {
                        await MainActor.run {
                            self.updateChapters(for: id, chapters: chapters.map {
                                SummaryChapter(start: $0.start, title: $0.title)
                            })
                        }
                    }

                } catch {
                    print("❌ Failed to process response for \(id):", error)
                    await MainActor.run { self.updateStatus(for: id, to: .failed) }
                }
            }

        default:
            print("⚠️ Unknown status: \(response.status)")
        }
    }
    
    
    
    private func moveToPersistentStorage(fileURL: URL, id: UUID) throws -> URL {
        let fileManager = FileManager.default
        
        // Используем .documentDirectory — безопасное хранилище, не очищается системой
        let documentsDir = try fileManager.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        
        let projectsDir = documentsDir.appendingPathComponent("Projects", isDirectory: true)
        if !fileManager.fileExists(atPath: projectsDir.path) {
            try fileManager.createDirectory(at: projectsDir, withIntermediateDirectories: true)
        }
        
        var destinationURL = projectsDir.appendingPathComponent("\(id.uuidString).mp4")
        
        // Если уже есть — удаляем старый
        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }
        
        // ✅ 1. Сначала копируем во "вечно живой" Documents
        try fileManager.copyItem(at: fileURL, to: destinationURL)
        
        // ✅ 2. Теперь безопасно удаляем tmp-оригинал
        if fileManager.fileExists(atPath: fileURL.path) {
            try? fileManager.removeItem(at: fileURL)
            print("🧹 Removed temporary merged file at \(fileURL.lastPathComponent)")
        }
        
        // ✅ 3. Помечаем, чтобы файл не удалялся системой
        var resourceValues = URLResourceValues()
        resourceValues.isExcludedFromBackup = false // true = не включать в iCloud backup
        try destinationURL.setResourceValues(resourceValues)
        
        print("📁 Video saved permanently at: \(destinationURL.path)")
        return destinationURL
    }
    
    
    private func moveAudioToPersistentStorage(fileURL: URL, id: UUID) throws -> URL {
        let fileManager = FileManager.default
        
        let documentsDir = try fileManager.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        
        let projectsDir = documentsDir.appendingPathComponent("Projects", isDirectory: true)
        if !fileManager.fileExists(atPath: projectsDir.path) {
            try fileManager.createDirectory(at: projectsDir, withIntermediateDirectories: true)
        }
        
        var destinationURL = projectsDir.appendingPathComponent("\(id.uuidString).mp3")
        
        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }
        
        try fileManager.copyItem(at: fileURL, to: destinationURL)
        
        var resourceValues = URLResourceValues()
        resourceValues.isExcludedFromBackup = false
        try destinationURL.setResourceValues(resourceValues)
        
        print("📁 Audio saved permanently at: \(destinationURL.path)")
        return destinationURL
    }
    
    
    // MARK: - CRUD Operations
    
    func fetchAll() -> [Project] {
        let descriptor = FetchDescriptor<Project>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        var projects = (try? context.fetch(descriptor)) ?? []
        
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        for project in projects {
            guard let path = project.localFilePath else { continue }
            
            if !FileManager.default.fileExists(atPath: path) {
                var recovered: URL?
                
                switch project.fileType {
                case .video:
                    let videoPath = docs.appendingPathComponent("Projects/\(project.id.uuidString).mp4")
                    if FileManager.default.fileExists(atPath: videoPath.path) {
                        recovered = videoPath
                        print("♻️ Restored video file for \(project.id)")
                    }
                    
                case .audio:
                    let audioPath = docs.appendingPathComponent("Projects/\(project.id.uuidString).mp3")
                    if FileManager.default.fileExists(atPath: audioPath.path) {
                        recovered = audioPath
                        print("♻️ Restored audio file for \(project.id)")
                    }
                }
                
                if let recovered {
                    project.localFilePath = recovered.path
                    save()
                } else {
                    print("⚠️ Missing file for project \(project.id)")
                }
            }
        }
        
        return projects
    }
        
    func updateStatus(for id: UUID, to status: Project.Status) {
        guard let project = try? fetchById(id) else { return }
        project.status = status
        if status == .failed {
            delete(project)
        } else {
            save()
        }
    }
    
    func updateResult(for id: UUID, result: String?) {
        guard let project = try? fetchById(id) else { return }
        project.result = result
        save()
    }
    
    func updateName(for id: UUID, name: String?) {
        guard let project = try? fetchById(id) else { return }
        project.name = name
        save()
    }
    
    func updateTranscriptions(for id: UUID, transcriptions: [Transcription]) {
        guard let project = try? fetchById(id) else { return }
        project.transcriptions = transcriptions
        save()
    }
    
    func updateChapters(for id: UUID, chapters: [SummaryChapter]) {
        guard let project = try? fetchById(id) else { return }
        project.summaryChapters = chapters
        save()
    }
    
    func delete(_ project: Project) {
        context.delete(project)
        save()
    }
    
    func deleteOldProject(for id: UUID) {
        guard let project = try? fetchById(id) else { return }
        delete(project)
    }
    
    // MARK: - Private Helpers
    
    private func fetchById(_ id: UUID) throws -> Project? {
        let descriptor = FetchDescriptor<Project>(
            predicate: #Predicate { $0.id == id }
        )
        return try context.fetch(descriptor).first
    }
    
    private func save() {
        do {
            try context.save()
            NotificationCenter.default.post(name: .projectsDidUpdate, object: nil)
        } catch {
            print("❌ Failed to save context: \(error)")
        }
    }
    
    // Локальный value-тип, чтобы не таскать за собой живую модель
    private struct ProjectSnapshot {
        let fileType: Project.FileType
        let taskType: Project.TaskType
        let localFilePath: String?
        let duration: Double?
    }

    @MainActor
    private func snapshot(for id: UUID) -> ProjectSnapshot? {
        guard let p = try? fetchById(id) else { return nil }
        return ProjectSnapshot(
            fileType: p.fileType,
            taskType: p.taskType,
            localFilePath: p.localFilePath,
            duration: p.duration
        )
    }

    func updateLocalPath(for id: UUID, path: String) {
        guard let project = try? fetchById(id) else { return }
        project.localFilePath = path
        save()
    }

    func deleteById(_ id: UUID) {
        guard let project = try? fetchById(id) else { return }
        delete(project)
    }
}

extension ProjectManager {
    /// Проверяет незавершённые задачи (queued / started)
    /// и автоматически перезапускает их поллинг.
    func checkUnfinishedTasks() {
        Task { [weak self] in
            guard let self else { return }

            let unfinished = fetchAll().filter {
                $0.status == .queued || $0.status == .started
            }

            guard !unfinished.isEmpty else {
                print("✅ Нет незавершённых задач")
                return
            }

            print("⚠️ Найдены незавершённые задачи: \(unfinished.count)")

            for project in unfinished {
                guard let id = project.id as UUID?,
                      let path = project.localFilePath else { continue }

                let url = URL(fileURLWithPath: path)
                let duration = project.duration ?? 0

                // Запускаем заново TaskPoller для этого проекта
                await TaskPoller.shared.startPolling(
                    id: id,
                    interval: 5,
                    timeout: 600,
                    fileType: project.fileType,
                    taskType: project.taskType,
                    localFilePath: path,
                    duration: duration
                ) { taskId in
                    try await NetworkManager.shared.fetchTaskStatus(taskId: taskId)
                }

                print("🔁 Возобновлён поллинг для задачи \(id)")
            }
        }
    }
}


extension ProjectManager {
    func fetchByIdSync(_ id: UUID) -> Project? {
        let descriptor = FetchDescriptor<Project>(
            predicate: #Predicate { $0.id == id }
        )
        return try? context.fetch(descriptor).first
    }
}

// MARK: - Ensure Permanent Copy of Input File
extension ProjectManager {
    /// Перемещает или копирует исходный файл (аудио/видео) в Documents/Projects.
    /// Возвращает постоянный URL, пригодный для хранения в `localFilePath`.
    func moveSourceToPersistentStorage(sourceURL: URL, id: UUID, fileType: Project.FileType) throws -> URL {
        let fileManager = FileManager.default
        let documentsDir = try fileManager.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        
        let projectsDir = documentsDir.appendingPathComponent("Projects", isDirectory: true)
        if !fileManager.fileExists(atPath: projectsDir.path) {
            try fileManager.createDirectory(at: projectsDir, withIntermediateDirectories: true)
        }
        
        let ext = (fileType == .video) ? "mp4" : "m4a"
        let destination = projectsDir.appendingPathComponent("\(id.uuidString).\(ext)")
        
        // Если файл временный (tmp), копируем
        if sourceURL.path.contains("/tmp/") {
            if fileManager.fileExists(atPath: destination.path) {
                try fileManager.removeItem(at: destination)
            }
            try fileManager.copyItem(at: sourceURL, to: destination)
            print("📦 Copied temp file to permanent: \(destination.lastPathComponent)")
        } else {
            // Если уже в Documents — просто возвращаем
            if !fileManager.fileExists(atPath: destination.path) {
                try fileManager.copyItem(at: sourceURL, to: destination)
            }
        }
        
        return destination
    }
}

extension ProjectManager {
    func fetchSafeCopyById(_ id: UUID) -> (fileType: Project.FileType, taskType: Project.TaskType, localFilePath: String?)? {
        guard let project = fetchByIdSync(id) else { return nil }
        return (project.fileType, project.taskType, project.localFilePath)
    }
}

