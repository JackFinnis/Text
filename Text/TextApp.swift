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
            ContentView()
        }
        .defaultSize(width: 300, height: 200)
    }
}

struct ContentView: View {
    @State var text = ""
    @State var monospaced = true
    
    var words: Int {
        NSSpellChecker.shared.countWords(in: text, language: nil)
    }
    
    var body: some View {
        NavigationStack {
            TextEditor(text: $text.animation())
                .font(monospaced ? .system(size: 15).monospaced() : .system(size: 15))
                .navigationTitle(text.isEmpty ? "" : (words == 1 ? "1 word" : "\(words) words"))
                .toolbar {
                    Toggle("Code", isOn: $monospaced.animation())
                }
        }
    }
}
