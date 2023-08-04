//
//  TextError.swift
//  Text
//
//  Created by Jack Finnis on 18/05/2023.
//

import Foundation

enum TextAlert {
    case geocodeAddressError
    case eventAuthError
    case addEventError
    case addEventSuccess
    case contactsAuthError
    case addContactSuccess
    
    var title: String {
        switch self {
        case .geocodeAddressError:
            return "Address Not Found"
        case .eventAuthError:
            return "Access Denied"
        case .addEventError:
            return "Event Not Added"
        case .contactsAuthError:
            return "Access Denied"
        case .addEventSuccess:
            return "Event Added"
        case .addContactSuccess:
            return "Contact Saved"
        }
    }
    
    var description: String {
        switch self {
        case .geocodeAddressError:
            return "Please check your internet connection and try again."
        case .eventAuthError:
            return "\(Constants.name) needs access to your calendar to add new events. Please go to Settings > \(Constants.name) and allow access."
        case .addEventError:
            return "Please try adding the event from your calendar app."
        case .contactsAuthError:
            return "\(Constants.name) needs access to your contacts to add contact details. Please go to Settings > \(Constants.name) and allow access."
        case .addEventSuccess, .addContactSuccess:
            return ""
        }
    }
    
    var showsOpenSettingsButton: Bool {
        [Self.contactsAuthError, .eventAuthError].contains(self)
    }
}
