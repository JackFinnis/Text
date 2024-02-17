//
//  TextView.swift
//  Text
//
//  Created by Jack Finnis on 12/02/2023.
//

import SwiftUI

struct TextView: UIViewRepresentable {
    @State var wordCount = UIBarButtonItem()
    let textView = UITextView()
    
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
        
        wordCount.tintColor = .secondaryLabel
        wordCount.setTitleTextAttributes([.font: UIFont.roundedSystemFont(style: .subheadline)], for: .normal)
        clearButton.setTitleTextAttributes([.font: UIFont.roundedSystemFont(style: .body)], for: .normal)
        clearButton.setTitleTextAttributes([.font: UIFont.roundedSystemFont(style: .body)], for: .selected)
        dismissButton.setTitleTextAttributes([.font: UIFont.roundedSystemFont(style: .headline)], for: .normal)
        dismissButton.setTitleTextAttributes([.font: UIFont.roundedSystemFont(style: .headline)], for: .selected)
        
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
        textView.font = UIFont.roundedSystemFont(style: .body)
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

#Preview {
    RootView()
}
