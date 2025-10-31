//
//  AudioResultView.swift
//  DesaiVideo
//
//  Created by Abylaikhan Abilkayr on 29.10.2025.
//

import SwiftUI
import AVFoundation

struct AudioResultView: View {
    
    @StateObject var viewModel: AudioResultViewModel
    @State private var isPlaying = false
    @State private var showFilters = false
    @StateObject private var playerVM: AudioPlayerViewModel
    
    init(viewModel: AudioResultViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
        _playerVM = StateObject(wrappedValue: AudioPlayerViewModel(url: viewModel.url))
    }
    
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
            .onAppear {
                playerVM.play() // сразу запускаем
                isPlaying = true
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
            
            Spacer()
            
            audioPlayer
                .frame(height: 110)
            
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
            .frame(height: 160)
            .frame(maxWidth: .infinity)
            .background(VisualEffectBlur(style: .regular))
            .overlay {
                VStack(spacing: 14) {
                    AudioTimebar(playerVM: playerVM)
                        .padding(.horizontal)
                    
                    controlButtons
                        .frame(width: 220)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 22))
    }
    
    private var controlButtons: some View {
        HStack {
            Button {
                seek(by: -10)
            } label: {
                Image(.tenSecBackIcon)
                    .resizable()
                    .frame(width: 36, height: 36)
            }
            
            Spacer()
            
            Button {
                togglePlayback()
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
                seek(by: 10)
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
                    Text(viewModel.getname() ?? viewModel.url.lastPathComponent)
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
            
            Button {
                showFilters = true
            } label: {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.gray414141)
                    .stroke(Color.green01A274.opacity(0.5), lineWidth: 2)
                    .frame(width: 40, height: 40)
                    .overlay {
                        Image(.resetIcon)
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
            Text("Track")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white)
        }
    }
    
    private var audioPlayer: some View {
        AudioEffectView(viewModel: viewModel.audioEffectViewModel)
            .onChange(of: isPlaying) { _, playing in
                viewModel.audioEffectViewModel.setAnimating(playing)
            }
    }
    
    // MARK: - Player Logic
    
    private func togglePlayback() {
        if isPlaying {
            playerVM.pause()
            viewModel.audioEffectViewModel.setAnimating(false)
        } else {
            playerVM.play()
            viewModel.audioEffectViewModel.setAnimating(true)
        }
        isPlaying.toggle()
    }
    
    private func seek(by seconds: Double) {
        let newTime = max(0, min(playerVM.duration, playerVM.current + seconds))
        playerVM.seek(to: newTime)
    }
}
