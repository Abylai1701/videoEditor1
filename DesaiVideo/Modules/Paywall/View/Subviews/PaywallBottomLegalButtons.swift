//
//  PaywallBottomLegalButtons.swift
//  DesaiVideo
//
//  Created by Abylaikhan Abilkayr on 24.10.2025.
//

import SwiftUI

enum PaywallLegalButtonType: Hashable, CaseIterable {
    case terms
    case restore
    case privacy
}

struct PaywallBottomLegalButtons: View {
    
    // MARK: - Public Properties
    
    let action: (PaywallLegalButtonType) -> Void
    
    // MARK: - Body
    
    var body: some View {
        HStack {
            
            Button {
                action(.terms)
            } label: {
                Text("Terms of Use")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(.white.opacity(0.5))
            }
            .buttonStyle(.plain)
            
            Spacer()

            Button {
                action(.privacy)
            } label: {
                Text("Privacy Policy")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(.white.opacity(0.5))
            }
            .buttonStyle(.plain)
            
            Spacer()

            
            Button {
                action(.restore)
            } label: {
                Text("Restore")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(.white.opacity(0.5))
            }
            .buttonStyle(.plain)
                        
        }
    }
}
