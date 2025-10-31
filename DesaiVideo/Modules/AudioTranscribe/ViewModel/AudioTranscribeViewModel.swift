//
//  AudioTranscribeViewModel.swift
//  DesaiVideo
//
//  Created by Abylaikhan Abilkayr on 30.10.2025.
//

import Foundation
import AVFoundation

@MainActor
final class AudioTranscribeViewModel: ObservableObject {
    
    let url: URL
    private let router: Router
    private let id: UUID
    let audioEffectViewModel = AudioEffectViewModel()
    var transcriptions: [Transcription] = []
    
    init(url: URL, router: Router, id: UUID) {
        self.url = url
        self.router = router
        self.id = id
        
        if let transcriptions = self.fetchProject()?.transcriptions {
            self.transcriptions = transcriptions
        }
    }
    
    
    func pop() {
        router.popToRoot()
    }
    
    private func fetchProject() -> Project? {
        if let project = ProjectManager.shared.fetchByIdSync(id) {
            return project
        }
        return nil
    }
}
