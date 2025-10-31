//
//  SwipeableProjectCell.swift
//  DesaiVideo
//
//  Created by Abylaikhan Abilkayr on 29.10.2025.
//

import Foundation
import SwiftUI

struct SwipeableProjectCell: View {
    let project: Project
    let onTap: () -> Void
    let onDelete: () -> Void
    let onMore: () -> Void
    
    @GestureState private var dragOffset: CGFloat = 0
    @State private var offset: CGFloat = 0
    @State private var isOpen = false

    private let buttonWidth: CGFloat = 73
    private let maxSwipe: CGFloat = 146   // две кнопки по 73
    private let swipeThreshold: CGFloat = 60

    var body: some View {
        ZStack(alignment: .trailing) {
            // Фон с кнопками (под ячейкой)
            HStack(spacing: 0) {
                Button {
                    closeSwipe()
                    onDelete()
                } label: {
                    Rectangle()
                        .fill(.gray.opacity(0.4))
                        .frame(width: buttonWidth, height: 73)
                        .overlay {
                            Image(.trashIcon)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 26, height: 26)
                        }
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())

                Button {
                    closeSwipe()
                    onMore()
                } label: {
                    UnevenRoundedRectangle( cornerRadii: .init(topLeading: 0, bottomLeading: 0, bottomTrailing: 14, topTrailing: 14), style: .continuous )
                        .fill(.gray.opacity(0.7))
                        .frame(width: buttonWidth, height: 73)
                        .overlay {
                            Image(.dotsIcon)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 26, height: 26)
                        }
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
            }
            .opacity(min(1, abs(offset + dragOffset) / maxSwipe))
            .animation(.easeInOut(duration: 0.2), value: offset)
            
            // Основная ячейка
            ProjectCell(
                project: project,
                onTap: {
                    if isOpen {
                        closeSwipe()
                    } else {
                        onTap()
                    }
                },
                onDelete: onDelete,
                onRename: {},
                onShare: {},
                onExport: {},
                showActions: $isOpen
            )
            .background(Color.white.opacity(0.0001)) // важно — позволяет hit-тест
            .offset(x: offset + dragOffset)
            // внутри ProjectCell
            .simultaneousGesture(
                DragGesture(minimumDistance: 10, coordinateSpace: .local)
                    .onChanged { value in
                        let dx = value.translation.width
                        let dy = value.translation.height
                        // реагируем только на горизонтальный свайп
                        guard abs(dx) > abs(dy) else { return }

                        if dx < 0 {
                            // открываем (влево)
                            offset = max(-maxSwipe, dx)
                            isOpen = true
                        } else {
                            // закрываем (вправо), если уже было открыто
                            if isOpen {
                                offset = min(0, dx - maxSwipe)
                            } else {
                                offset = 0
                            }
                        }
                    }
                    .onEnded { value in
                        let dx = value.translation.width
                        let dy = value.translation.height
                        guard abs(dx) > abs(dy) else { return }

                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            if dx <= -swipeThreshold {
                                offset = -maxSwipe
                                isOpen = true
                            } else {
                                offset = 0
                                isOpen = false
                            }
                        }
                    }
            )

            .onTapGesture {
                if isOpen {
                    closeSwipe()
                } else {
                    onTap()
                }
            }
            .allowsHitTesting(true)
        }
        .frame(height: 73)
        .contentShape(Rectangle())
    }

    private func closeSwipe() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            offset = 0
            isOpen = false
        }
    }
}
