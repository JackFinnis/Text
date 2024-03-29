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
        UINavigationBar.appearance().titleTextAttributes = [.font: UIFont.roundedSystemFont(style: .headline)]
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
                .navigationDocument(Constants.appURL, preview: SharePreview(Constants.name, image: Image(.logo)))
                .toolbarTitleMenu {
                    Button {
                        requestReview()
                    } label: {
                        Label("Rate \(Constants.name)", systemImage: "star")
                    }
                    Button {
                        AppStore.writeReview()
                    } label: {
                        Label("Write a Review", systemImage: "quote.bubble")
                    }
                    if MFMailComposeViewController.canSendMail() {
                        Button {
                            showEmailSheet.toggle()
                        } label: {
                            Label("Send us Feedback", systemImage: "envelope")
                        }
                    } else if let url = Emails.url(subject: "\(Constants.name) Feedback"), UIApplication.shared.canOpenURL(url) {
                        Button {
                            UIApplication.shared.open(url)
                        } label: {
                            Label("Send us Feedback", systemImage: "envelope")
                        }
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Copy") {
                            UIPasteboard.general.string = text
                            refresh.toggle()
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
        .onChange(of: scenePhase) { _, _ in
            refresh.toggle()
        }
        .emailSheet(recipient: Constants.email, subject: "\(Constants.name) Feedback", isPresented: $showEmailSheet)
        .fontDesign(.rounded)
    }
}

#Preview {
    RootView()
}
