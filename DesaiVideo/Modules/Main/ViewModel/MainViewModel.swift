import Foundation
import PhotosUI
import SwiftUI
import Combine
import AVFoundation
import UniformTypeIdentifiers
import Photos

@MainActor
final class MainViewModel: ObservableObject {
    
    // MARK: - Published
    
    @Published var isPhotoPickerPresented = false
    @Published var selectedVideo: PhotosPickerItem?
    @Published var isFilesPickerPresented = false
    @Published var isPaywallPresented = false
    @Published var alert: AlertItem?
    @Published var isLoaderPresented = false
    @Published var fileType: Segment = .video
    @Published var selectedProcess: ProcessSegmentedControlItem = .edit
    @Published var searchText = ""
    @Published var projects: [Project] = []
    @Published var activeMenuProject: Project?

    @Published var renameAlert: TextFieldAlert? = nil

    @Published var shareURL: URL? = nil

    @Published var selectedStatus: StatusOption = .all
    @Published var selectedDuration: DurationOption = .all
    @Published var selectedDate: DateOption = .newestFirst
    
    private let purchaseManager = PurchaseManager.shared

    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Dependencies
    
    private let fileStorage: FileStorage
    private let router: Router
    private let projectManager = ProjectManager.shared
        
    // MARK: - Init
    
    init(fileStorage: FileStorage, router: Router) {
        self.fileStorage = fileStorage
        self.router = router
        setupBindings()
        loadProjects()
        
        ProjectManager.shared.checkUnfinishedTasks()
        
        checkPaywallCondition()
    }
    
    private func checkPaywallCondition() {
        if !purchaseManager.isSubscribed {
            print("🟠 Нет подписки — показываем Paywall")
            isPaywallPresented = true
        } else {
            print("🟢 У пользователя активная подписка — Paywall не показываем")
        }
    }
    // MARK: - Setup
    
