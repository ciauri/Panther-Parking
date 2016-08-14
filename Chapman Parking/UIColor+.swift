//
//  UIColor+.swift
//  Chapman Parking
//
//  Created by Stephen Ciauri on 8/14/16.
//  Copyright © 2016 Stephen Ciauri. All rights reserved.
//

import Foundation
import UIKit

extension UIColor{
    /// Must be a value between 0 and 1
    class func temperatureColor(fromPercentCompletion percent: Float) -> UIColor {
        return UIColor(hue: 0.3 - CGFloat(percent/3), saturation: 1, brightness: 1, alpha: 1)

    }
}
