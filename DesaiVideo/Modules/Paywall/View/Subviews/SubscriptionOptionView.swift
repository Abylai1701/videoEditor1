//
//  SubscriptionOptionView.swift
//  DesaiVideo
//
//  Created by Abylaikhan Abilkayr on 24.10.2025.
//

import SwiftUI

struct SubscriptionOptionView: View {
    var title: String
    var subtitle: String
    var price: String
    var isSelected: Bool = false

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15.fitH, weight: .bold))
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.system(size: 13.fitH, weight: .regular))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            Spacer()
            
            Text(price)
                .font(.system(size: 15.fitH, weight: .bold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12.fitH)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.gray545454)
        )
        .overlay {
            Rectangle()
                .fill(.gray7C7C7C)
                .frame(width: 1, height: 41.fitH)
                .offset(x: 35.fitW)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(isSelected ? Color.grayEBECF5 : Color.gray414141,
                        lineWidth: isSelected ? 2 : 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