    private func setupBindings() {
        $selectedVideo
            .compactMap { $0 }
            .sink { [weak self] item in
                Task { await self?.handleSelectedVideo(item: item) }
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.addObserver(
            forName: .projectsDidUpdate,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.loadProjects()
        }
    }
    
    // MARK: - Load
    
    func loadProjects() {
        projects = projectManager.fetchAll()
            .sorted(by: { $0.createdAt > $1.createdAt })
    }
    
    // MARK: - Project Actions
    
    func delete(_ project: Project) {
        guard project.status == .finished else { return }

        projectManager.delete(project)
        loadProjects()
        print("deleteProject")

    }
    
    func open(_ project: Project) {
        if project.status == .queued {
            switch project.fileType {
            case .video:
                switch project.taskType {
                case .editing:
                    router.push(.loader(type: .videoEdit, id: project.id))
                case .transcribing:
                    router.push(.loader(type: .videoTrans, id: project.id))
                }
            case .audio:
                switch project.taskType {
                case .editing:
                    router.push(.loader(type: .audioEdit, id: project.id))
                case .transcribing:
                    router.push(.loader(type: .audioTrans, id: project.id))
                }
            }
            return
        }
        
        guard project.status == .finished else { return }
        
        guard let path = project.localFilePath else { return }
        let url = URL(fileURLWithPath: path)
        
        switch project.fileType {
        case .video:
            switch project.taskType {
            case .editing:
                router.push(.videoResult(url: url, id: project.id))
            case .transcribing:
                router.push(.videoTranscribe(url: url, id: project.id))
            }

        case .audio:
            switch project.taskType {
            case .editing:
                router.push(.audioResult(url: url, id: project.id))
            case .transcribing:
                router.push(.audioTranscribe(url: url, id: project.id))
            }
        }
    }
    
    func rename(_ project: Project) {
        renameAlert = TextFieldAlert(
            title: "Rename",
            message: nil,
            placeholder: "Enter new name",
            initialText: project.name ?? "",
            onCancel: {
                print("Rename cancelled")
            },
            onSave: { newName in
                print("💾 Rename to:", newName)
                self.projectManager.updateName(for: project.id, name: newName)
                self.loadProjects()
            }
        )
    }
    
    func share(_ project: Project) {
        guard let path = project.localFilePath else {
            alert = AlertItem(
                titleText: "File not found",
                descriptionText: "The project file could not be found.",
                firstButton: .init(titleText: "OK", style: .default)
            )
            return
        }

        let url = URL(fileURLWithPath: path)
        guard FileManager.default.fileExists(atPath: url.path) else {
            alert = AlertItem(
                titleText: "Missing file",
                descriptionText: "This video file no longer exists.",
                firstButton: .init(titleText: "OK", style: .default)
            )
            return
        }

        shareURL = url
    }

    
    func export(_ project: Project) {
        guard let path = project.localFilePath else {
            alert = AlertItem(
                titleText: "File not found",
                descriptionText: "The project file could not be found.",
                firstButton: .init(titleText: "OK", style: .default)
            )
            return
        }
        
        let url = URL(fileURLWithPath: path)
        guard FileManager.default.fileExists(atPath: url.path) else {
            alert = AlertItem(
                titleText: "Missing file",
                descriptionText: "This file no longer exists.",
                firstButton: .init(titleText: "OK", style: .default)
            )
            return
        }

        switch project.fileType {
        case .video:
            exportVideoToGallery(url: url)
        case .audio:
            exportAudioToFiles(url: url)
        }
    }

    
    func showMenu(for project: Project) {
        guard project.status == .finished else { return }

        activeMenuProject = project
        print("ShowMenu")
    }
    
    func renameActiveProject() {
        guard let project = activeMenuProject else { return }
        rename(project)
    }
    
    func shareActiveProject() {
        guard let project = activeMenuProject else { return }
        share(project)
    }
    
    func exportActiveProject() {
        guard let project = activeMenuProject else { return }
        export(project)
    }
    func goToSettings() {
        router.push(.settings)
    }
    
    // MARK: - File Pickers
    
    private func handleSelectedVideo(item: PhotosPickerItem) async {
        selectedVideo = nil
        isLoaderPresented = true
        defer { isLoaderPresented = false }
        
        do {
            guard let videoItem = try await item.loadTransferable(type: VideoItem.self) else { return }
            switch selectedProcess {
            case .edit:
                router.push(.videoEditing(url: videoItem.url))
            case .transcribe:
                generateVideoTranscribe(url: videoItem.url)
            }
        } catch {
            alert = AlertItem(
                titleText: "Error",
                descriptionText: "Error loading video",
                firstButton: AlertItemButton(titleText: "Ok", style: .default)
            )
        }
    }
    
    func fileSelectedForEdit(result: Result<[URL], any Error>) {
        Task { @MainActor in
            isLoaderPresented = true
            defer { isLoaderPresented = false }
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                guard url.startAccessingSecurityScopedResource() else { return }
                defer { url.stopAccessingSecurityScopedResource() }
                do {
                    let fileURL = try fileStorage.copyFile(
                        from: url,
                        to: .temporary,
                        with: UUID().uuidString + "." + url.pathExtension
                    )
                    router.push(.audioEditing(url: fileURL))
                } catch {
                    showError("Error selecting file")
                }
            case .failure:
                showError("Error importing file")
            }
        }
    }
    
    func fileSelectedForTranscribe(result: Result<[URL], any Error>) {
        Task { @MainActor in
            isLoaderPresented = true
            defer { isLoaderPresented = false }
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                guard url.startAccessingSecurityScopedResource() else { return }
                defer { url.stopAccessingSecurityScopedResource() }
                print("Start transcription for file \(url.lastPathComponent)")
                let fileURL = try fileStorage.copyFile(
                    from: url,
                    to: .temporary,
                    with: UUID().uuidString + "." + url.pathExtension
                )
                generateAudioTranscribe(url: fileURL)
            case .failure:
                showError("Error importing file")
            }
        }
    }
    
    // MARK: - Helpers
    
    private func exportVideoToGallery(url: URL) {
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized || status == .limited else {
                Task { @MainActor in
                    self.alert = AlertItem(
                        titleText: "Access Denied",
                        descriptionText: "Please allow photo library access in Settings to export videos.",
                        firstButton: .init(titleText: "OK", style: .default)
                    )
                }
                return
            }

            UISaveVideoAtPathToSavedPhotosAlbum(url.path, nil, nil, nil)
            Task { @MainActor in
                self.alert = AlertItem(
                    titleText: "Exported",
                    descriptionText: "Your video has been saved to the Photos app.",
                    firstButton: .init(titleText: "OK", style: .default)
                )
            }
        }
    }

    private func exportAudioToFiles(url: URL) {
        Task { @MainActor in
            self.shareURL = url // покажет системный share sheet (включая “Save to Files”)
        }
    }

    private func showError(_ message: String) {
        alert = AlertItem(
            titleText: "Error",
            descriptionText: message,
            firstButton: .init(titleText: "OK", style: .default)
        )
    }
}

