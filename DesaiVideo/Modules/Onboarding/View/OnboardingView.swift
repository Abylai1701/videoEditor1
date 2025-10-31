//
//  OnboardingView.swift
//  DesaiVideo
//
//  Created by Abylaikhan Abilkayr on 23.10.2025.
//

import SwiftUI

struct OnboardingView: View {
        
    @State private var myPage: OnbEnum = .onb1
    var closeOnboard: () -> Void

    var body: some View {
            ZStack {
                GeometryReader { geo in
                    Image(myPage.image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width)
                }
                .ignoresSafeArea()
            }
            .overlay(alignment: .bottom) {
                Image(.bottomOnb)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 300)
            }
            .overlay(alignment: .bottom) {
                bottomView(_for: myPage)
            }
    }
    
    @ViewBuilder
    private func bottomView(_for page: OnbEnum) -> some View {
        VStack(spacing: .zero) {
            Text(page.title1)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.white)
                .padding(.bottom, 2)

            Text(page.title2)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.green01A274)
                .padding(.bottom, 8)
            

            Text(page.description)
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.bottom)
                .padding(.horizontal, page == .onb3 ? 79.fitW : 0)
            Button {
                switch page {
                case .onb1:
                    myPage = .onb2
                case .onb2:
                    myPage = .onb3
                case .onb3:
                    myPage = .onb4
                case .onb4:
                    closeOnboard()
                }
            } label: {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.green01A274)
                    .frame(height: 54)
                    .overlay {
                        Text(page.continueTitle)
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(.white)
                    }
            }
            .buttonStyle(.plain)
            .padding(.bottom, 24)
        }
        .padding(.horizontal)
    }
}
