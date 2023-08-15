//
//  ViewModel.swift
//  Text
//
//  Created by Jack Finnis on 12/02/2023.
//

import UIKit
import EventKitUI
import MapKit
import Contacts
import SwiftUI
import WebKit
import ContactsUI

@MainActor
class ViewModel: NSObject, ObservableObject {
    // MARK: - Properties
    let plainAttributes: [NSAttributedString.Key: Any] = [
        .foregroundColor: UIColor.label,
        .font: UIFont.systemFont(ofSize: UIFont.buttonFontSize)
    ]
    @Storage("previousTexts") var previousTexts = [String]() { didSet {
        objectWillChange.send()
    }}
    @Storage("text") var text = Constants.welcomeMessage { didSet {
        textView?.text = text
    }}
    @Published var editing = false
    var textView: UITextView?
    
    // Results
    var tapRecogniser = UITapGestureRecognizer()
    var results = [NSTextCheckingResult]()
    var selectedResult: NSTextCheckingResult?
    
    @Published var showAlert = false
    @Published var alert = TextAlert.addContactSuccess { didSet {
        showAlert.toggle()
    }}
    
    // MARK: - Initialiser
    override init() {
        super.init()
        tapRecogniser = UITapGestureRecognizer(target: self, action: #selector(ViewModel.handleTextTap))
    }
    
    // MARK: - Functions
    func detectData() {
        let types: NSTextCheckingResult.CheckingType = [.address, .date, .link, .phoneNumber]
        let detector = try? NSDataDetector(types: types.rawValue)
        results = detector?.matches(in: text, range: NSRange(location: 0, length: text.count)) ?? []
    }
    
    func undoEdit() {
        guard let text = previousTexts.popLast() else { return }
        self.text = text
        textView?.becomeFirstResponder()
    }
    
    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
    
    func getClosestResult(to point: CGPoint) -> NSTextCheckingResult? {
        guard let textView,
              let position = textView.closestPosition(to: point)
        else { return nil }
        let index = textView.offset(from: textView.beginningOfDocument, to: position)
        return results.first { $0.range.contains(index) }
    }
    
    func getMapItem(result: NSTextCheckingResult, completion: @escaping (MKMapItem) -> Void) {
        let address = NSString(string: text).substring(with: result.range)
        CLGeocoder().geocodeAddressString(address) { placemarks, error in
            guard let placemark = placemarks?.first else {
                self.alert = .geocodeAddressError
                return
            }
            let mapItem = MKMapItem(placemark: MKPlacemark(placemark: placemark))
            completion(mapItem)
        }
    }
    
    func createEvent(result: NSTextCheckingResult, anchor: CGPoint) {
        func completion(_ event: EKEvent) {
            let vc = EKEventEditViewController()
            vc.event = event
            vc.eventStore = .shared
            vc.editViewDelegate = self
            present(vc, anchor: anchor)
        }
        
        EKEventStore.shared.requestAccess(to: .event) { success, error in
            DispatchQueue.main.async {
                guard success else {
                    self.alert = .eventAuthError
                    return
                }
                let event = EKEvent(eventStore: .shared)
                event.timeZone = result.timeZone ?? .current
                event.startDate = result.date ?? .now
                event.endDate = event.startDate.addingTimeInterval(result.duration)
                event.isAllDay = result.duration == 0
                if let address = self.results.first(where: { $0.resultType == .address }) {
                    self.getMapItem(result: address) { mapItem in
                        event.structuredLocation = EKStructuredLocation(mapItem: mapItem)
                        completion(event)
                    }
                } else {
                    completion(event)
                }
            }
        }
    }
    
    func extractContactDetails(anchor: CGPoint, mapItem: MKMapItem? = nil) {
        CNContactStore.shared.requestAccess(for: .contacts) { success, error in
            DispatchQueue.main.async {
                guard success else {
                    self.alert = .contactsAuthError
                    return
                }
                let contact = CNMutableContact()
                if let address = mapItem?.placemark.postalAddress {
                    contact.postalAddresses = [CNLabeledValue(label: CNLabelHome, value: address)]
                }
                
                let phoneNumbers = self.results.map { $0.phoneNumber }.compactMap { $0 }.filter(\.isNotEmpty)
                contact.phoneNumbers = phoneNumbers.map { number in
                    CNLabeledValue(label: CNLabelPhoneNumberMain, value: CNPhoneNumber(stringValue: number))
                }
                
                let emails = self.results.map { $0.url }.compactMap { $0 }.filter(\.isMailto).map(\.email).compactMap { $0 }.filter(\.isNotEmpty)
                contact.emailAddresses = emails.map { email in
                    CNLabeledValue(label: CNLabelHome, value: email as NSString)
                }
                
                let contactVC = CNContactViewController(forUnknownContact: contact)
                contactVC.contactStore = .shared
                contactVC.delegate = self
                contactVC.navigationItem.rightBarButtonItem = UIBarButtonItem(systemItem: .cancel, primaryAction: UIAction { _ in
                    contactVC.dismiss(animated: true)
                })
                
                let navVC = UINavigationController(rootViewController: contactVC)
                self.present(navVC, anchor: anchor)
            }
        }
    }
    
    func performDefaultAction(for result: NSTextCheckingResult, anchor: CGPoint) {
        switch result.resultType {
        case .address:
            getMapItem(result: result) { mapItem in
                mapItem.openInMaps()
            }
        case .date:
            createEvent(result: result, anchor: anchor)
        case .link:
            guard let url = result.url else { return }
            UIApplication.shared.open(url)
        case .phoneNumber:
            guard let number = result.phoneNumber,
                  let url = URL(string: "tel://\(number)")
            else { return }
            UIApplication.shared.open(url)
        default:
            break
        }
    }
    
    func addAttributes() {
        detectData()
        let string = NSMutableAttributedString(string: text, attributes: plainAttributes)
        for result in results {
            if let attributes = result.attributes {
                string.addAttributes(attributes, range: result.range)
            }
        }
        textView?.attributedText = string
        textView?.addGestureRecognizer(tapRecogniser)
    }
}

// MARK: - UITextViewDelegate
extension ViewModel: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        text = textView.text
        previousTexts.append(text)
        textView.attributedText = NSAttributedString(string: text, attributes: plainAttributes)
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if text == Constants.welcomeMessage {
            text = ""
        }
        DispatchQueue.main.async {
            self.editing = true
        }
        results = []
        textView.attributedText = NSAttributedString(string: text, attributes: plainAttributes)
        textView.removeGestureRecognizer(tapRecogniser)
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        DispatchQueue.main.async {
            self.editing = false
        }
        addAttributes()
    }
}

