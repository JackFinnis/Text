//
//  TextView.swift
//  Text
//
//  Created by Jack Finnis on 12/02/2023.
//

import SwiftUI

extension UIFont {
    class func roundedSystemFont(ofSize size: CGFloat, weight: UIFont.Weight = .regular) -> UIFont {
        let systemFont = UIFont.systemFont(ofSize: size, weight: weight)
        guard let descriptor = systemFont.fontDescriptor.withDesign(.rounded) else { return systemFont }
        return UIFont(descriptor: descriptor, size: size)
    }
}

struct TextView: UIViewRepresentable {
    let textView = UITextView()
    let font = UIFont.roundedSystemFont(ofSize: UIFont.labelFontSize)
    let boldFont = UIFont.roundedSystemFont(ofSize: UIFont.labelFontSize, weight: .semibold)
    @State var wordCount = UIBarButtonItem()
    
    @Binding var text: String
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> UITextView {
        textView.delegate = context.coordinator
        textView.textContainerInset = UIEdgeInsets(top: Constants.verticalPadding, left: Constants.horizontalPadding, bottom: Constants.verticalPadding, right: Constants.horizontalPadding)
        textView.textContainer.lineFragmentPadding = 0
        textView.isUserInteractionEnabled = true
        textView.isScrollEnabled = true
        textView.isSelectable = true
        textView.isEditable = false
        textView.dataDetectorTypes = .all
        textView.linkTextAttributes = [
            .foregroundColor: UIColor.link,
            .underlineStyle: CTUnderlineStyle.single.rawValue
        ]
        
        let clearButton = UIBarButtonItem(title: "Clear", style: .plain, target: context.coordinator, action: #selector(Coordinator.clearText))
        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let dismissButton = UIBarButtonItem(title: "Done", style: .done, target: context.coordinator, action: #selector(Coordinator.stopEditing))
        
        wordCount.isEnabled = false
        wordCount.setTitleTextAttributes([.font: font], for: .normal)
        clearButton.setTitleTextAttributes([.font: font], for: .normal)
        clearButton.setTitleTextAttributes([.font: font], for: .selected)
        dismissButton.setTitleTextAttributes([.font: boldFont], for: .normal)
        dismissButton.setTitleTextAttributes([.font: boldFont], for: .selected)
        
        let toolbar = UIToolbar()
        toolbar.items = [clearButton, spacer, wordCount, spacer, dismissButton]
        toolbar.sizeToFit()
        textView.inputAccessoryView = toolbar
        
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap))
        tapGesture.delegate = context.coordinator
        textView.addGestureRecognizer(tapGesture)
        
        return textView
    }
    
    func updateUIView(_ textView: UITextView, context: Context) {
        textView.text = text
        textView.font = font
        wordCount.title = text.count.formatted(singular: "char") + " • " + text.words.formatted(singular: "word")
    }
    
    // MARK: - Coordinator
    class Coordinator: NSObject, UITextViewDelegate, UIGestureRecognizerDelegate {
        let parent: TextView
        
        init(_ parent: TextView) {
            self.parent = parent
        }
        
        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
        }
        
        func textViewDidBeginEditing(_ textView: UITextView) {
            if parent.text == Constants.welcomeMessage {
                parent.text = ""
            }
        }
        
        func textViewDidEndEditing(_ textView: UITextView) {
            textView.isEditable = false
            textView.dataDetectorTypes = .all
        }
        
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool { true }
        
        @objc
        func handleTap(_ tap: UITapGestureRecognizer) {
            let textView = parent.textView
            guard !textView.isEditable else { return }
            let point = tap.location(in: textView)
            guard let position = textView.closestPosition(to: point) else { return }
            let index = textView.offset(from: textView.beginningOfDocument, to: position)
            if index < textView.attributedText.length {
                let attributes = textView.attributedText.attributes(at: index, effectiveRange: nil)
                guard attributes[.link] == nil else { return }
            }
            
            textView.isEditable = true
            textView.becomeFirstResponder()
            textView.selectedTextRange = textView.textRange(from: position, to: position)
        }
        
        @objc
        func clearText() {
            parent.text = ""
        }
        
        @objc
        func stopEditing() {
            parent.textView.resignFirstResponder()
        }
    }
}
