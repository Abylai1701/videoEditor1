//
//  ProjectCell.swift
//  DesaiVideo
//
//  Created by Abylaikhan Abilkayr on 29.10.2025.
//

import Foundation
import SwiftUI

struct ProjectCell: View {
    let project: Project
    let onTap: () -> Void
    let onDelete: () -> Void
    let onRename: () -> Void
    let onShare: () -> Void
    let onExport: () -> Void
    
    @Binding var showActions: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(mainImage)
                .resizable()
                .frame(width: 50, height: 50)
            
            mainInfo
            
            Spacer()
            
            Image(.arrowForwardIcon)
                .resizable()
                .frame(width: 8, height: 15)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
        .background(Color.white.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: showActions ? 0 : 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: showActions ? 0 : 14, style: .continuous)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
    
    private var mainImage: ImageResource {
        switch project.fileType {
        case .audio:
            switch project.taskType {
            case .editing:
                    .audioEditIcon
            case .transcribing:
                    .transIcon
            }
        case .video:
            switch project.taskType {
            case .editing:
                    .videoEditIcon
            case .transcribing:
                    .transIcon
            }
        }
    }
    
    private func formatDuration(_ duration: Double?) -> String {
        guard let duration, duration > 0 else { return "0:00" }
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private var mainInfo: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(project.name ?? "Unknown")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .lineLimit(1)
            
            HStack(spacing: 6) {
                Text(formatDuration(project.duration))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
                
                Circle()
                    .fill(.gray676767)
                    .frame(width: 4, height: 4)
                
                Text(statusTitle)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.green01A274)
            }
        }
    }
    
    private var statusTitle: String {
        if project.status != .finished {
            return "In progress"
        }
        
        switch project.taskType {
        case .editing:
            return "Original"
        case .transcribing:
            return "Transcribed"
        }
    }
}
