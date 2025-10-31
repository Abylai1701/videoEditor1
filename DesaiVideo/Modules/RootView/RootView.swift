//
//  RootView.swift
//  DesaiVideo
//
//  Created by Abylaikhan Abilkayr on 31.10.2025.
//

import SwiftUI

struct RootView: View {
    
    @StateObject private var router = Router()
    @StateObject private var mainVM: MainViewModel

    @AppStorage("onboardingСompleted") private var onboardingCompleted = false
    @State private var showOnboarding = false
    
    init() {
        let fileStorage = FileStorage()
        let tempRouter = Router()
        _mainVM = StateObject(wrappedValue: MainViewModel(fileStorage: fileStorage, router: tempRouter))
        _router = StateObject(wrappedValue: tempRouter)
    }

    var body: some View {
        
        ZStack {
            if onboardingCompleted {
                NavigationStack(path: $router.path) {
                    MainView(viewModel: mainVM)
                        .navigationDestination(for: AppRoute.self) { route in
                            router.destination(for: route)
                        }
                }
            } else {
                OnboardingView {
                    onboardingCompleted = true
                    withAnimation(.easeInOut) {
                        showOnboarding = false
                    }
                }
            }
        }
    }
}
