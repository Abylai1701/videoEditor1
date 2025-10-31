//
//  IdentifiableAlert.swift
//  DesaiVideo
//
//  Created by Abylaikhan Abilkayr on 31.10.2025.
//

import SwiftUI

struct IdentifiableAlert: Identifiable {
    var id = UUID()
    var message: String

    var alert: Alert {
        Alert(title: Text("Error"), message: Text(message), dismissButton: .default(Text("OK")))
    }
}
