//
//  UIFont.swift
//  Text
//
//  Created by Jack Finnis on 17/02/2024.
//

import UIKit

extension UIFont {
    class func roundedSystemFont(style: TextStyle) -> UIFont {
        let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: style).withDesign(.rounded)!
        return UIFont(descriptor: descriptor, size: descriptor.pointSize)
    }
}
