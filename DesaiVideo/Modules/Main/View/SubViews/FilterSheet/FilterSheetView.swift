//
//  FilterSheetView.swift
//  DesaiVideo
//
//  Created by Abylaikhan Abilkayr on 22.10.2025.
//

import SwiftUI

struct FilterSheetView: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var selectedStatus: StatusOption
    @Binding var selectedDuration: DurationOption
    @Binding var selectedDate: DateOption

    var body: some View {
        ZStack {
            
            VisualEffectBlur(style: .systemUltraThinMaterial)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                Capsule()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 51, height: 5)
                    .padding(.top, 8)
                
                Text("Filter")
                    .font(.headline)
                    .foregroundStyle(.white)
                
                FilterSection(
                    title: "Status",
                    systemImage: "tag",
                    options: StatusOption.allCases,
                    selected: $selectedStatus
                )
                .padding(.bottom, 8)
                
                FilterSection(
                    title: "Duration",
                    systemImage: "clock",
                    options: DurationOption.allCases,
                    selected: $selectedDuration
                )
                .padding(.bottom, 8)
                
                FilterSection(
                    title: "Date",
                    systemImage: "calendar",
                    options: DateOption.allCases,
                    selected: $selectedDate
                )
                .padding(.bottom)
                
                Button {
                    print("Applied: \(selectedStatus), \(selectedDuration), \(selectedDate)")
                    dismiss()
                } label: {
                    Text("Apply")
                        .font(.system(size: 17, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .foregroundColor(.black)
                }
                .buttonStyle(.plain)
                .padding(.bottom, 24)
            }
            .padding(.horizontal)
        }
        .background(ClearBackground())
        .overlay {
            TopRoundedBorder(radius: 24)
                .stroke(
                    Color.white,
                    style: StrokeStyle(
                        lineWidth: 2,
                        lineCap: .round,
                        lineJoin: .round
                    )
                )
        }
    }
}

struct FilterSection<Option: FilterOption>: View {
    let title: String
    let systemImage: String
    let options: [Option]
    @Binding var selected: Option

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: systemImage)
                    .resizable()
                    .frame(width: 22, height: 22)
                    .foregroundStyle(.green01A274)

                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(options, id: \.self) { option in
                    Button {
                        withAnimation(.snappy) {
                            selected = option
                        }
                    } label: {
                        HStack {
                            Circle()
                                .strokeBorder(
                                    selected == option ? Color.green01A274 : .grayBDBDBD,
                                    lineWidth: 2
                                )
                                .frame(width: 18, height: 18)
                            
                            Text(option.title)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(.white)
                            Spacer()
                        }
                        .padding()
                        .frame(height: 49)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(selected == option ? Color.green01A274.opacity(0.2) : .gray7C7C7C)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(
                                    selected == option ? Color.green01A274 : .grayBDBDBD,
                                    lineWidth: selected == option ? 2 : 1
                                )
                        )
                    }
                }
            }
        }
    }
}

protocol FilterOption: Hashable, CaseIterable {
    var title: String { get }
}

enum StatusOption: String, FilterOption {
    case all, edited, transcribed, inProgress

    var title: String {
        switch self {
        case .all: return "All"
        case .edited: return "Edited"
        case .transcribed: return "Transcribed"
        case .inProgress: return "In Progress"
        }
    }
}

enum DurationOption: String, FilterOption {
    case all, zeroToFive, fiveToTen, tenToThirty

    var title: String {
        switch self {
        case .all: return "All"
        case .zeroToFive: return "0–5 mins"
        case .fiveToTen: return "5–10 mins"
        case .tenToThirty: return "10–30 mins"
        }
    }
}

enum DateOption: String, FilterOption {
    case newestFirst, oldestFirst

    var title: String {
        switch self {
        case .newestFirst: return "Newest First"
        case .oldestFirst: return "Oldest First"
        }
    }
}
