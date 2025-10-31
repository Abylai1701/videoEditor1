//
//  AppHudExtensions.swift
//  DesaiVideo
//
//  Created by Abylaikhan Abilkayr on 31.10.2025.
//

import Foundation
import ApphudSDK
import StoreKit

extension ApphudProduct {
    private var provider: ProductDataProvider {
        if let skProduct {
            return SKProductDataProvider(skProduct: skProduct)
        }
        if let local = StoreKitContent.defaultContent.products.first(where: { $0.productID == productId }) {
            return LocalStoreKitProductDataProvider(localProduct: local)
        }
        return FallbackProductDataProvider()
    }

    var isTrial: Bool { provider.isTrial }

    var price: Decimal { provider.price == 0 ? (parsedInfo?.price ?? 0) : provider.price }

    var localizedPrice: String {
        if let sk = skProduct {
            let f = NumberFormatter()
            f.numberStyle = .currency
            f.locale = sk.priceLocale
            return f.string(from: sk.price) ?? ""
        }
        return provider.localizedPrice
    }

    var localizedPeriod: String? {
        if let lp = provider.localizedPeriod, !lp.isEmpty {
            return lp
        }
        if let unit = parsedInfo?.subscriptionUnit {
            switch unit {
            case .day:   return NSLocalizedString("Daily", comment: "")
            case .weekOfMonth: return NSLocalizedString("Weekly", comment: "")
            case .month: return NSLocalizedString("Monthly", comment: "")
            case .year:  return NSLocalizedString("Yearly", comment: "")
            default:     return nil
            }
        }
        return nil
    }
    var localizedIntroductory: String? { provider.localizedIntroductory }
    var fullPrice: String { provider.fullPrice }
    var revertedFullPrice: String { provider.revertedFullPrice }
    var firstPaymentPrice: Decimal { provider.firstPaymentPrice }
    var firstPaymentLocalizedPrice: String { provider.firstPaymentLocalizedPrice }
    var formattedSubPeriod: String {
        guard let subscriptionPeriod = provider.subscriptionPeriod else { return "" }
        switch subscriptionPeriod.unit {
            case .day:
                return NSLocalizedString("\(NSLocalizedString("Weekly", comment: ""))", comment: "Daily subscription period")
            case .month:
                return NSLocalizedString("\(NSLocalizedString("Monthly", comment: ""))", comment: "Monthly subscription period")
            case .year:
                return NSLocalizedString("\(NSLocalizedString("Yearly", comment: ""))", comment: "Yearly subscription period")
            default:
                return NSLocalizedString("\(NSLocalizedString("Weekly", comment: ""))", comment: "Weekly subscription period")
        }
    }
    func firstPaymentLocalizedPriceDivided(by divider: Decimal, minimumFractionDigits: Int = 0, maximumFractionDigits: Int = 2) -> String {
        provider.firstPaymentLocalizedPriceDivided(by: divider, minimumFractionDigits: minimumFractionDigits, maximumFractionDigits: maximumFractionDigits)
    }
    func localizedPriceDivided(by divider: Decimal, minimumFractionDigits: Int = 0, maximumFractionDigits: Int = 2) -> String {
        provider.localizedPriceDivided(by: divider, minimumFractionDigits: minimumFractionDigits, maximumFractionDigits: maximumFractionDigits)
    }
    
    var isLifetime: Bool { provider.subscriptionPeriod == nil && parsedInfo?.subscriptionUnit == nil }

    var tokensQuantity: Int? { parsedInfo?.tokens }

    var avatarsQuantity: Int? { parsedInfo?.avatars }
}

struct ProductDataPeriod {
    let unit: NSCalendar.Unit
    let numberOfUnits: Int

    private static var calendar: Calendar {
        var calendar = Calendar.current
        calendar.locale = Locale(identifier: "en_US")
        return calendar
    }

