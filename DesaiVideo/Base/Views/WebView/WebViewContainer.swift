//
//  WebViewContainer.swift
//  TestBroadApps
//
//  Created by Abylaikhan Abilkayr on 15.10.2025.
//

import SwiftUI
import WebKit

struct WebViewContainer: View {
    let url: URL
    let title: String
    let onClose: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    onClose()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title3.bold())
                        .foregroundColor(.black)
                }
                Spacer()
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.black)
                Spacer()
                Spacer().frame(width: 24)
            }
            .padding()
            .background(Color.white)
            
            WebView(url: url)
                .ignoresSafeArea(edges: .bottom)
        }
        .background(Color.white)
        .transition(.move(edge: .bottom))
    }
}

struct WebView: UIViewRepresentable {
    let url: URL
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.load(URLRequest(url: url))
        return webView
    }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

import SafariServices

struct SafariWebView: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}
