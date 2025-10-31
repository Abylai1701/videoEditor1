//
//  OnbModel.swift
//  DesaiVideo
//
//  Created by Abylaikhan Abilkayr on 24.10.2025.
//

import SwiftUI

enum OnbEnum {
    case onb1, onb2, onb3, onb4
    
    var title1: String {
        switch self {
        case .onb1:
            "AI-Powered"
        case .onb2:
            "Smart Audio"
        case .onb3:
            "We value"
        case .onb4:
            "Unlimited"
        }
    }
    
    var title2: String {
        switch self {
        case .onb1:
            "Cleanup"
        case .onb2:
            "& Video Editing"
        case .onb3:
            "your feedback"
        case .onb4:
            "Access"
        }
    }
    
    var description: String {
        switch self {
        case .onb1:
            "Remove filler words, cut pauses, and boost clarity with just one tap"
        case .onb2:
            "Manage your recordings, enhance sound, and get instant transcripts — all in one place"
        case .onb3:
            "Share your opinion about our app Transcript"
        case .onb4:
            "Try 3 days free then $4,99 / week or proceed with limited version"
        }
    }
    
    var continueTitle: String {
        switch self {
        case .onb1:
            "Continue"
        case .onb2:
            "Continue"
        case .onb3:
            "Continue"
        case .onb4:
            "Try free & subscribe"
        }
    }
    
    var image: ImageResource {
        switch self {
        case .onb1:
                .onb1
        case .onb2:
                .onb2
        case .onb3:
                .onb3
        case .onb4:
                .onb4
        }
    }
}