// MARK: - UIContextMenuInteractionDelegate
extension ViewModel: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        selectedResult = getClosestResult(to: location)
        guard let selectedResult else { return nil }
        var title = NSString(string: text).substring(with: selectedResult.range)
        var children = [UIMenuElement]()
        switch selectedResult.resultType {
        case .address:
            children.append(UIAction(title: "Get Directions", image: UIImage(systemName: "arrow.triangle.turn.up.right.circle")) { action in
                self.getMapItem(result: selectedResult) { mapItem in
                    mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDefault])
                }
            })
            children.append(UIAction(title: "Open in Maps", image: UIImage(systemName: "map")) { action in
                self.getMapItem(result: selectedResult) { mapItem in
                    mapItem.openInMaps()
                }
            })
            children.append(UIAction(title: "Add to Contacts", image: UIImage(systemName: "person.crop.circle.badge.plus")) { action in
                self.getMapItem(result: selectedResult) { mapItem in
                    self.extractContactDetails(anchor: location, mapItem: mapItem)
                }
            })
            children.append(UIAction(title: "Copy Address", image: UIImage(systemName: "doc.on.doc")) { action in
                UIPasteboard.general.string = title
                Haptics.tap()
            })
            if let encodedAddress = title.urlEncoded,
               let url = URL(string: "https://maps.apple.com/?address=\(encodedAddress)") {
                children.append(UIAction(title: "Share...", image: UIImage(systemName: "square.and.arrow.up")) { action in
                    self.share(items: [url], anchor: location)
                })
            }
        case .date:
            children.append(UIAction(title: "Create Event", image: UIImage(systemName: "calendar.badge.plus")) { action in
                self.createEvent(result: selectedResult, anchor: location)
            })
            children.append(UIAction(title: "Copy Event", image: UIImage(systemName: "doc.on.doc")) { action in
                UIPasteboard.general.string = title
                Haptics.tap()
            })
        case .link:
            guard let url = selectedResult.url else { return nil }
            if url.isMailto {
                guard let email = url.email else { return nil }
                title = email
                if UIApplication.shared.canOpenURL(url) {
                    children.append(UIAction(title: "Send Email", image: UIImage(systemName: "envelope")) { action in
                        UIApplication.shared.open(url)
                    })
                }
                children.append(UIAction(title: "Add to Contacts", image: UIImage(systemName: "person.crop.circle.badge.plus")) { action in
                    self.extractContactDetails(anchor: location)
                })
                children.append(UIAction(title: "Copy Email", image: UIImage(systemName: "doc.on.doc")) { action in
                    UIPasteboard.general.string = email
                    Haptics.tap()
                })
            } else {
                title = url.absoluteString
                if UIApplication.shared.canOpenURL(url) {
                    children.append(UIAction(title: "Open Link", image: UIImage(systemName: "safari")) { action in
                        UIApplication.shared.open(url)
                    })
                }
                children.append(UIAction(title: "Copy Link", image: UIImage(systemName: "doc.on.doc")) { action in
                    UIPasteboard.general.url = url
                    Haptics.tap()
                })
                children.append(UIAction(title: "Share...", image: UIImage(systemName: "square.and.arrow.up")) { action in
                    self.share(items: [url], anchor: location)
                })
            }
        case .phoneNumber:
            guard let number = selectedResult.phoneNumber else { return nil }
            title = number
            if let url = URL(string: "tel:\(number)"), UIApplication.shared.canOpenURL(url) {
                children.append(UIAction(title: "Call \(number)", image: UIImage(systemName: "phone")) { action in
                    UIApplication.shared.open(url)
                })
            }
            if let url = URL(string: "sms:\(number)"), UIApplication.shared.canOpenURL(url) {
                children.append(UIAction(title: "Send Message", image: UIImage(systemName: "message")) { action in
                    UIApplication.shared.open(url)
                })
            }
            children.append(UIAction(title: "Add to Contacts", image: UIImage(systemName: "person.crop.circle.badge.plus")) { action in
                self.extractContactDetails(anchor: location)
            })
            children.append(UIAction(title: "Copy Number", image: UIImage(systemName: "doc.on.doc")) { action in
                UIPasteboard.general.string = number
                Haptics.tap()
            })
        default:
            return nil
        }
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            UIMenu(title: title, children: children)
        }
    }
    
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, previewForHighlightingMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        guard let selectedResult, let textView else { return nil }
        
        var preview = UIView()
        switch selectedResult.resultType {
        case .link:
            guard let url = selectedResult.url,
                  url.isWebsite
            else { break }
            
            let size = CGSize(width: 400, height: 500)
            let webView = WKWebView(frame: CGRect(origin: .zero, size: size))
            webView.isOpaque = false
            webView.navigationDelegate = self
            webView.load(URLRequest(url: url))
            preview = webView
            
            let spinner = UIActivityIndicatorView(style: .medium)
            spinner.startAnimating()
            spinner.center = webView.center
            webView.addSubview(spinner)
            webView.sendSubviewToBack(spinner)
        case .address:
            let size = CGSize(width: 400, height: 400)
            let mapView = MKMapView(frame: CGRect(origin: .zero, size: size))
            mapView.isRotateEnabled = false
            mapView.isPitchEnabled = false
            mapView.isHidden = true
            mapView.showsUserLocation = true
            preview = mapView
            
            getMapItem(result: selectedResult) { mapItem in
                let delta = 0.02
                let span = MKCoordinateSpan(latitudeDelta: delta, longitudeDelta: delta)
                mapView.region = MKCoordinateRegion(center: mapItem.placemark.coordinate, span: span)
                
                let annotation = MKPointAnnotation()
                annotation.coordinate = mapItem.placemark.coordinate
                mapView.addAnnotation(annotation)
                
                mapView.isHidden = false
            }
            
            let tap = UITapGestureRecognizer(target: self, action: #selector(handlePreviewTap))
            tap.delegate = self
            preview.addGestureRecognizer(tap)
        default: break
        }
        
        let rect = textView.layoutManager.boundingRect(forGlyphRange: selectedResult.range, in: textView.textContainer)
        let target = UIPreviewTarget(container: textView, center: CGPoint(x: rect.midX, y: rect.midY))
        return UITargetedPreview(view: preview, parameters: UIPreviewParameters(), target: target)
    }
    
    func share(items: [Any], anchor: CGPoint) {
        let shareVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
        present(shareVC, anchor: anchor)
    }
    
    func present(_ vc: UIViewController, anchor: CGPoint) {
        vc.modalPresentationStyle = .popover
        vc.popoverPresentationController?.sourceView = textView
        vc.popoverPresentationController?.sourceRect = CGRect(origin: anchor, size: .zero)
        textView?.window?.rootViewController?.present(vc, animated: true)
    }
}

