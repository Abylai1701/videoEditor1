//
//  AppHudUserManager.swift
//  DesaiVideo
//
//  Created by Abylaikhan Abilkayr on 31.10.2025.
//

import Foundation
import ApphudSDK
import Security

final class ApphudUserManager {
    
    static let shared = ApphudUserManager()
    private init() {}
    
    private let keychainKey = "com.cha.5003d4scr1pt.apphud_user_id"
    
    // MARK: - Public
    
    @MainActor
    func configure() {
        if let savedID = getUserID() {
            Apphud.start(apiKey: "app_L2fTgg3NJK6tNFTEuAZF7rr1heXxxZ", userID: savedID)
            print("✅ Apphud started with saved userID: \(savedID)")
        } else {
            Apphud.start(apiKey: "app_L2fTgg3NJK6tNFTEuAZF7rr1heXxxZ")
            print("🕓 Apphud started anonymously")
        }
        Task {
            await PurchaseManager.shared.loadAllProducts()
        }
    }
    
    @MainActor
    func saveCurrentUserIfNeeded() {
        guard getUserID() == nil else { return }
        saveUserID(Apphud.userID())
        print("💾 Saved Apphud userID to Keychain: \(Apphud.userID())")
    }
    
    // MARK: - Keychain
    
    private func saveUserID(_ id: String) {
        guard let data = id.data(using: .utf8) else { return }
        
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: keychainKey,
            kSecValueData: data,
            kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlock
        ] as CFDictionary
        
        SecItemDelete(query)
        SecItemAdd(query, nil)
    }
    
    func getUserID() -> String? {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: keychainKey,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ] as CFDictionary
        
        var result: AnyObject?
        if SecItemCopyMatching(query, &result) == noErr,
           let data = result as? Data,
           let id = String(data: data, encoding: .utf8) {
            return id
        }
        return nil
    }
}
