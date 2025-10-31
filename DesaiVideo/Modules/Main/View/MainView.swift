//
//  MainView.swift
//  DesaiVideo
//
//  Created by Abylaikhan Abilkayr on 22.10.2025.
//

import SwiftUI

struct MainView: View {
    
    @ObservedObject var viewModel: MainViewModel
    
    @State var showFilter = false
    
    var body: some View {
        ZStack {
            GeometryReader { geo in
                VStack {
                    content
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .background(BackgroundView())
                .hideKeyboardOnTap()
            }
            
            if showFilter {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.25), value: showFilter)
                    .onTapGesture {
                        withAnimation {
                            showFilter = false
                        }
                    }
            }
        }
        .fullScreenCover(isPresented: $viewModel.isPaywallPresented) {
            PaywallView()
        }
        .sheet(isPresented: $showFilter) {
            FilterSheetView(
                selectedStatus: $viewModel.selectedStatus,
                selectedDuration: $viewModel.selectedDuration,
                selectedDate: $viewModel.selectedDate
            )
            .presentationDragIndicator(.hidden)
            .presentationDetents([.height(600)])
            .presentationCornerRadius(24)
        }
        .photosPicker(
            isPresented: $viewModel.isPhotoPickerPresented,
            selection: $viewModel.selectedVideo,
            matching: .videos
        )
        .fileImporter(
            isPresented: $viewModel.isFilesPickerPresented,
            allowedContentTypes: [.audio],
            allowsMultipleSelection: false
        ) { result in
            switch viewModel.selectedProcess {
            case .edit:
                viewModel.fileSelectedForEdit(result: result)
            case .transcribe:
                viewModel.fileSelectedForTranscribe(result: result)
            }
        }
        .overlay {
            if viewModel.isLoaderPresented {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.white)
                    .scaleEffect(1.5)
            }
        }
        .alert(item: $viewModel.alert) {
            $0.alert
        }
        .allowsHitTesting(!viewModel.isLoaderPresented)
        .confirmationDialog(
            "Project Actions",
            isPresented: .init(
                get: { viewModel.activeMenuProject != nil },
                set: { if !$0 { viewModel.activeMenuProject = nil } }
            ),
            titleVisibility: .hidden
        ) {
            Button("Rename", action: { viewModel.renameActiveProject() })
            Button("Share", action: { viewModel.shareActiveProject() })
            Button("Export", action: { viewModel.exportActiveProject() })
            Button("Cancel", role: .cancel) {
                viewModel.activeMenuProject = nil
            }
        }
        .sheet(item: $viewModel.shareURL) { url in
            ShareSheet(activityItems: [url])
        }
        .background(TextFieldWrapper(alert: $viewModel.renameAlert))
        .ignoresSafeArea(.keyboard)
    }
    
    private var content: some View {
        VStack(spacing: .zero) {
            topSection
                .padding(.bottom, 24)

            searchBar
                .padding(.horizontal)
                .padding(.bottom)
            

            GeometryReader { geo in
                if viewModel.filteredProjects.isEmpty {
                    VStack {
                        Spacer()
                        switch viewModel.fileType {
                        case .audio:
                            VStack(spacing: 4) {
                                Text("Empty Audio")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundStyle(.white)
                                
                                Text("Create a new clip or add \na file first")
                                    .font(.system(size: 17, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.5))
                                    .multilineTextAlignment(.center)
                            }
                        case .video:
                            VStack(spacing: 4) {
                                Text("Empty Video")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundStyle(.white)
                                
                                Text("Create a new clip or add \na file first")
                                    .font(.system(size: 17, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.5))
                                    .multilineTextAlignment(.center)
                            }
                        }
                        Spacer()
                    }
                    .frame(width: geo.size.width, height: geo.size.height)
                } else {
                    List {
                        ForEach(viewModel.filteredProjects) { project in
                            SwipeableProjectCell(
                                project: project,
                                onTap: { viewModel.open(project) },
                                onDelete: { viewModel.delete(project) },
                                onMore: { viewModel.showMenu(for: project) }
                            )
                            .listRowInsets(EdgeInsets())
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .padding(.vertical, 6)
                        }
                    }
                    .listStyle(.plain)
                    .scrollIndicators(.hidden)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 15)
                    .frame(width: geo.size.width, height: geo.size.height)
                }
            }
        }
        .navigationBarHidden(true)
        
    }
    
    private var topSection: some View {
        VStack {
            HStack(alignment: .center) {
                VStack(alignment: .leading) {
                    Text("Al Video Editing")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.white.opacity(0.5))
                    
                    Text("Transcript")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(.white)
                }
                
                Spacer()
                
                Button {
                    viewModel.goToSettings()
                } label: {
                    Image(.settingsIcon)
                        .resizable()
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal)
            .padding(.top, 10)
            .padding(.bottom, 20)
            
            SegmentedSwitchView(selectedSegment: $viewModel.fileType)
                .padding(.bottom, 20)
                .padding(.horizontal)
            
            TypeOfGenerationsView {
                viewModel.selectedProcess = .edit
                switch viewModel.fileType {
                case .audio:
                    viewModel.isFilesPickerPresented = true
                case .video:
                    viewModel.isPhotoPickerPresented = true
                }
            } tapTranscribe: {
                viewModel.selectedProcess = .transcribe
                switch viewModel.fileType {
                case .audio:
                    if PurchaseManager.shared.isSubscribed {
                        viewModel.isFilesPickerPresented = true
                    } else {
                        viewModel.isPaywallPresented = true
                    }
                case .video:
                    if PurchaseManager.shared.isSubscribed {
                        viewModel.isPhotoPickerPresented = true
                    } else {
                        viewModel.isPaywallPresented = true
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.bottom)
        }
        .background(
            UnevenRoundedRectangle(
                cornerRadii: .init(topLeading: 0, bottomLeading: 24, bottomTrailing: 24, topTrailing: 0),
                style: .continuous
            )
            .fill(.white.opacity(0.10))
            .overlay(
                BottomRoundedBorder(radius: 24)
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
    
    private var searchBar: some View {
        HStack {
            HStack(spacing: 6.fitW) {
                Image(systemName: "magnifyingglass")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 20.fitW)
                    .foregroundStyle(.white.opacity(0.7))
                
                TextField(text: $viewModel.searchText) {
                    Text("Search")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.gray676767)
                }
                .foregroundStyle(.white)
                
                Spacer(minLength: .zero)
            }
            .padding(.horizontal)
            .frame(height: 53.fitW)
            .frame(maxWidth: .infinity)
            .background(
                Color.gray414141
                    .clipShape(.rect(cornerRadius: 16.fitW))
            )
            Button {
                showFilter = true
            } label: {
                RoundedRectangle(cornerRadius: 16)
                    .fill(viewModel.filtersActive ? Color.green01A274 : Color.gray414141)
                    .frame(width: 53.fitW, height: 53.fitW)
                    .overlay {
                        Image(.filterIcon)
                            .resizable()
                            .frame(width: 22, height: 15)
                    }
            }
            .buttonStyle(.plain)
        }
    }
}
