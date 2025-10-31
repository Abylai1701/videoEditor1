//
//  Double+Extensions.swift
//  Scripty
//
//  Created by Илья Тимченко on 6/24/25.
//

import Foundation

extension Double {
    /// Преобразует значение в секундах (self) в строку формата времени.
    ///
    /// - Если значение меньше 1 часа — возвращается строка в формате `mm:ss`.
    /// - Если значение 1 час и больше — формат `h:mm:ss`.
    /// - Returns: Строка, представляющая форматированное время.
    func timeString() -> String {
        let totalSeconds = Int(self)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        if hours > 0 {
            return String(format: "%01d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}
