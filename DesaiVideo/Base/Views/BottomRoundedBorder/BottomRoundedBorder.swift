//
//  BottomRoundedBorder.swift
//  DesaiVideo
//
//  Created by Abylaikhan Abilkayr on 22.10.2025.
//

import SwiftUI

struct BottomRoundedBorder: InsettableShape {
    var radius: CGFloat
    var insetAmount: CGFloat = 0
    
    func inset(by amount: CGFloat) -> some InsettableShape {
        var copy = self
        copy.insetAmount += amount
        return copy
    }
    
    func path(in rect: CGRect) -> Path {
        let minX = rect.minX + insetAmount
        let maxX = rect.maxX - insetAmount
        let maxY = rect.maxY - insetAmount
        let r = max(0, min(radius, min(rect.width, rect.height) / 2) - insetAmount)
        
        var p = Path()
        // старт у левого борта на высоте радиуса
        p.move(to: CGPoint(x: minX, y: maxY - r))
        // дуга нижнего левого угла (слева → вниз)
        p.addArc(center: CGPoint(x: minX + r, y: maxY - r),
                 radius: r,
                 startAngle: .degrees(180),
                 endAngle: .degrees(90),
                 clockwise: true)
        // нижняя прямая
        p.addLine(to: CGPoint(x: maxX - r, y: maxY))
        // дуга нижнего правого угла (вниз → вправо)
        p.addArc(center: CGPoint(x: maxX - r, y: maxY - r),
                 radius: r,
                 startAngle: .degrees(90),
                 endAngle: .degrees(0),
                 clockwise: true)
        return p
    }
}

struct TopRoundedBorder: InsettableShape {
    var radius: CGFloat
    var insetAmount: CGFloat = 0

    func inset(by amount: CGFloat) -> some InsettableShape {
        var copy = self
        copy.insetAmount += amount
        return copy
    }

    func path(in rect: CGRect) -> Path {
        let minX = rect.minX + insetAmount
        let maxX = rect.maxX - insetAmount
        let minY = rect.minY + insetAmount
        let r = max(0, min(radius, min(rect.width, rect.height) / 2) - insetAmount)

        var p = Path()
        // старт на левом борту, на расстоянии r от верха
        p.move(to: CGPoint(x: minX, y: minY + r))
        // дуга верхнего левого угла (слева → вверх)
        p.addArc(center: CGPoint(x: minX + r, y: minY + r),
                 radius: r,
                 startAngle: .degrees(180),
                 endAngle: .degrees(270),
                 clockwise: false)
        // верхняя прямая
        p.addLine(to: CGPoint(x: maxX - r, y: minY))
        // дуга верхнего правого угла (вверх → вправо)
        p.addArc(center: CGPoint(x: maxX - r, y: minY + r),
                 radius: r,
                 startAngle: .degrees(270),
                 endAngle: .degrees(360),
                 clockwise: false)
        return p
    }
}
