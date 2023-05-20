//
//  String.swift
//  Text
//
//  Created by Jack Finnis on 20/05/2023.
//

import Foundation

extension String {
    var urlEncoding: String? {
        addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
    }
}
