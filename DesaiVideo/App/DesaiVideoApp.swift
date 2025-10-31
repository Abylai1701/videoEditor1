//
//  DesaiVideoApp.swift
//  DesaiVideo
//
//  Created by Abylaikhan Abilkayr on 22.10.2025.
//

import SwiftUI
import AdSupport
import ApphudSDK
import AppTrackingTransparency

@main
struct DesaiVideoApp: App {
    
    @Environment(\.scenePhase) var scenePhase

    init() {
        ApphudUserManager.shared.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.light)
                .onChange(of: scenePhase) {
                    if scenePhase == .active {
                        ATTrackingManager.requestTrackingAuthorization { status in
                            switch status {
                            case .authorized:
                                let idfa = ASIdentifierManager.shared().advertisingIdentifier
                                Apphud.setDeviceIdentifiers(idfa: idfa.uuidString, idfv: UIDevice.current.identifierForVendor?.uuidString)
                            case .denied, .restricted, .notDetermined:
                                print("IDFA authorization not granted")
                            @unknown default:
                                break
                            }
                        }
                    }
                }
        }
    }
}