// MARK: - UIGestureRecognizerDelegate
extension ViewModel: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool { true }
    
    @objc func handlePreviewTap() {
        guard let selectedResult else { return }
        performDefaultAction(for: selectedResult, anchor: .zero)
    }
    
    @objc
    func handleTextTap(tap: UITapGestureRecognizer) {
        guard let textView else { return }
        let point = tap.location(in: textView)
        if let result = getClosestResult(to: point) {
            performDefaultAction(for: result, anchor: point)
        } else if let position = textView.closestPosition(to: point) {
            textView.becomeFirstResponder()
            textView.selectedTextRange = textView.textRange(from: position, to: position)
        }
    }
    
    @objc
    func clearText() {
        text = ""
    }
    
    @objc
    func stopEditing() {
        textView?.resignFirstResponder()
    }
}

// MARK: - WKNavigationDelegate
extension ViewModel: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webViewFinished(webView)
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        webViewFailed(webView)
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        webViewFailed(webView)
    }
    
    func webViewFailed(_ webView: WKWebView) {
        webViewFinished(webView)
        let font = UIImage.SymbolConfiguration(font: .systemFont(ofSize: 25))
        let rendering = UIImage.SymbolConfiguration(hierarchicalColor: .secondaryLabel)
        let image = UIImage(systemName: "wifi.slash", withConfiguration: font.applying(rendering))
        let imageView = UIImageView(image: image)
        imageView.center = webView.center
        webView.addSubview(imageView)
    }
    
    func webViewFinished(_ webView: WKWebView) {
        webView.subviews.forEach { subview in
            if let spinner = subview as? UIActivityIndicatorView {
                spinner.stopAnimating()
            }
        }
    }
}

// MARK: - EKEventEditViewDelegate
extension ViewModel: EKEventEditViewDelegate {
    func eventEditViewController(_ vc: EKEventEditViewController, didCompleteWith action: EKEventEditViewAction) {
        if action == .saved, let event = vc.event {
            do {
                try EKEventStore.shared.save(event, span: .thisEvent)
                alert = .addEventSuccess
            } catch {
                alert = .addEventError
            }
        }
        vc.dismiss(animated: true)
    }
}

extension ViewModel: CNContactViewControllerDelegate {
    func contactViewController(_ contactVC: CNContactViewController, didCompleteWith contact: CNContact?) {
        contactVC.parent?.dismiss(animated: true)
        if contact != nil {
            self.alert = .addContactSuccess
        }
    }
}
