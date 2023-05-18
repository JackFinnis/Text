//
//  EKEvent.swift
//  Text
//
//  Created by Jack Finnis on 12/02/2023.
//

import Foundation
import EventKit

extension EKEvent: Identifiable {
    public var id: UUID { UUID() }
}

extension EKEventStore {
    static let shared = EKEventStore()
}
