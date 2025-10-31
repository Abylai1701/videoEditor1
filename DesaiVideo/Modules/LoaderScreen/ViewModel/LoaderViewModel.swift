//
//  LoaderViewModel.swift
//  DesaiVideo
//
//  Created by Abylaikhan Abilkayr on 29.10.2025.
//

import Foundation


enum TaskType {
    case videoEdit
    case videoTrans
    case audioEdit
    case audioTrans
}

final class LoaderViewModel: ObservableObject {
    
    private var router: Router
    var type: TaskType
    let slowFactor: Double
    
    @Published var progress: Double = 0
    @Published var isFinished = false
    @Published var alert: AlertItem?
    
    private var observer: NSObjectProtocol?
    private var observerForCancel: NSObjectProtocol?
    var taskId: UUID
    
    init(router: Router, type: TaskType, taskId: UUID) {
        self.router = router
        self.type = type
        self.taskId = taskId
        slowFactor = (type == .videoEdit) ? 10 : 5
        
        observer = NotificationCenter.default.addObserver(
            forName: .taskDidFinish,
            object: nil,
            queue: .main
        ) { [weak self] notif in
            guard let self else { return }
            guard let id = notif.userInfo?["id"] as? UUID else { return }
            if id == self.taskId {
                self.goToResult(with: id)
            }
        }
        
        observerForCancel = NotificationCenter.default.addObserver(
            forName: .cancelTask,
            object: nil,
            queue: .main
        ) { [weak self] notif in
            guard let self else { return }
            guard let id = notif.userInfo?["id"] as? UUID else { return }
            if id == self.taskId {
                self.handleCancellation()
            }
        }
    }
    
    deinit {
        if let observer {
            NotificationCenter.default.removeObserver(observer)
        }
        
        if let observerForCancel {
            NotificationCenter.default.removeObserver(observerForCancel)
        }
    }
    
    @MainActor
    func backToMain() {
        router.popToRoot()
    }
    
    private func handleCancellation() {
        Task { @MainActor in
            alert = AlertItem(
                titleText: "Processing Interrupted",
                descriptionText: "Something went wrong while enhancing your file.",
                firstButton: .init(
                    titleText: "OK",
                    style: .default,
                    action: { [weak self] in
                        // 3️⃣ Возврат на главный экран после подтверждения
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            self?.backToMain()
                        }
                    }
                )
            )
        }
    }
    
    @MainActor
    func goToResult(with id: UUID) {
        switch type {
        case .videoEdit:
            if let project = ProjectManager.shared.fetchByIdSync(id),
               let path = project.localFilePath {
                router.push(.videoResult(url: URL(fileURLWithPath: path), id: id))
            }
        case .audioEdit:
            if let project = ProjectManager.shared.fetchByIdSync(id),
               let path = project.localFilePath {
                router.push(.audioResult(url: URL(fileURLWithPath: path), id: id))
            }
        case .audioTrans:
            if let project = ProjectManager.shared.fetchByIdSync(id),
               let path = project.localFilePath {
                router.push(.audioTranscribe(url: URL(fileURLWithPath: path), id: id))
            }
        case .videoTrans:
            if let project = ProjectManager.shared.fetchByIdSync(id),
               let path = project.localFilePath {
                router.push(.videoTranscribe(url: URL(fileURLWithPath: path), id: id))
            }
            print("DDDD")
        }
    }
}
