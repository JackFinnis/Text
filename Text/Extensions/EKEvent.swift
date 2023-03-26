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
    
    convenience init(date: Date, duration: Double, timeZone: TimeZone) {
        self.init(eventStore: .shared)
        self.timeZone = timeZone
        self.startDate = date
        self.endDate = date.addingTimeInterval(duration)
    }
}
