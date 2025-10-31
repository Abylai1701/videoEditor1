//
//  Int+Extensions.swift
//  Scripty
//
//  Created by Abylaikhan Abilkayr on 23.06.2025.
//

import UIKit

extension Int {

    // MARK: - Public Properties
    
    /// Подогнать под ширину базового экрана.
    var fitW: CGFloat {
        let ratio = screenSize.width / baseiPhoneSize.width
        return CGFloat(self) * ratio
    }

    /// Подогнать под высоту базового экрана.
    var fitH: CGFloat {
        let ratio = screenSize.height / baseiPhoneSize.height
        return CGFloat(self) * ratio
    }
    
    /// Сделать пропорционально высоте базового экрана, только если ширина текущего устройства больше высоте iPhone 15 Pro.
    var fitHMore: CGFloat {
        let ratio = screenSize.height / baseiPhoneSize.height
        return ratio > 1 ? CGFloat(self) * ratio : CGFloat(self)
    }
    
    // MARK: - Private Properties
    
    private var baseiPhoneSize: (width: CGFloat, height: CGFloat) { (390, 844) }
    private var screenSize: CGSize { UIScreen.main.bounds.size }
}