    func format(omitOneUnit: Bool) -> String {
        var unit = unit
        var numberOfUnits = numberOfUnits
        if unit == .day, numberOfUnits == 7 {
            unit = .weekOfMonth
            numberOfUnits = 1
        }
        let componentFormatter: DateComponentsFormatter = {
            let formatter = DateComponentsFormatter()
            formatter.maximumUnitCount = 1
            formatter.unitsStyle = .full
            formatter.zeroFormattingBehavior = .dropAll
            formatter.calendar = Self.calendar
            formatter.allowedUnits = [unit]
            return formatter
        }()
        var dateComponents = DateComponents()
        dateComponents.calendar = Self.calendar
        switch unit {
        case .day:
            if omitOneUnit, numberOfUnits == 1 { return "day" }
            dateComponents.setValue(numberOfUnits, for: .day)
        case .weekOfMonth:
            if omitOneUnit, numberOfUnits == 1 { return "week" }
            dateComponents.setValue(numberOfUnits, for: .weekOfMonth)
        case .month:
            if omitOneUnit, numberOfUnits == 1 { return "month" }
            dateComponents.setValue(numberOfUnits, for: .month)
        case .year:
            if omitOneUnit, numberOfUnits == 1 { return "year" }
            dateComponents.setValue(numberOfUnits, for: .year)
        default:
            assertionFailure("invalid storekit")
        }

        return componentFormatter.string(from: dateComponents) ?? ""
    }
}

enum ProductDataIntroductory {
    case freeTrial(ProductDataPeriod)
    case payUpFront(Decimal, ProductDataPeriod)
    case payAsYouGo(Decimal, ProductDataPeriod, Int)
}

protocol ProductDataProvider {
    var price: Decimal { get }
    var priceLocale: Locale { get }
    var subscriptionPeriod: ProductDataPeriod? { get }
    var introductory: ProductDataIntroductory? { get }
}

private struct FallbackProductDataProvider: ProductDataProvider {
    var price: Decimal { 0 }
    var priceLocale: Locale { Locale.current }
    var subscriptionPeriod: ProductDataPeriod? { nil }
    var introductory: ProductDataIntroductory? { nil }
}

extension ProductDataProvider {
    var isTrial: Bool {
        if case .freeTrial = introductory {
            return true
        } else {
            return false
        }
    }

    var localizedPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = priceLocale
        return formatter.string(from: price as NSNumber) ?? ""
    }

    var localizedPeriod: String? {
        subscriptionPeriod?.format(omitOneUnit: true)
    }

    var localizedIntroductory: String? {
        introductory.map { introductory in
            switch introductory {
            case .freeTrial(let period):
                return "\(period.format(omitOneUnit: false)) free trial"
            case .payUpFront(let price, let period):
                let formatter = NumberFormatter()
                formatter.numberStyle = .currency
                formatter.locale = priceLocale
                return "first \(period.format(omitOneUnit: false)) for \(formatter.string(from: price as NSNumber) ?? "")"
            case .payAsYouGo(let price, let period, let numberOfPeriods):
                let formatter = NumberFormatter()
                formatter.numberStyle = .currency
                formatter.locale = priceLocale
                return "first \(ProductDataPeriod(unit: period.unit, numberOfUnits: period.numberOfUnits * numberOfPeriods).format(omitOneUnit: false)) for \(formatter.string(from: price as NSNumber) ?? "")/\(period.format(omitOneUnit: true))"
            }
        }
    }

    var fullPrice: String {
        var price = localizedPrice
        if let localizedPeriod {
            price += "/\(localizedPeriod)"
        } else {
            price += " at once"
        }
        if let discount = localizedIntroductory {
            price += " + \(discount)"
        }
        return price
    }

    var revertedFullPrice: String {
        var price = ""
        if let discount = localizedIntroductory {
            price += "\(discount), then "
        }
        price += "\(localizedPrice)"
        if let localizedPeriod {
            price += "/\(localizedPeriod)"
        } else {
            price += " at once"
        }
        return price
    }

    var firstPaymentPrice: Decimal {
        if let introductory = introductory {
            switch introductory {
            case .freeTrial(_): return price
            case .payUpFront(let price, _): return price
            case .payAsYouGo(let price, _, _): return price
            }
        } else {
            return price
        }
    }

    var firstPaymentLocalizedPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = priceLocale
        return formatter.string(from: firstPaymentPrice as NSNumber) ?? ""
    }

    func firstPaymentLocalizedPriceDivided(by divider: Decimal, minimumFractionDigits: Int, maximumFractionDigits: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = priceLocale
        formatter.minimumFractionDigits = minimumFractionDigits
        formatter.maximumFractionDigits = maximumFractionDigits
        return formatter.string(from: (firstPaymentPrice / divider) as NSNumber) ?? ""
    }


    func localizedPriceDivided(by amount: Decimal, minimumFractionDigits: Int, maximumFractionDigits: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = priceLocale
        formatter.minimumFractionDigits = 0
        formatter.minimumFractionDigits = minimumFractionDigits
        formatter.maximumFractionDigits = maximumFractionDigits
        return formatter.string(from: (price / amount) as NSNumber) ?? ""
    }
}

