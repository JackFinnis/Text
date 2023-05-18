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
import WebKit
import SafariServices

@MainActor
class ViewModel: NSObject, ObservableObject {
    // MARK: - Properties
    // Text
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
    @Published var showShareSheet = false
    var shareItems = [Any]() { didSet {
        showShareSheet = true
    }}
    @Published var showAlert = false
    var alert: TextAlert? { didSet {
        showAlert = true
    }}
    @Published var showContactView = false
    var mapItem: MKMapItem? { didSet {
        showContactView = true
    }}
    var phoneNumber: String? { didSet {
        showContactView = true
    }}
    
    // MARK: - Initialiser
    override init() {
        super.init()
        tapRecogniser = UITapGestureRecognizer(target: self, action: #selector(ViewModel.handleTap))
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
                self.alert = .geocodeAddressError
                return
            }
            let mapItem = MKMapItem(placemark: MKPlacemark(placemark: placemark))
            completion(mapItem)
        }
    }
    
    func createEvent(result: NSTextCheckingResult) {
        EKEventStore.shared.requestAccess(to: .event) { success, error in
            guard success else {
                self.alert = .eventAuthDenied
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
    
    @objc
    func handleTap(tap: UITapGestureRecognizer) {
        guard let textView else { return }
        let point = tap.location(in: textView)
        if let result = getClosestResult(to: point) {
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
        } else if let position = textView.closestPosition(to: point) {
            textView.becomeFirstResponder()
            textView.selectedTextRange = textView.textRange(from: position, to: position)
        }
    }
    
    func addAttributes() {
        detectData()
        let attributes = NSMutableAttributedString(string: text, attributes: plainAttributes)
        for result in results {
            attributes.addAttribute(.foregroundColor, value: UIColor(.accentColor), range: result.range)
            attributes.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: result.range)
        }
        textView?.attributedText = attributes
        textView?.addGestureRecognizer(tapRecogniser)
    }
}

// MARK: - UITextViewDelegate
extension ViewModel: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        text = textView.text
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        DispatchQueue.main.async {
            self.editing = true
        }
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
                self.getMapItem(result: selectedResult) { mapItem in
                    self.mapItem = mapItem
                }
            })
            children.append(UIAction(title: "Copy Address", image: UIImage(systemName: "doc.on.doc")) { action in
                UIPasteboard.general.string = title
            })
            children.append(UIAction(title: "Share...", image: UIImage(systemName: "square.and.arrow.up")) { action in
                self.getMapItem(result: selectedResult) { mapItem in
                    let coord = mapItem.placemark.coordinate
                    guard let url = URL(string: "https://maps.apple.com/?ll=\(coord.latitude),\(coord.longitude)") else {
                        self.alert = .shareAddressUrlError
                        return
                    }
                    self.shareItems = [url]
                }
            })
        case .date:
            children.append(UIAction(title: "Create Event", image: UIImage(systemName: "calendar.badge.plus")) { action in
                self.createEvent(result: selectedResult)
            })
            children.append(UIAction(title: "Copy Event", image: UIImage(systemName: "doc.on.doc")) { action in
                UIPasteboard.general.string = title
            })
        case .link:
            guard let url = selectedResult.url else { return nil }
            title = url.absoluteString
            children.append(UIAction(title: "Open Link", image: UIImage(systemName: "safari")) { action in
                UIApplication.shared.open(url)
            })
            if SSReadingList.supportsURL(url) {
                children.append(UIAction(title: "Add to Reading List", image: UIImage(systemName: "eyeglasses")) { action in
                    do {
                        try SSReadingList.default()?.addItem(with: url, title: nil, previewText: nil)
                        self.alert = .addToReadingListSuccess
                    } catch {
                        self.alert = .addToReadingListError
                    }
                })
            }
            children.append(UIAction(title: "Copy Link", image: UIImage(systemName: "doc.on.doc")) { action in
                UIPasteboard.general.url = url
            })
            children.append(UIAction(title: "Share...", image: UIImage(systemName: "square.and.arrow.up")) { action in
                self.shareItems = [url]
            })
        case .phoneNumber:
            guard let number = selectedResult.phoneNumber else { return nil }
            title = number
            children.append(UIAction(title: "Call \(number)", image: UIImage(systemName: "phone")) { action in
                guard let url = URL(string: "tel://\(number)") else { return }
                UIApplication.shared.open(url)
            })
            children.append(UIAction(title: "Add to Contacts", image: UIImage(systemName: "person.crop.circle.badge.plus")) { action in
                self.phoneNumber = number
            })
            children.append(UIAction(title: "Copy Number", image: UIImage(systemName: "doc.on.doc")) { action in
                UIPasteboard.general.string = number
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
        let rect = textView.layoutManager.boundingRect(forGlyphRange: selectedResult.range, in: textView.textContainer)
        let target = UIPreviewTarget(container: textView, center: CGPoint(x: rect.midX, y: rect.midY))
        
        let preview: UIView
        switch selectedResult.resultType {
        case .link:
            guard let url = selectedResult.url else { fallthrough }
            let size = CGSize(width: 300, height: 350)
            let webView = WKWebView(frame: CGRect(origin: .zero, size: size))
            webView.load(URLRequest(url: url))
            preview = webView
        case .address:
            let size = CGSize(width: 300, height: 300)
            let mapView = MKMapView(frame: CGRect(origin: .zero, size: size))
            preview = mapView
            getMapItem(result: selectedResult) { mapItem in
                let delta = 0.02
                let span = MKCoordinateSpan(latitudeDelta: delta, longitudeDelta: delta)
                mapView.region = MKCoordinateRegion(center: mapItem.placemark.coordinate, span: span)
                let annotation = MKPointAnnotation()
                annotation.coordinate = mapItem.placemark.coordinate
                mapView.addAnnotation(annotation)
            }
        default:
            preview = UIView()
        }
        
        return UITargetedPreview(view: preview, parameters: UIPreviewParameters(), target: target)
    }
}
