//
//  String.swift
//  Text
//
//  Created by Jack Finnis on 15/08/2023.
//

import Foundation

extension String {
    var words: Int {
        split(whereSeparator: \.isLetter).filter(\.isNotEmpty).count
    }
}