private struct SKProductDataProvider: ProductDataProvider {
    private let skProduct: SKProduct
    init(skProduct: SKProduct) {
        self.skProduct = skProduct
    }

    var price: Decimal {
        skProduct.price.decimalValue
    }

    var priceLocale: Locale {
        skProduct.priceLocale
    }

    var subscriptionPeriod: ProductDataPeriod? {
        skProduct.subscriptionPeriod.map { period in
            ProductDataPeriod(unit: period.unit.toCalendarUnit(), numberOfUnits: period.numberOfUnits)
        }
    }

    var introductory: ProductDataIntroductory? {
        skProduct.introductoryPrice.map { introductory in
            let period = ProductDataPeriod(unit: introductory.subscriptionPeriod.unit.toCalendarUnit(), numberOfUnits: introductory.subscriptionPeriod.numberOfUnits)
            switch introductory.paymentMode {
            case .freeTrial: return .freeTrial(period)
            case .payUpFront: return .payUpFront(introductory.price.decimalValue, period)
            case .payAsYouGo: return .payAsYouGo(introductory.price.decimalValue, period, introductory.numberOfPeriods)
            }
        }
    }
}

private extension SKProduct.PeriodUnit {
    func toCalendarUnit() -> NSCalendar.Unit {
        switch self {
        case .day:
            return .day
        case .month:
            return .month
        case .week:
            return .weekOfMonth
        case .year:
            return .year
        @unknown default:
            assertionFailure("Unknown period unit")
        }
        return .day
    }
}

private struct LocalStoreKitProductDataProvider: ProductDataProvider {
    private let localProduct: StoreKitContent.Product
    init(localProduct: StoreKitContent.Product) {
        self.localProduct = localProduct
    }

    var price: Decimal {
        Decimal(string: localProduct.displayPrice, locale: priceLocale) ?? 0
    }

    var priceLocale: Locale {
        Locale(identifier: "en_US")
    }

    var subscriptionPeriod: ProductDataPeriod? {
        localProduct.recurringSubscriptionPeriod.map { period in
            ProductDataPeriod(unit: period.unit, numberOfUnits: period.numberOfUnits)
        }
    }

    var introductory: ProductDataIntroductory? {
        localProduct.introductoryOffer.map { introductory in
            let period = ProductDataPeriod(unit: introductory.subscriptionPeriod.unit, numberOfUnits: introductory.subscriptionPeriod.numberOfUnits)
            switch introductory.paymentMode {
            case .free: return .freeTrial(period)
            case .payUpFront: return .payUpFront(Decimal(string: introductory.displayPrice ?? "0", locale: priceLocale) ?? 0, period)
            case .payAsYouGo: return .payAsYouGo(Decimal(string: introductory.displayPrice ?? "0", locale: priceLocale) ?? 0, period, introductory.numberOfPeriods ?? 0)
            }
        }
    }
}

