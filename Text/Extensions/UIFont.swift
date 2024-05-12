//
//  UIFont.swift
//  Text
//
//  Created by Jack Finnis on 17/02/2024.
//

import UIKit

extension UIFont {
    class func systemFont(_ style: TextStyle = .body, weight: UIFont.Weight = .regular, design: UIFontDescriptor.SystemDesign = .default) -> UIFont {
        let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: style).withDesign(design)!.addingAttributes([.traits : [UIFontDescriptor.TraitKey.weight : weight]])
        return UIFont(descriptor: descriptor, size: descriptor.pointSize)
    }
}
