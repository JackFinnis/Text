//
//  Constants.swift
//  Text
//
//  Created by Jack Finnis on 16/05/2023.
//

import Foundation

struct Constants {
    #if os(iOS)
    static let verticalPadding = 8.0
    static let horizontalPadding = 16.0
    #elseif os(visionOS)
    static let verticalPadding = 0.0
    static let horizontalPadding = 25.0
    #endif
}
