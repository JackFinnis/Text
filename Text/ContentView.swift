//
//  ContentView.swift
//  Text
//
//  Created by Jack Finnis on 28/08/2022.
//

import SwiftUI

struct ContentView: View {
    @State var text = ""
    @State var appeared = false
    
    var body: some View {
        TextEditor(text: $text)
            .font(.monospaced(.system(size: 15))())
            .frame(width: appeared ? nil : 300, height: appeared ? nil : 200)
            .task { appeared = true }
    }
}
