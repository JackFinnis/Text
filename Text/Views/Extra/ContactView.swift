//
//  ContactView.swift
//  Text
//
//  Created by Jack Finnis on 18/05/2023.
//

import SwiftUI
import ContactsUI
import MapKit

struct ContactView: UIViewControllerRepresentable {
    @EnvironmentObject var vm: ViewModel
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    func makeUIViewController(context: Context) -> CNContactViewController {
        let contact = CNMutableContact()
        if let address = vm.mapItem?.placemark.postalAddress {
            contact.postalAddresses = [CNLabeledValue(label: CNLabelHome, value: address)]
        }
        if let phoneNumber = vm.phoneNumber {
            contact.phoneNumbers = [CNLabeledValue(label: CNLabelPhoneNumberMain, value: CNPhoneNumber(stringValue: phoneNumber))]
        }
        
        let vc = CNContactViewController(forNewContact: contact)
        vc.delegate = context.coordinator
        
        return vc
    }
    
    func updateUIViewController(_ vc: CNContactViewController, context: Context) {}
    
    class Coordinator: NSObject, CNContactViewControllerDelegate {
        var parent: ContactView

        init(parent: ContactView) {
            self.parent = parent
        }
        
        @MainActor
        func contactViewController(_ viewController: CNContactViewController, didCompleteWith contact: CNContact?) {
            if contact != nil {
                parent.vm.alert = .addContactSuccess
            }
        }
    }
}
