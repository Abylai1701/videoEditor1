//
//  URL+Extensions.swift
//  DesaiVideo
//
//  Created by Abylaikhan Abilkayr on 30.10.2025.
//

import Foundation

extension URL: Identifiable {
    public var id: String { path }
}
