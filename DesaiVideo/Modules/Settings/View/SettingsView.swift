//
//  SettingsView.swift
//  DesaiVideo
//
//  Created by Abylaikhan Abilkayr on 31.10.2025.
//

import SwiftUI
import StoreKit

struct SettingsView: View {
    
    @State private var showWebView = false
    @State private var webTitle = ""
    @State private var webURL: URL? = nil
    @State private var showAlert = false
    @State private var showProAlert = false
    @State private var showPaywall = false

    var router: Router
    
    init(router: Router) {
        self.router = router
    }
    var body: some View {
        ZStack {
            content
        }
        .background(BackgroundView())
        .fullScreenCover(isPresented: $showWebView) {
            if let webURL {
                SafariWebView(url: webURL)
            }
        }
        .alert(isPresented: $showAlert) {
            return Alert(
                title: Text("App version"),
                message: Text("1.0"),
                dismissButton: .default(Text("OK"))
            )
        }
        .alert(isPresented: $showProAlert) {
            return Alert(
                title: Text("You have full access to all features!"),
                message: Text(""),
                dismissButton: .default(Text("OK"))
            )
        }
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallView()
        }
        .navigationBarHidden(true)
    }
    
    private var content: some View {
        VStack {
            header
                .padding(.top, 12)
                .padding(.horizontal)
                .padding(.bottom, 24)
            
            sections
                .padding(.horizontal)
            Spacer()
        }
    }
    
    
    private var sections: some View {
        VStack(spacing: 14) {
            createButton(.access)
            createButton(.version)
            createButton(.share)
            createButton(.feedback)
            createButton(.privacy)
        }
    }
    private var header: some View {
        HStack {
            Button {
                router.popToRoot()
            } label: {
                HStack {
                    Image(.arrowBackIcon)
                        .resizable()
                        .frame(width: 13, height: 22)
                    
                    Text("Back")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            
            Spacer()
        }
        .overlay {
            Text("Settings")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)
        }
    }
    
    private func createButton(_ type: SettingsButtonType) -> some View {
        Button {
            switch type {
            case .access:
                if PurchaseManager.shared.isSubscribed {
                    showProAlert = true
                } else {
                    showPaywall = true
                }
            case .version:
                showAlert = true
            case .share:
                shareApp()
            case .feedback:
                requestReviewOrOpenStore()
            case .privacy:
                webTitle = "Privacy Policy"
                webURL = URL(string: "https://docs.google.com/document/d/13uGesrn26h7sXhLzqbY9s_UVuw01IfQwOqIVZK1MxbI/edit?tab=t.0#heading=h.9k1agz8dd6mn")
                showWebView = true
            }
        } label: {
            RoundedRectangle(cornerRadius: 10)
                .fill(.white.opacity(0.1))
                .frame(maxWidth: .infinity)
                .frame(height: 74)
                .overlay {
                    HStack(spacing: 10) {
                        Image(type.image)
                            .resizable()
                            .frame(width: 42, height: 42)
                        
                        Text(type.title)
                            .font(.system(size: 16.fitW, weight: .semibold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                        
                        Spacer(minLength: 0)
                        
                        if type == .access {
                            HStack(spacing: 6) {
                                Text(PurchaseManager.shared.isSubscribed ? "Pro" : "Basic")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.5))
                                
                                Image(.arrowForwardIcon)
                                    .resizable()
                                    .frame(width: 10, height: 20)
                            }
                            .padding(.trailing)
                        }
                    }
                    .padding(.leading)
                }
        }
        .buttonStyle(.plain)
    }
    
    func requestReviewOrOpenStore() {
        if let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }) {
            SKStoreReviewController.requestReview(in: scene)
        }
    }
    
    func shareApp() {
        let appURL = URL(string: "https://apps.apple.com/us/app/transcripta/id6754630620")! 
        
        let message = """
        ✨ Check out Desai Video — AI-powered video editor and transcription tool!
        Download here: \(appURL.absoluteString)
        """

        let activityVC = UIActivityViewController(activityItems: [message], applicationActivities: nil)
        
        // Для iPad (чтобы не упало на .popoverPresentationController == nil)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = scene.keyWindow?.rootViewController {
            activityVC.popoverPresentationController?.sourceView = rootVC.view
            rootVC.present(activityVC, animated: true)
        }
    }

}

enum SettingsButtonType {
    case access
    case version
    case share
    case feedback
    case privacy
    
    var image: ImageResource {
        switch self {
        case .access:
                .set1
        case .version:
                .set2
        case .share:
                .set3
        case .feedback:
                .set4
        case .privacy:
                .set5
        }
    }
    
    var title: String {
        switch self {
        case .access:
            "Current version"
        case .version:
            "App version"
        case .share:
            "Share Transcript & AI Video Editing"
        case .feedback:
            "Feedback"
        case .privacy:
            "Privacy Policy"
        }
    }
}
