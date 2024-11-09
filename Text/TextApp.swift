//
//  TextApp.swift
//  Text
//
//  Created by Jack Finnis on 28/08/2022.
//

import SwiftUI

@main
struct TextApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 300, height: 200)
    }
}

#if os(macOS)
struct RootView: View {
    @State var text = ""
    
    var body: some View {
        TextEditor(text: $text)
            .scrollContentBackground(.hidden)
            .font(.system(size: 15).monospaced())
    }
}

extension NSTextView {
    open override var frame: NSRect { didSet {
        textContainer?.lineFragmentPadding = 8
        smartInsertDeleteEnabled = true
        isAutomaticDataDetectionEnabled = true
        isAutomaticLinkDetectionEnabled = true
        isAutomaticTextCompletionEnabled = true
        isAutomaticTextReplacementEnabled = true
        isAutomaticDashSubstitutionEnabled = false
        isAutomaticQuoteSubstitutionEnabled = false
        isAutomaticSpellingCorrectionEnabled = true
        isGrammarCheckingEnabled = true
        isIncrementalSearchingEnabled = true
        isContinuousSpellCheckingEnabled = true
    }}
}
#else
import MessageUI
import StoreKit

struct RootView: View {
    @AppStorage("text") var text = ""
    @State var refresh = false
    
    init() {
        UINavigationBar.appearance().titleTextAttributes = [.font: UIFont.systemFont(.body, weight: .semibold, design: .rounded)]
    }
    
    var body: some View {
        NavigationStack {
            TextView(text: $text)
                .navigationTitle("Notepad")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Copy") {
                            UIPasteboard.general.string = text
                        }
                        .disabled(text.isEmpty)
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Button("Paste") {
                            text = UIPasteboard.general.string ?? ""
                        }
                        .disabled(!UIPasteboard.general.hasStrings)
                        .id(refresh)
                    }
                }
        }
        .fontDesign(.rounded)
        .onReceive(NotificationCenter.default.publisher(for: UIPasteboard.changedNotification)) { _ in
            refresh.toggle()
        }
    }
}

struct TextView: UIViewRepresentable {
    @State var wordCount = UIBarButtonItem()
    let textView = UITextView()
    
    @Binding var text: String
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> UITextView {
#if os(iOS)
        let verticalPadding = 8.0
        let horizontalPadding = 16.0
#elseif os(visionOS)
        let verticalPadding = 0.0
        let horizontalPadding = 25.0
#endif
        
        textView.delegate = context.coordinator
        textView.font = UIFont.systemFont(.body, design: .rounded)
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
        
        let clearButton = UIBarButtonItem(title: "Clear", style: .plain, target: context.coordinator, action: #selector(Coordinator.clear))
        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let dismissButton = UIBarButtonItem(title: "Done", style: .done, target: context.coordinator, action: #selector(Coordinator.stopEditing))
        
        wordCount.tintColor = .secondaryLabel
        wordCount.setTitleTextAttributes([.font: UIFont.systemFont(.subheadline, design: .rounded)], for: .normal)
        clearButton.setTitleTextAttributes([.font: UIFont.systemFont(.body, design: .rounded)], for: .normal)
        clearButton.setTitleTextAttributes([.font: UIFont.systemFont(.body, design: .rounded)], for: .selected)
        dismissButton.setTitleTextAttributes([.font: UIFont.systemFont(.headline, weight: .semibold, design: .rounded)], for: .normal)
        dismissButton.setTitleTextAttributes([.font: UIFont.systemFont(.headline, weight: .semibold, design: .rounded)], for: .selected)
        
        let toolbar = UIToolbar()
        toolbar.items = [clearButton, spacer, wordCount, spacer, dismissButton]
        toolbar.sizeToFit()
#if os(iOS)
        textView.inputAccessoryView = toolbar
#endif
        
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap))
        tapGesture.delegate = context.coordinator
        textView.addGestureRecognizer(tapGesture)
        
        return textView
    }
    
    func updateUIView(_ textView: UITextView, context: Context) {
        textView.text = text
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
        
        func textViewDidEndEditing(_ textView: UITextView) {
            textView.isEditable = false
            textView.dataDetectorTypes = .all
        }
        
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            true
        }
        
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
        func clear() {
            parent.text = ""
        }
        
        @objc
        func stopEditing() {
            parent.textView.resignFirstResponder()
        }
    }
}

extension UIFont {
    class func systemFont(_ style: TextStyle = .body, weight: UIFont.Weight = .regular, design: UIFontDescriptor.SystemDesign = .default) -> UIFont {
        let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: style).withDesign(design)!.addingAttributes([.traits : [UIFontDescriptor.TraitKey.weight : weight]])
        return UIFont(descriptor: descriptor, size: descriptor.pointSize)
    }
}

#Preview {
    RootView()
}
#endif

extension String {
    var words: Int {
        split { !$0.isLetter }.filter(\.isNotEmpty).count
    }
}

extension Int {
    func formatted(singular word: String) -> String {
        "\(self) " + word + (self == 1 ? "" : "s")
    }
}

extension Collection {
    var isNotEmpty: Bool { !isEmpty }
}
