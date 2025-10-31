//
//  VideoTranscribeViewModel.swift
//  DesaiVideo
//
//  Created by Abylaikhan Abilkayr on 30.10.2025.
//

import Foundation
import AVFoundation

@MainActor
final class VideoTranscribeViewModel: ObservableObject {
    
    let url: URL
    private var router: Router
    let id: UUID
    var transcriptions: [Transcription] = []

    init(url: URL, router: Router, id: UUID) {
        self.url = url
        self.router = router
        self.id = id
        
        if let transcriptions = self.fetchProject()?.transcriptions {
            self.transcriptions = transcriptions
        }
    }
    
    @MainActor
    func pop() {
        router.popToRoot()
    }
    
    private func fetchProject() -> Project? {
        if let project = ProjectManager.shared.fetchByIdSync(id) {
            return project
        }
        return nil
    }
    func getname() -> String? {
        if let project = ProjectManager.shared.fetchByIdSync(id) {
            return project.name
        } else {
            return nil
        }
    }
}