extension MainViewModel {
    func generateAudioTranscribe(url: URL) {
        Task {
            do {
                let asset = AVAsset(url: url)
                let durationInSeconds = CMTimeGetSeconds(asset.duration)
                                
                // 2️⃣ Отправляем аудио на сервер
                let response = try await NetworkManager.shared.createTask(
                    fileURL: url,
                    fileType: "audio/m4a",
                    summarize: true,
                    soundStudio: true,
                    socialContent: false,
                    exportTimestamps: false,
                    removeDeadAir: false,
                    muted: false,
                    transcription: true,
                    removeFillerWords: false,
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
                    taskType: .transcribing,
                    localFilePath: permanentURL.path,
                    duration: durationInSeconds
                )
                
                guard let id = UUID(uuidString: response.id) else {
                    print("❌ Invalid backend ID")
                    return
                }
                
                // ✅ 5️⃣ Переход на LoaderScreen
                await MainActor.run {
                    router.push(.loader(type: .audioTrans, id: id))
                }
                
                // 4️⃣ Запускаем поллинг (ожидание результата)
                if let id = UUID(uuidString: response.id) {
                    await TaskPoller.shared.startPolling(
                        id: id,
                        interval: 5,
                        timeout: 600,
                        fileType: .audio,
                        taskType: .transcribing,
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
    
    func generateVideoTranscribe(url: URL) {
        Task {
            do {
                let asset = AVAsset(url: url)
                let durationInSeconds = CMTimeGetSeconds(asset.duration)
                
                let audioURL = try await AudioExtractor.extractAudio(from: url)

                // 2️⃣ Отправляем аудио на сервер
                let response = try await NetworkManager.shared.createTask(
                    fileURL: audioURL,
                    fileType: "audio/m4a",
                    summarize: true,
                    soundStudio: false,
                    socialContent: false,
                    exportTimestamps: false,
                    removeDeadAir: false,
                    muted: false,
                    transcription: true,
                    removeFillerWords: false,
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
                    fileType: .video,
                    taskType: .transcribing,
                    localFilePath: permanentURL.path,
                    duration: durationInSeconds
                )
                
                guard let id = UUID(uuidString: response.id) else {
                    print("❌ Invalid backend ID")
                    return
                }
                
                // ✅ 5️⃣ Переход на LoaderScreen
                await MainActor.run {
                    router.push(.loader(type: .videoTrans, id: id))
                }
                
                // 4️⃣ Запускаем поллинг (ожидание результата)
                if let id = UUID(uuidString: response.id) {
                    await TaskPoller.shared.startPolling(
                        id: id,
                        interval: 5,
                        timeout: 600,
                        fileType: .video,
                        taskType: .transcribing,
                        localFilePath: url.path,
                        duration: durationInSeconds
                    ) { taskId in
                        try await NetworkManager.shared.fetchTaskStatus(taskId: taskId)
                    }
                }
                
                print("✅ Video generation started for \(url.lastPathComponent)")
            } catch {
                print("❌ Video generation failed:", error)
            }
        }
    }
}

extension MainViewModel {
    var filteredProjects: [Project] {
        projects
            .filterByFileType(fileType)
            .filterByFilters(selectedStatus, selectedDuration, selectedDate)
            .filterBySearch(searchText)
    }
}

extension MainViewModel {
    var filtersActive: Bool {
        selectedStatus != .all ||
        selectedDuration != .all ||
        selectedDate != .newestFirst
    }
}
