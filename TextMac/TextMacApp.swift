//
//  TextMacApp.swift
//  TextMac
//
//  Created by Jack Finnis on 15/08/2023.
//

import SwiftUI

@main
struct TextMacApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 300, height: 200)
    }
}

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
