//
//  Router.swift
//  DesaiVideo
//
//  Created by Abylaikhan Abilkayr on 28.10.2025.
//

import Foundation

enum AppRoute: Hashable {
    case videoEditing(url: URL)
    case audioEditing(url: URL)
    case videoResult(url: URL, id: UUID)
    case audioResult(url: URL, id: UUID)
    case loader(type: TaskType, id: UUID)
    case audioTranscribe(url: URL, id: UUID)
    case videoTranscribe(url: URL, id: UUID)
    case settings
}

import SwiftUI

@MainActor
final class Router: ObservableObject {

    @Published var path = NavigationPath()

    // MARK: - Navigation helpers

    func push(_ route: AppRoute) {
        path.append(route)
    }

    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func popToRoot() {
        path.removeLast(path.count)
    }

    func setRoot(_ route: AppRoute) {
        path.removeLast(path.count)
        path.append(route)
    }
}

// MARK: - Destination builder

extension Router {
    @ViewBuilder
    func destination(for route: AppRoute) -> some View {
        switch route {
        case .videoEditing(url: let url):
            VideoEditView(url: url, router: self)
        case .audioEditing(url: let url):
            AudioEditView(viewModel: AudioEditingViewModel(url: url, router: self))
        case .videoResult(url: let url, let id):
            VideoEditingResultView(url: url, router: self, id: id)
        case .audioResult(url: let url, id: let id):
            AudioResultView(viewModel: AudioResultViewModel(url: url, router: self, id: id))
        case .loader(type: let type, id: let id):
            LoaderScreen(router: self, type: type, taskId: id)
        case .audioTranscribe(url: let url, id: let id):
            AudioTranscribeView(viewModel: AudioTranscribeViewModel(url: url, router: self, id: id))
        case .videoTranscribe(url: let url, id: let id):
            VideoTranscribeView(url: url, router: self, id: id)
        case .settings:
            SettingsView(router: self)
        }
    }
}
