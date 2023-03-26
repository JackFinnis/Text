//
//  TextView.swift
//  Text
//
//  Created by Jack Finnis on 12/02/2023.
//

import SwiftUI

struct TextView: UIViewRepresentable {
    @ObservedObject var vm: ViewModel
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = vm
        vm.textView = textView
        
        textView.textContainerInset = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
        textView.textContainer.lineFragmentPadding = .zero
        textView.isUserInteractionEnabled = true
        textView.isScrollEnabled = true
        textView.isEditable = true
        textView.isSelectable = true
        
        return textView
    }
    
    func updateUIView(_ textView: UITextView, context: Context) {
        textView.font = .systemFont(ofSize: UIFont.buttonFontSize)
    }
}
