//
//  BackgroundView.swift
//  DesaiVideo
//
//  Created by Abylaikhan Abilkayr on 22.10.2025.
//

import SwiftUI

struct BackgroundView: View {
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            backgroundColor
            topRightCircle
            bottomLeftCircle
        }
    }
    
    // MARK: - Private Views

    private var backgroundColor: some View {
        Color.black111111
            .ignoresSafeArea()
    }

    private var topRightCircle: some View {
        Circle()
            .fill(circleGradient)
            .frame(width: 230.fitH, height: 230.fitH)
            .blur(radius: 50.fitW)
            .offset(x: 150.fitW, y: -240.fitW)
    }

    private var bottomLeftCircle: some View {
        Circle()
            .fill(circleGradient)
            .frame(width: 250.fitH, height: 250.fitH)
            .blur(radius: 50.fitW)
            .offset(x: -100.fitW, y: 340.fitW)
    }

    private var circleGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                .blue40FFE9.opacity(0.25)]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

struct BackgroundViewForOthers: View {
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            backgroundColor
            topRightCircle
            bottomLeftCircle
        }
    }
    
    // MARK: - Private Views

    private var backgroundColor: some View {
        Color.black111111
            .ignoresSafeArea()
    }

    private var topRightCircle: some View {
        Circle()
            .fill(circleGradient)
            .frame(width: 230.fitH, height: 230.fitH)
            .blur(radius: 50.fitW)
            .offset(x: 150.fitW, y: -380.fitW)
    }

    private var bottomLeftCircle: some View {
        Circle()
            .fill(circleGradient)
            .frame(width: 250.fitH, height: 250.fitH)
            .blur(radius: 50.fitW)
            .offset(x: -100.fitW, y: 340.fitW)
    }

    private var circleGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                .blue40FFE9.opacity(0.25)]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Preview

#Preview {
    BackgroundViewForOthers()
}
