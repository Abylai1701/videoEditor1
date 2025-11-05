//
//  PurchaseManager.swift
//  DesaiVideo
//
//  Created by Abylaikhan Abilkayr on 31.10.2025.
//

import Foundation
import ApphudSDK
import StoreKit
import SwiftUI

@MainActor
final class PurchaseManager: ObservableObject {
    static let shared = PurchaseManager()
    
    // MARK: - Published
    @Published var subscriptions: [ApphudProduct] = []
    @Published var isSubscribed: Bool = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var alert: IdentifiableAlert?

    // MARK: - IDs
    private let subscriptionIDs = [
        "week_4.99_nottrial",
        "yearly_39.99_nottrial"
    ]

    private init() {}
    
    // MARK: - LOAD
    func loadAllProducts() async {
        isLoading = true
        defer { isLoading = false }
        
        await loadApphudSubscriptions()
    }
    
    private func loadApphudSubscriptions() async {
        _ = await Apphud.fetchSKProducts()
        let paywalls = await Apphud.fetchPaywallsWithFallback()
        
        guard !paywalls.isEmpty else {
            print("❌ Нет Apphud paywalls")
            return
        }

        // Собираем продукты из всех paywalls
        let allProducts = paywalls.flatMap { $0.products }

        // Фильтруем по категориям
        let subs = allProducts.filter { subscriptionIDs.contains($0.productId) }

        // Если тебе нужно всё в одном массиве
        subscriptions = subs

        print("✅ Apphud Subscriptions:")
        for s in subscriptions {
            print("• \(s.productId) \(s.localizedPrice)")
        }
        
        isSubscribed = Apphud.hasPremiumAccess()
    }
        
    // MARK: - PURCHASE
    func purchaseSubscription(_ product: ApphudProduct) async {
        Apphud.purchase(product) { result in
            if let error = result.error {
                self.alert = IdentifiableAlert(message: "Purchase failed")
                return
            }
            if result.subscription?.isActive() == true {
                print("✅ Подписка активна: \(product.productId)")
                self.isSubscribed = true
                ApphudUserManager.shared.saveCurrentUserIfNeeded()
                self.alert = IdentifiableAlert(message: "Purchase success")
            } else {
                print("⚠️ Подписка не активна")
            }
        }
    }
    
    func purchaseLocal(_ product: Product) async {
        do {
            let result = try await product.purchase()
            if case .success(let verification) = result,
               case .verified(let transaction) = verification {
                await transaction.finish()
                print("✅ Куплен инап: \(transaction.productID)")
            }
        } catch {
            self.alert = IdentifiableAlert(message: "Purchase failed")
        }
    }
    
    // MARK: - RESTORE
    func restore() async {
        // Apphud restore
        Apphud.restorePurchases { subs, purchases, error in
            if let error = error {
                self.alert = IdentifiableAlert(message: "Restore failed")
                return
            }
            let active = subs?.contains(where: { $0.isActive() }) ?? false
            self.isSubscribed = active
            ApphudUserManager.shared.saveCurrentUserIfNeeded()
            print("🔄 Apphud restore complete — active: \(active)")
        }
        
        // StoreKit restore
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                print("🔄 Восстановлено: \(transaction.productID)")
            }
        }
    }
}

extension Apphud {
    @MainActor
    static func fetchPaywallsWithFallback() async -> [ApphudPaywall] {
        // 1️⃣ Попробуем получить продукты с App Store
        _ = await Apphud.fetchSKProducts()

        // 2️⃣ Слушаем, когда Apphud загрузит paywalls
        let remote: [ApphudPaywall] = await withCheckedContinuation { continuation in
            Apphud.paywallsDidLoadCallback { paywalls, _ in
                print("Вот мои paywalls: \(paywalls)")
                continuation.resume(returning: paywalls)
            }
        }

        // 3️⃣ Если paywalls пришли — возвращаем
        if !remote.isEmpty {
            return remote
        }

        // 4️⃣ Иначе пробуем fallback (локальный кэш или встроенные)
        let fallback: [ApphudPaywall] = await withCheckedContinuation { continuation in
            Apphud.loadFallbackPaywalls { paywalls, _ in
                print("Вот мои local paywalls: \(paywalls)")
                continuation.resume(returning: paywalls ?? [])
            }
        }
        return fallback
    }
}
