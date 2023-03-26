//
//  ViewModel.swift
//  Text
//
//  Created by Jack Finnis on 12/02/2023.
//

import UIKit
import EventKit
import MapKit
import Contacts

@MainActor
class ViewModel: NSObject, ObservableObject {
    // MARK: - Properties
    // Text
    let defaultAttributes: [NSAttributedString.Key: Any] = [.foregroundColor : UIColor.label, .font : UIFont.systemFont(ofSize: UIFont.buttonFontSize)]
    @Published var previousTexts = [String]()
    @Published var text = "" { didSet {
        textView?.text = text
        previousTexts.append(oldValue)
    }}
    @Published var editing = false
    var textView: UITextView?
    var words: Int {
        text.split { $0.isLetter }.count
    }
    
    // Results
    @Published var event: EKEvent?
    var tapRecogniser = UITapGestureRecognizer()
    var results = [NSTextCheckingResult]()
    
    // MARK: - Initialiser
    override init() {
        super.init()
        tapRecogniser = UITapGestureRecognizer(target: self, action: #selector(ViewModel.handleTap))
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
    
    @objc
    func handleTap(tap: UITapGestureRecognizer) {
        guard let textView else { return }
        let point = tap.location(in: textView)
        guard let position = textView.closestPosition(to: point) else { return }
        let index = textView.offset(from: textView.beginningOfDocument, to: position)
        
        if let result = results.first(where: { $0.range.contains(index) }) {
            switch result.resultType {
            case .address:
                let address = NSString(string: text).substring(with: result.range)
                CLGeocoder().geocodeAddressString(address) { placemarks, error in
                    guard let placemark = placemarks?.first else { return }
                    let mapItem = MKMapItem(placemark: MKPlacemark(placemark: placemark))
                    mapItem.openInMaps()
                }
            case .date:
                EKEventStore.shared.requestAccess(to: .event) { success, error in
                    guard success else { return }
                    DispatchQueue.main.async {
                        self.event = EKEvent(date: result.date ?? .now, duration: result.duration, timeZone: result.timeZone ?? .current)
                    }
                }
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
        } else {
            textView.becomeFirstResponder()
            textView.selectedTextRange = textView.textRange(from: position, to: position)
        }
    }
    
    func addAttributes() {
        detectData()
        let attributes = NSMutableAttributedString(string: text, attributes: defaultAttributes)
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
        textView.attributedText = NSAttributedString(string: text, attributes: defaultAttributes)
        textView.removeGestureRecognizer(tapRecogniser)
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        DispatchQueue.main.async {
            self.editing = false
        }
        addAttributes()
    }
}
