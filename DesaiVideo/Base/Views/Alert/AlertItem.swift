//
//  AlertItem.swift
//  Scripty
//
//  Created by Иван Незговоров on 24.06.2025.
//

import SwiftUI

struct AlertItem: Identifiable {
    
    // MARK: - Public Properties
    
    let id = UUID()
    
    let titleText: String
    
    let descriptionText: String
    
    let firstButton: AlertItemButton
    
    var secondButton: AlertItemButton?

    var alert: Alert {
        let titleText = Text(titleText)
        let messageText = Text(descriptionText)
        return if let secondButton {
            Alert(
                title: titleText,
                message: messageText,
                primaryButton: firstButton.toAlertButton(),
                secondaryButton: secondButton.toAlertButton()
            )
        } else {
            Alert(
                title: titleText,
                message: messageText,
                dismissButton: firstButton.toAlertButton()
            )
        }
    }
}
