//
//  TextError.swift
//  Text
//
//  Created by Jack Finnis on 18/05/2023.
//

import Foundation

enum TextError {
    case geocodeAddress
    case eventAuth
    case addEvent
    case contactsAuth
    
    var title: String {
        switch self {
        case .geocodeAddress:
            return "Invalid Address"
        case .eventAuth:
            return "Access Denied"
        case .addEvent:
            return "Event Not Added"
        case .contactsAuth:
            return "Access Denied"
        }
    }
    
    var description: String {
        switch self {
        case .geocodeAddress:
            return "Please try finding the address in Apple Maps."
        case .eventAuth:
            return "\(Constants.name) needs access to your calendar to add new events. Please go to Settings > \(Constants.name) and allow access."
        case .addEvent:
            return "Please try adding the event in Calendar."
        case .contactsAuth:
            return "\(Constants.name) needs access to your contacts to add contact details. Please go to Settings > \(Constants.name) and allow access."
        }
    }
    
    var showsOpenSettingsButton: Bool {
        [TextError.contactsAuth, .eventAuth].contains(self)
    }
}
