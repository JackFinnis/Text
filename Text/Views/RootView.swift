//
//  ContentView.swift
//  Text
//
//  Created by Jack Finnis on 12/02/2023.
//

import SwiftUI
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

#Preview {
    RootView()
}
