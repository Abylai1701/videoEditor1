//
//  PaywallView.swift
//  DesaiVideo
//
//  Created by Abylaikhan Abilkayr on 24.10.2025.
//

import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    
    @ObservedObject private var viewModel = PurchaseManager.shared
    
    @State private var selectedSubscriptionID: String = "yearly_39.99_nottrial"
    
    @State private var showWebView = false
    @State private var webTitle = ""
    @State private var webURL: URL? = nil
    @State private var showCloseButton = false
    
    var body: some View {
        ZStack(alignment: .topTrailing) { // теперь можно разместить крестик в углу
            GeometryReader { geo in
                Image(.pay)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width)
            }
            .ignoresSafeArea()
            
            VStack {
                Image(.pay1)
                    .resizable()
                    .scaledToFit()
                
                Image(.pay2)
                    .resizable()
                    .scaledToFit()
                Spacer()
                
                bottomView
            }
            
            if showCloseButton {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(.white)
                        .shadow(radius: 4)
                        .padding(.top, 50)
                        .padding(.trailing, 24)
                }
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.3), value: showCloseButton)
            }
        }
        .fullScreenCover(isPresented: $showWebView) {
            if let webURL {
                SafariWebView(url: webURL)
            }
        }
        .alert(item: $viewModel.alert) { alert in
            if alert.message == "Purchase success" {
                return Alert(
                    title: Text("Purchase success"),
                    message: Text(""),
                    dismissButton: .default(Text("OK")) {
                        dismiss()
                        ApphudUserManager.shared.saveCurrentUserIfNeeded()
                    }
                )
            } else {
                return Alert(
                    title: Text("Please try again later..."),
                    message: Text(alert.message),
                    dismissButton: .default(Text("OK")) {
                        viewModel.alert = nil
                    }
                )
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                withAnimation {
                    showCloseButton = true
                }
            }
        }
    }
    
    private var bottomView: some View {
        VStack(spacing: .zero) {
            
            VStack(spacing: 5) {
                Text("Get Full Access")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
                Text("Audio & Video edit without linites")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
            }
            .padding(.bottom)
            
            subButtons
                .padding(.bottom, 20)
            
            Text("Cancel anytime")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white.opacity(0.5))
                .padding(.bottom, 8)
            
            Button {
                Task {
                    await handleContinueTap()
                }
            } label: {
                RoundedRectangle(cornerRadius: 16.fitH)
                    .fill(.green01A274)
                    .frame(height: 54.fitH)
                    .overlay {
                        Text("Continue")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(.white)
                    }
            }
            .buttonStyle(.plain)
            .padding(.bottom)
            
            legacyButtons
                .frame(maxWidth: .infinity)
                .padding(.bottom, 6.fitH)
                .padding(.horizontal)
        }
        .padding(.horizontal)
        .padding(.top, 10)
        .background(
            UnevenRoundedRectangle(
                cornerRadii: .init(topLeading: 24, bottomLeading: 0, bottomTrailing: 0, topTrailing: 24),
                style: .continuous
            )
            .fill(.white.opacity(0.10))
            .overlay(
                TopRoundedBorder(radius: 24)
                    .stroke(
                        Color.white.opacity(0.2),
                        style: StrokeStyle(
                            lineWidth: 1,
                            lineCap: .round,
                            lineJoin: .round
                        )
                    )
            )
            .ignoresSafeArea()
        )
    }
    
    private func handleContinueTap() async {
        guard let product = viewModel.subscriptions.first(where: { $0.productId == selectedSubscriptionID }) else {
            print("❌ Продукт не найден в Apphud Subscriptions")
            return
        }
        print("🟢 Покупаем: \(product.productId)")
        await viewModel.purchaseSubscription(product)
    }
    
    private var legacyButtons: some View {
        PaywallBottomLegalButtons { action in
            switch action {
                
            case .terms:
                webTitle = "Terms of Use"
                webURL = URL(string: "https://docs.google.com/document/d/1YAAqPb8oqaKomiqlUOtDuHJrbK6xL4VToKcSjvjwNr4/edit?tab=t.0#heading=h.l97jy7i87fdb")
                withAnimation { showWebView = true }
            case .restore:
                Task {
                    await viewModel.restore()
                }
            case .privacy:
                webTitle = "Privacy Policy"
                webURL = URL(string: "https://docs.google.com/document/d/13uGesrn26h7sXhLzqbY9s_UVuw01IfQwOqIVZK1MxbI/edit?tab=t.0#heading=h.9k1agz8dd6mn")
                withAnimation { showWebView = true }
            }
        }
    }
    
    private var subButtons: some View {
        VStack(spacing: 8) {
            SubscriptionOptionView(
                title: "Weekly",
                subtitle: "Cancel anytime",
                price: "$4.99 / week",
                isSelected: selectedSubscriptionID == "week_4.99_nottrial")
            .onTapGesture {
                selectedSubscriptionID = "week_4.99_nottrial"
            }
            
            SubscriptionOptionView(
                title: "Annual",
                subtitle: "Best offer",
                price: "$39.99",
                isSelected: selectedSubscriptionID == "yearly_39.99_nottrial")
            .onTapGesture {
                selectedSubscriptionID = "yearly_39.99_nottrial"
            }
        }
    }
}


#Preview {
    PaywallView()
}
