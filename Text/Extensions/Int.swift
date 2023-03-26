//
//  Int.swift
//  Text
//
//  Created by Jack Finnis on 12/02/2023.
//

import Foundation

extension Int {
    func formatted(singular word: String) -> String {
        "\(self) " + word + (self == 1 ? "" : "s")
    }
}
