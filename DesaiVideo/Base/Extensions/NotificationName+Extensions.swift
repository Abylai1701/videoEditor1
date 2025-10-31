//
//  NotificationName+Extensions.swift
//  Scripty
//
//  Created by duke on 6/30/25.
//

import Foundation

extension Notification.Name {
    static let didFinishOnboarding = Notification.Name("didFinishOnboarding")
    static let didFinishTask = Notification.Name("didFinishTask")
    static let taskDidFinish = Notification.Name("taskDidFinish")

    
    static let seekForward10 = Notification.Name("seekForward10")
    static let seekBackward10 = Notification.Name("seekBackward10")
    static let projectsDidUpdate = Notification.Name("projectsDidUpdate")
    static let cancelTask = Notification.Name("cancelTask")
}
