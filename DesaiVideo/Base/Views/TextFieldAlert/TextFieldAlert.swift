//
//  TextFieldAlert.swift
//  DesaiVideo
//
//  Created by Abylaikhan Abilkayr on 30.10.2025.
//

import Foundation
import SwiftUI

struct TextFieldAlert {
    let title: String
    let message: String?
    var placeholder: String = ""
    var initialText: String = ""
    var keyboardType: UIKeyboardType = .default
    var onCancel: (() -> Void)? = nil
    var onSave: (String) -> Void
}

struct TextFieldWrapper: UIViewControllerRepresentable {
    @Binding var alert: TextFieldAlert?

    func makeUIViewController(context: Context) -> UIViewController {
        UIViewController() // пустой хост
    }

    func updateUIViewController(_ vc: UIViewController, context: Context) {
        guard let alert = alert, vc.presentedViewController == nil else { return }

        let alertController = UIAlertController(
            title: alert.title,
            message: alert.message,
            preferredStyle: .alert
        )

        alertController.addTextField { textField in
            textField.placeholder = alert.placeholder
            textField.text = alert.initialText
            textField.keyboardType = alert.keyboardType
            textField.autocapitalizationType = .none
        }

        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
            alert.onCancel?()
            self.alert = nil
        })

        alertController.addAction(UIAlertAction(title: "Save", style: .default) { _ in
            if let text = alertController.textFields?.first?.text {
                alert.onSave(text)
            }
            self.alert = nil
        })

        vc.present(alertController, animated: true)
    }
}
