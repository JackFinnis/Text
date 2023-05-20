//
//  NSTextCheckingResult.swift
//  Text
//
//  Created by Jack Finnis on 20/05/2023.
//

import UIKit

extension NSTextCheckingResult {
    var attributes: [NSAttributedString.Key: Any]? {
        switch resultType {
        case .phoneNumber, .link:
            return [
                .foregroundColor: UIColor.link,
                .underlineStyle: NSUnderlineStyle.single.rawValue
            ]
        case .address, .date:
            return [
                .underlineColor: UIColor.placeholderText,
                .underlineStyle: NSUnderlineStyle.single.rawValue
            ]
        default: return nil
        }
    }
}
