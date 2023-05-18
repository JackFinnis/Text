//
//  TextView.swift
//  Text
//
//  Created by Jack Finnis on 12/02/2023.
//

import SwiftUI

struct TextView: UIViewRepresentable {
    @EnvironmentObject var vm: ViewModel
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = vm
        vm.textView = textView
        
        textView.text = vm.text
        vm.addAttributes()
        
        textView.textContainerInset = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
        textView.textContainer.lineFragmentPadding = 0
        textView.isUserInteractionEnabled = true
        textView.isScrollEnabled = true
        textView.isEditable = true
        textView.isSelectable = true
        
        let toolbar = UIToolbar()
        let clearButton = UIBarButtonItem(title: "Clear", style: .plain, target: vm, action: #selector(ViewModel.clearText))
        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let dismissButton = UIBarButtonItem(title: "Done", style: .done, target: vm, action: #selector(ViewModel.stopEditing))
        toolbar.items = [clearButton, spacer, dismissButton]
        toolbar.sizeToFit()
        textView.inputAccessoryView = toolbar
        
        textView.addInteraction(UIContextMenuInteraction(delegate: vm))
        
        return textView
    }
    
    func updateUIView(_ textView: UITextView, context: Context) {
        textView.font = .systemFont(ofSize: UIFont.buttonFontSize)
    }
}