fileprivate struct StoreKitContent: Decodable {
    let settings: Settings
    let nonRenewingSubscriptions: [Product]?
    let nonConsumableProducts: [Product]?
    let subscriptionGroups: [SubscriptionGroup]?
    fileprivate static let defaultContent: StoreKitContent = {
        if let url = Bundle.main.url(forResource: nil, withExtension: "storekit"),
           let data = try? Data(contentsOf: url),
           let content = try? JSONDecoder().decode(StoreKitContent.self, from: data) {
            return content
        }
        return .init(settings: .init(storefront: nil), nonRenewingSubscriptions: nil, nonConsumableProducts: nil, subscriptionGroups: nil)
    }()

    var products: [Product] {
        (nonRenewingSubscriptions ?? []) +
        (nonConsumableProducts ?? []) +
        (subscriptionGroups ?? []).flatMap(\.subscriptions)
    }

    enum CodingKeys: String, CodingKey {
        case settings = "settings"
        case nonRenewingSubscriptions = "nonRenewingSubscriptions"
        case nonConsumableProducts = "products"
        case subscriptionGroups = "subscriptionGroups"
    }

    struct Settings: Decodable {
        let storefront: String?

        enum CodingKeys: String, CodingKey {
            case storefront = "_storefront"
        }
    }

    struct SubscriptionGroup: Decodable {
        let subscriptions: [Product]

        enum CodingKeys: String, CodingKey {
            case subscriptions = "subscriptions"
        }
    }

    struct Product: Decodable {
        let productID: String
        let displayPrice: String
        let recurringSubscriptionPeriod: Period?
        let introductoryOffer: IntroductoryOffer?

        enum CodingKeys: String, CodingKey {
            case productID = "productID"
            case displayPrice = "displayPrice"
            case recurringSubscriptionPeriod = "recurringSubscriptionPeriod"
            case introductoryOffer = "introductoryOffer"
        }
    }

    struct IntroductoryOffer: Decodable {
        enum PaymentMode: String, Decodable {
            case free
            case payAsYouGo
            case payUpFront
        }
        let paymentMode: PaymentMode
        let subscriptionPeriod: Period
        let numberOfPeriods: Int?
        let displayPrice: String?

        enum CodingKeys: String, CodingKey {
            case paymentMode = "paymentMode"
            case subscriptionPeriod = "subscriptionPeriod"
            case numberOfPeriods = "numberOfPeriods"
            case displayPrice = "displayPrice"
        }
    }

    struct Period: Decodable {
        let unit: NSCalendar.Unit
        let numberOfUnits: Int

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let periodString = try container.decode(String.self)

            guard periodString.first == "P" else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid period format. Must start with 'P'.")
            }

            let duration = periodString.dropFirst()

            let pattern = #"^(\d+)([YMWD])$"#
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let durationString = String(duration)

            guard
                let match = regex.firstMatch(in: durationString, options: [], range: NSRange(location: 0, length: durationString.utf16.count)),
                let numberRange = Range(match.range(at: 1), in: durationString),
                let unitRange = Range(match.range(at: 2), in: durationString),
                let number = Int(durationString[numberRange])
            else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid period format.")
            }

            let unitChar = durationString[unitRange]
            let calendarUnit: NSCalendar.Unit

            switch unitChar {
            case "Y": calendarUnit = .year
            case "M": calendarUnit = .month
            case "W": calendarUnit = .weekOfMonth
            case "D": calendarUnit = .day
            default:
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported time unit: \(unitChar)")
            }

            self.unit = calendarUnit
            self.numberOfUnits = number
        }
    }
}

private extension ApphudProduct {
    struct ParsedInfo {
        enum Kind { case tokens, avatars, subscription }
        let kind: Kind
        let price: Decimal?
        let tokens: Int?
        let avatars: Int?
        let subscriptionUnit: NSCalendar.Unit?
    }

    var parsedInfo: ParsedInfo? {
        let id = productId.lowercased()

        if let m = id.firstMatch(regex: "^(\\d+)_tokens_([0-9]+(?:\\.[0-9]+)?)$") {
            let qty = Int(m[1])
            let pr  = Decimal(string: m[2])
            return .init(kind: .tokens, price: pr, tokens: qty, avatars: nil, subscriptionUnit: nil)
        }

        if let m = id.firstMatch(regex: "^(\\d+)_avatar_([0-9]+(?:\\.[0-9]+)?)$") {
            let qty = Int(m[1])
            let pr  = Decimal(string: m[2])
            return .init(kind: .avatars, price: pr, tokens: nil, avatars: qty, subscriptionUnit: nil)
        }

        if let m = id.firstMatch(regex: "^(week|month|monthly|year|yearly)_([0-9]+(?:\\.[0-9]+)?)(?:_nottrial|_not_trial)?$") {
            let unitStr = m[1]
            let pr = Decimal(string: m[2])
            let unit: NSCalendar.Unit
            switch unitStr {
            case "week": unit = .weekOfMonth
            case "month", "monthly": unit = .month
            case "year", "yearly": unit = .year
            default: unit = .month
            }
            return .init(kind: .subscription, price: pr, tokens: nil, avatars: nil, subscriptionUnit: unit)
        }

        return nil
    }
}

private extension String {
    func firstMatch(regex pattern: String) -> [String]? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return nil }
        let range = NSRange(startIndex..<endIndex, in: self)
        guard let match = regex.firstMatch(in: self, options: [], range: range) else { return nil }
        var results: [String] = []
        for i in 0..<match.numberOfRanges {
            let r = match.range(at: i)
            if let rr = Range(r, in: self) {
                results.append(String(self[rr]))
            }
        }
        return results
    }
}


