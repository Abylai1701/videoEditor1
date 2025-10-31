//
//  ClearBackground.swift
//  DesaiVideo
//
//  Created by Abylaikhan Abilkayr on 22.10.2025.
//

import SwiftUI

struct ClearBackground: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        DispatchQueue.main.async {
            view.superview?.superview?.backgroundColor = .clear
        }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}
