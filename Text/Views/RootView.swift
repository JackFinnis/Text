//
//  ContentView.swift
//  Text
//
//  Created by Jack Finnis on 12/02/2023.
//

import SwiftUI
import MessageUI

struct RootView: View {
    @Environment(\.scenePhase) var scenePhase
    @StateObject var vm = ViewModel()
    @State var showUndoAlert = false
    @State var showEmailSheet = false
    @State var showSharePopover = false
    
    var body: some View {
        NavigationView {
            TextView()
                .overlay(alignment: .topLeading) {
                    if vm.text.isEmpty {
                        Text("Enter text here")
                            .padding(.top, 10)
                            .padding(.leading, 20)
                            .foregroundColor(Color(.placeholderText))
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Copy") {
                            UIPasteboard.general.string = vm.text
                            Haptics.success()
                        }
                        .disabled(vm.text.isEmpty)
                    }
                    ToolbarItem(placement: .principal) {
                        Menu {
                            Button {
                                showSharePopover = true
                            } label: {
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
                                    showEmailSheet = true
                                } label: {
                                    Label("Send us Feedback", systemImage: "envelope")
                                }
                            } else if let url = Emails.mailtoUrl(subject: "\(Constants.name) Feedback"), UIApplication.shared.canOpenURL(url) {
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
                        .sharePopover(items: [Constants.appUrl], showsSharedAlert: true, isPresented: $showSharePopover)
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Button("Paste") {
                            vm.text = UIPasteboard.general.string ?? ""
                            Haptics.success()
                            if !vm.editing {
                                vm.addAttributes()
                            }
                        }
                        .disabled(!UIPasteboard.general.hasStrings)
                    }
                    ToolbarItem(placement: .status) {
                        Text(vm.words.formatted(singular: "word") + " • " + vm.text.count.formatted(singular: "char"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
        }
        .emailSheet(recipient: Constants.email, subject: "\(Constants.name) Feedback", isPresented: $showEmailSheet)
        .sheet(item: $vm.event) { event in
            EventView(event: event)
        }
        .sheet(isPresented: $vm.showContactView) {
            ContactView()
        }
        .onShake {
            if vm.previousTexts.isNotEmpty {
                showUndoAlert = true
                Haptics.success()
            }
        }
        .background {
            Text("")
                .alert("Undo Edit", isPresented: $showUndoAlert) {
                    Button("Cancel", role: .cancel) {}
                    Button("Undo") {
                        vm.undoEdit()
                    }
                }
            if let error = vm.error {
                Text("")
                    .alert(error.title, isPresented: .constant(true)) {
                        Button("OK", role: .cancel) {}
                        if error.showsOpenSettingsButton {
                            Button("Open Settings", role: .cancel) {
                                vm.openSettings()
                            }
                        }
                    } message: {
                        Text(error.description)
                    }
            }
        }
        .navigationViewStyle(.stack)
        .environmentObject(vm)
    }
}
