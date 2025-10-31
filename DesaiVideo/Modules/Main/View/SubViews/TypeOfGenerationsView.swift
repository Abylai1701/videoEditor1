//
//  TypeOfGenerationsView.swift
//  DesaiVideo
//
//  Created by Abylaikhan Abilkayr on 22.10.2025.
//

import SwiftUI

struct TypeOfGenerationsView: View {
    
    var tapEdit: () -> Void
    var tapTranscribe: () -> Void
    
    var body: some View {
        HStack {
            Button {
                tapEdit()
            } label: {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    .fill(.white.opacity(0.20))
                    .frame(width: 173.fitW, height: 78.fitH)
                    .overlay {
                        VStack(spacing: 6) {
                            Text("Edit")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(.white.opacity(0.5))
                            Image(.penIcon)
                                .resizable()
                                .frame(width: 28, height: 28)
                        }
                    }
            }
            .buttonStyle(.plain)

//            Spacer(minLength: 0)
            
            Button {
                tapTranscribe()
            } label: {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    .fill(.white.opacity(0.20))
                    .frame(width: 173, height: 78.fitH)
                    .overlay {
                        VStack(spacing: 6) {
                            Text("Transcribe")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(.white.opacity(0.5))
                            Image(.documentIcon)
                                .resizable()
                                .frame(width: 28, height: 28)
                        }
                    }
            }
            .buttonStyle(.plain)
        }
    }
}
