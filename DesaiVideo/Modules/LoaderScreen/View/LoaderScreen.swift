//
//  LoaderScreen.swift
//  DesaiVideo
//
//  Created by Abylaikhan Abilkayr on 29.10.2025.
//

import SwiftUI

struct LoaderScreen: View {
    
    @StateObject var viewModel: LoaderViewModel
    
    init(router: Router, type: TaskType, taskId: UUID) {
        _viewModel = StateObject(wrappedValue: LoaderViewModel(router: router, type: type, taskId: taskId))
    }
    
    var body: some View {
        ZStack {
            VStack {
                header
                    .padding(.top)
                    .padding(.horizontal)
                    .padding(.bottom, 24)
                
                Spacer()
                
                VStack(spacing: 16) {
                    Image(image)
                        .resizable()
                        .frame(width: 133, height: 133)
                    
                }
                Spacer()
                
                VStack(spacing: 12) {
                    Text(text)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white)
                    
                    Text("Please wait, we need to apply filters.\nIt will be quick!")
                        .font(.system(size: 17, weight: .regular))
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .padding(.bottom, 20)
            }
        }
        .background(BackgroundViewForOthers())
        .navigationBarHidden(true)
    }
    
    func formattedPercentage(_ percent: Double) -> String {
        String(format: "%.0f%%", percent)
    }
    
    private var image: ImageResource {
        switch viewModel.type {
        case .videoEdit:
                .videoEditIcon
        case .videoTrans:
                .bigTransIcon
        case .audioEdit:
                .audioEditIcon
        case .audioTrans:
                .bigTransIcon
        }
    }
    
    private var text: String {
        switch viewModel.type {
        case .videoEdit:
            "Enhancing your video"
        case .videoTrans:
            "Trasncribing your video"
        case .audioEdit:
            "Enhancing your audio"
        case .audioTrans:
            "Trasncribing your audio"
        }
    }
    
    private var header: some View {
        HStack {
            Button {
                viewModel.backToMain()
            } label: {
                HStack {
                    Image(.arrowBackIcon)
                        .resizable()
                        .frame(width: 13, height: 22)
                    
                    Text("Home")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            
            Spacer()
        }
    }
}
