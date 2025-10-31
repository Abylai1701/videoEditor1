//
//  VideoEditView.swift
//  DesaiVideo
//
//  Created by Abylaikhan Abilkayr on 28.10.2025.
//

import SwiftUI
import AVFoundation

struct VideoEditView: View {
    
    @StateObject private var viewModel: VideoEditViewModel

    init(url: URL, router: Router) {
        _viewModel = StateObject(wrappedValue: VideoEditViewModel(url: url, router: router))
    }
    
    @State private var isPlaying = false
    @State private var showFullscreen = false
    @State private var player: AVPlayer = AVPlayer()
    @State private var showFilters = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                content
                if showFilters {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.25), value: showFilters)
                        .onTapGesture {
                            withAnimation {
                                showFilters = false
                            }
                        }
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .background(BackgroundViewForOthers())
            .hideKeyboardOnTap()
            .onAppear {
                configurePlayerIfNeeded()
            }
            .onDisappear {
                isPlaying = false
            }
            .fullScreenCover(isPresented: $showFullscreen) {
                SimpleVideoView(player: player)
            }
            .sheet(isPresented: $showFilters) {
                EnhanceSheetView { options in
                    viewModel.generate(with: options)
                }
                .presentationDragIndicator(.hidden)
                .presentationDetents([.height(600)])
                .presentationCornerRadius(24)
            }
            .fullScreenCover(isPresented: $viewModel.showPaywall) {
                PaywallView()
            }
            .navigationBarHidden(true)
        }
    }
    
    private var content: some View {
        VStack {
            header
                .padding(.top)
                .padding(.horizontal)
                .padding(.bottom, 24)
            
            nameView
                .padding(.bottom)
            
            Text("Enhanced")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.white.opacity(0.5))
                .padding(.bottom)
            
            SimpleVideoPlayer(player: player, isPlaying: $isPlaying) {
                showFullscreen = true
            }
            .padding(.horizontal)

            Spacer()
            
            bottomControl
                .padding(.horizontal)
                .padding(.bottom, 22)
        }
    }
    
    private var bottomControl: some View {
        RoundedRectangle(cornerRadius: 22)
            .fill(.clear)
            .stroke(Color.white.opacity(0.3), lineWidth: 2)
            .frame(height: 110)
            .frame(maxWidth: .infinity)
            .background(VisualEffectBlur(style: .regular))
            .overlay {
                controlButtons
                    .frame(width: 220)
            }
            .clipShape(RoundedRectangle(cornerRadius: 22))
    }
    
    private var controlButtons: some View {
        HStack {
            Button {
                NotificationCenter.default.post(name: .seekBackward10, object: nil)
            } label: {
                Image(.tenSecBackIcon)
                    .resizable()
                    .frame(width: 36, height: 36)
            }

            Spacer()
            
            Button {
                isPlaying.toggle()
            } label: {
                Image(.playPauseIcon)
                    .resizable()
                    .frame(width: 66, height: 66)
                    .overlay {
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 58, height: 58)
                    }
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            Button {
                NotificationCenter.default.post(name: .seekForward10, object: nil)
            } label: {
                Image(.tenSecForwardIcon)
                    .resizable()
                    .frame(width: 36, height: 36)
            }
        }

    }
    private var nameView: some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 12)
                .fill(.gray414141)
                .stroke(Color.green01A274.opacity(0.5), lineWidth: 2)
                .frame(width: 219, height: 40)
                .overlay {
                    Text(viewModel.url.lastPathComponent)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(width: 177)
                        .lineLimit(1)
                }
            
            Button {
                showFilters = true
            } label: {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.gray414141)
                    .stroke(Color.green01A274.opacity(0.5), lineWidth: 2)
                    .frame(width: 40, height: 40)
                    .overlay {
                        Image(.penIcon)
                            .resizable()
                            .frame(width: 18, height: 18)
                    }
            }
            .buttonStyle(.plain)
        }
    }
    private var header: some View {
        HStack {
            Button {
                viewModel.pop()
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
            Text("Video")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white)
        }
    }
    
    private func configurePlayerIfNeeded() {
        player.replaceCurrentItem(with: AVPlayerItem(url: viewModel.url))
    }
}
