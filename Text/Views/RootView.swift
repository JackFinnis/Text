//
//  ContentView.swift
//  Text
//
//  Created by Jack Finnis on 12/02/2023.
//

import SwiftUI
import MessageUI

struct RootView: View {
    class ViewModel: ObservableObject {}
    @StateObject var vm = ViewModel()
    
    @Environment(\.scenePhase) var scenePhase
    @State var showEmailSheet = false
    @State var showSharePopover = false
    @AppStorage("text") var text = ""
    
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
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Copy") {
                            UIPasteboard.general.string = text
                            vm.objectWillChange.send()
                            Haptics.tap()
                        }
                        .disabled(text.isEmpty)
                    }
                    ToolbarItem(placement: .principal) {
                        Menu {
                            ShareLink(item: Constants.appURL) {
                                Label("Share \(Constants.name)", systemImage: "square.and.arrow.up")
                            }
                            Button {
                                Store.requestRating()
                            } label: {
                                Label("Rate \(Constants.name)", systemImage: "star")
                            }
                            Button {
                                Store.writeReview()
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
                        } label: {
                            HStack {
                                Text(Constants.name)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                MenuChevron()
                            }
                        }
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Button("Paste") {
                            text = UIPasteboard.general.string ?? ""
                        }
                        .disabled(!UIPasteboard.general.hasStrings)
                    }
                }
        }
        .onChange(of: scenePhase) { scenePhase in
            vm.objectWillChange.send()
        }
        .emailSheet(recipient: Constants.email, subject: "\(Constants.name) Feedback", isPresented: $showEmailSheet)
    }
}
