//
//  AlertButton.swift
//  Scripty
//
//  Created by Иван Незговоров on 24.06.2025.
//

import SwiftUI

enum AlertItemButtonStyle {
    case destructive, `default`, cancel
}

struct AlertItemButton {
    
    // MARK: - Public Properties
    
    let titleText: String
    
    let style: AlertItemButtonStyle

    var action: () -> Void = {}

    // MARK: - Public Methods
    
    func toAlertButton() -> Alert.Button {
        switch style {
        case .default:
            .default(Text(titleText), action: action)
        case .cancel:
            .cancel(Text(titleText), action: action)
        case .destructive:
            .destructive(Text(titleText), action: action)
        }
    }
}
