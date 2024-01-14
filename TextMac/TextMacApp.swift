//
//  TextMacApp.swift
//  TextMac
//
//  Created by Jack Finnis on 15/08/2023.
//

import SwiftUI

@main
struct TextMacApp: App {
    @NSApplicationDelegateAdaptor var appDelegate: AppDelegate
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .onAppear {
                    NSWindow.allowsAutomaticWindowTabbing = false
                }
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 300, height: 200)
        .commands {
            CommandGroup(replacing: .help) {}
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}

// NSTextView NSViewRepresentable doesn't resize to window
extension NSTextView {
    open override var frame: NSRect { didSet {
        textContainer?.lineFragmentPadding = 12
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

struct RootView: View {
    @State var text = ""
    
    var body: some View {
        TextEditor(text: $text)
            .scrollContentBackground(.hidden)
            .font(.system(size: 15).monospaced())
            .toolbar {
                ToolbarItem(placement: .status) {
                    Text(text.count.formatted(singular: "char") + " • " + text.words.formatted(singular: "word"))
                        .foregroundStyle(.secondary)
                }
            }
    }
}
