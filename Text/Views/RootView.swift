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
    @Environment(\.requestReview) var requestReview
    @Environment(\.scenePhase) var scenePhase
    @AppStorage("text") var text = ""
    @State var showEmailSheet = false
    @State var refresh = false
    
    init() {
        UINavigationBar.appearance().titleTextAttributes = [.font: UIFont.systemFont(.body, weight: .semibold, design: .rounded)]
    }
    
    var body: some View {
        NavigationStack {
            TextView(text: $text)
                .overlay(alignment: .topLeading) {
                    if text.isEmpty {
                        Text(Constants.welcomeMessage)
                            .padding(.vertical, Constants.verticalPadding)
                            .padding(.horizontal, Constants.horizontalPadding)
                            .foregroundColor(Color(.placeholderText))
                            .allowsHitTesting(false)
                    }
                }
                .navigationTitle(Constants.name)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Copy") {
                            UIPasteboard.general.string = text
                            Haptics.tap()
                        }
                        .disabled(text.isEmpty)
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Button("Paste") {
                            text = UIPasteboard.general.string ?? ""
                        }
                        .disabled(!UIPasteboard.general.hasStrings)
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
