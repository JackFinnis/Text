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
    
    func makeUIViewController(context: Context) -> UINavigationController {
        let contact = CNMutableContact()
        if let address = vm.mapItem?.placemark.postalAddress {
            contact.postalAddresses = [CNLabeledValue(label: CNLabelHome, value: address)]
        }
        if let number = vm.phoneNumber {
            contact.phoneNumbers = [CNLabeledValue(label: CNLabelPhoneNumberMain, value: CNPhoneNumber(stringValue: number))]
        }
        if let email = vm.email {
            contact.emailAddresses = [CNLabeledValue(label: CNLabelHome, value: email as NSString)]
        }
        
        let contactVC = CNContactViewController(forUnknownContact: contact)
        contactVC.contactStore = .shared
        contactVC.navigationItem.leftBarButtonItem = UIBarButtonItem(systemItem: .done, primaryAction: UIAction { _ in
            contactVC.dismiss(animated: true)
        })
        
        return UINavigationController(rootViewController: contactVC)
    }
    
    func updateUIViewController(_ vc: UINavigationController, context: Context) {}
}
