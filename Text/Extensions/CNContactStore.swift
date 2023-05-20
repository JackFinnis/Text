//
//  CNContactStore.swift
//  Text
//
//  Created by Jack Finnis on 20/05/2023.
//

import Foundation
import Contacts

extension CNContactStore {
    static var shared: CNContactStore { .init() }
}
