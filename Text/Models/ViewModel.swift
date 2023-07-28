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
    @Storage("text") var text = "" { didSet {
        textView?.text = text
        previousTexts.append(oldValue)
    }}
    @Published var editing = false
    var textView: UITextView?
    var words: Int {
        text.split { $0.isLetter }.count
    }
    
    // Results
    var tapRecogniser = UITapGestureRecognizer()
    var results = [NSTextCheckingResult]()
    var selectedResult: NSTextCheckingResult?
    @Published var event: EKEvent?
    @Published var error: TextError?
    
    @Published var showContactView = false
    var mapItem: MKMapItem? { didSet {
        showContactView = true
    }}
    var phoneNumber: String? { didSet {
        showContactView = true
    }}
    var email: String? { didSet {
        showContactView = true
    }}
    
    // MARK: - Initialiser
    override init() {
        super.init()
        tapRecogniser = UITapGestureRecognizer(target: self, action: #selector(ViewModel.handleTextTap))
    }
    
    // MARK: - Functions
    @objc
    func clearText() {
        text = ""
    }
    
    @objc
    func stopEditing() {
        textView?.resignFirstResponder()
    }
    
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
                self.error = .geocodeAddress
                return
            }
            let mapItem = MKMapItem(placemark: MKPlacemark(placemark: placemark))
            completion(mapItem)
        }
    }
    
    func createEvent(result: NSTextCheckingResult) {
        EKEventStore.shared.requestAccess(to: .event) { success, error in
            guard success else {
                self.error = .eventAuth
                return
            }
            let event = EKEvent(eventStore: .shared)
            event.timeZone = result.timeZone ?? .current
            event.startDate = result.date ?? .now
            event.endDate = event.startDate.addingTimeInterval(result.duration)
            DispatchQueue.main.async {
                self.event = event
            }
        }
    }
    
    func requestContactsAuth(completion: @escaping () -> Void) {
        CNContactStore.shared.requestAccess(for: .contacts) { success, error in
            guard success else {
                self.error = .contactsAuth
                return
            }
            completion()
        }
    }
    
    @objc
    func handleTextTap(tap: UITapGestureRecognizer) {
        guard let textView else { return }
        let point = tap.location(in: textView)
        if let result = getClosestResult(to: point) {
            performDefaultAction(for: result)
        } else if let position = textView.closestPosition(to: point) {
            textView.becomeFirstResponder()
            textView.selectedTextRange = textView.textRange(from: position, to: position)
        }
    }
    
    func performDefaultAction(for result: NSTextCheckingResult) {
        switch result.resultType {
        case .address:
            getMapItem(result: result) { mapItem in
                mapItem.openInMaps()
            }
        case .date:
            createEvent(result: result)
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
        textView.attributedText = NSAttributedString(string: text, attributes: plainAttributes)
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
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
            children.append(UIAction(title: "Get Directions", image: UIImage(systemName: "arrow.triangle.turn.up.right.diamond")) { action in
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
                self.requestContactsAuth {
                    self.getMapItem(result: selectedResult) { mapItem in
                        self.mapItem = mapItem
                    }
                }
            })
            children.append(UIAction(title: "Copy Address", image: UIImage(systemName: "doc.on.doc")) { action in
                UIPasteboard.general.string = title
                Haptics.success()
            })
            if let encodedAddress = title.urlEncoded,
               let url = URL(string: "https://maps.apple.com/?address=\(encodedAddress)") {
                children.append(UIAction(title: "Share...", image: UIImage(systemName: "square.and.arrow.up")) { action in
                    self.share(items: [url], point: location)
                })
            }
        case .date:
            children.append(UIAction(title: "Create Event", image: UIImage(systemName: "calendar.badge.plus")) { action in
                self.createEvent(result: selectedResult)
            })
            children.append(UIAction(title: "Copy Event", image: UIImage(systemName: "doc.on.doc")) { action in
                UIPasteboard.general.string = title
                Haptics.success()
            })
        case .link:
            guard let url = selectedResult.url else { return nil }
            if url.isMailto {
                guard let email = url.email else { return nil }
                title = email
                if UIApplication.shared.canOpenURL(url) {
                    children.append(UIAction(title: "New Mail Message", image: UIImage(systemName: "envelope")) { action in
                        UIApplication.shared.open(url)
                    })
                }
                children.append(UIAction(title: "Add to Contacts", image: UIImage(systemName: "person.crop.circle.badge.plus")) { action in
                    self.requestContactsAuth {
                        self.email = email
                    }
                })
                children.append(UIAction(title: "Copy Email", image: UIImage(systemName: "doc.on.doc")) { action in
                    UIPasteboard.general.string = email
                    Haptics.success()
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
                    Haptics.success()
                })
                children.append(UIAction(title: "Share...", image: UIImage(systemName: "square.and.arrow.up")) { action in
                    self.share(items: [url], point: location)
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
                self.requestContactsAuth {
                    self.phoneNumber = number
                }
            })
            children.append(UIAction(title: "Copy Number", image: UIImage(systemName: "doc.on.doc")) { action in
                UIPasteboard.general.string = number
                Haptics.success()
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
            
            let size = CGSize(width: 300, height: 350)
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
            let size = CGSize(width: 300, height: 250)
            let mapView = MKMapView(frame: CGRect(origin: .zero, size: size))
            mapView.isRotateEnabled = false
            mapView.isPitchEnabled = false
            mapView.showsUserLocation = true
            preview = mapView
            
            getMapItem(result: selectedResult) { mapItem in
                let delta = 0.02
                let span = MKCoordinateSpan(latitudeDelta: delta, longitudeDelta: delta)
                mapView.region = MKCoordinateRegion(center: mapItem.placemark.coordinate, span: span)
                let annotation = MKPointAnnotation()
                annotation.coordinate = mapItem.placemark.coordinate
                mapView.addAnnotation(annotation)
            }
        default: break
        }
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(handlePreviewTap))
        tap.delegate = self
        preview.addGestureRecognizer(tap)
        
        let rect = textView.layoutManager.boundingRect(forGlyphRange: selectedResult.range, in: textView.textContainer)
        let target = UIPreviewTarget(container: textView, center: CGPoint(x: rect.midX, y: rect.midY))
        return UITargetedPreview(view: preview, parameters: UIPreviewParameters(), target: target)
    }
    
    @objc func handlePreviewTap() {
        guard let selectedResult else { return }
        performDefaultAction(for: selectedResult)
    }
    
    func share(items: [Any], point: CGPoint) {
        let shareVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
        shareVC.popoverPresentationController?.sourceView = textView
        shareVC.popoverPresentationController?.sourceRect = CGRect(origin: point, size: .zero)
        textView?.window?.rootViewController?.present(shareVC, animated: true)
    }
}

// MARK: - WKNavigationDelegate
extension ViewModel: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool { true }
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
        let config = UIImage.SymbolConfiguration(font: .systemFont(ofSize: 22))
        let image = UIImage(systemName: "wifi.slash", withConfiguration: config)
        let imageView = UIImageView(image: image)
        imageView.tintColor = .secondaryLabel
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
