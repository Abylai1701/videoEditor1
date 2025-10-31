//
//  Publishers+Extensions.swift
//  Scripty
//
//  Created by Иван Незговоров on 30.06.2025.
//

import Combine
import SwiftUI

extension Publishers {
    static var keyboardHeight: AnyPublisher<CGFloat, Never> {
        let willShow = NotificationCenter.default
            .publisher(for: UIResponder.keyboardWillShowNotification)
            .compactMap { notification -> CGFloat? in
                (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect)?.height
            }
            .eraseToAnyPublisher()

        let willHide = NotificationCenter.default
            .publisher(for: UIResponder.keyboardWillHideNotification)
            .map { _ in CGFloat(0) }
            .eraseToAnyPublisher()

        return Publishers.Merge(willShow, willHide)
            .eraseToAnyPublisher()
    }
}
