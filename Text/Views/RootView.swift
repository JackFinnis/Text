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
                .overlay(alignment: .bottom) {
                    if vm.text.isNotEmpty && !vm.editing {
                        Text(vm.words.formatted(singular: "word") + " • " + vm.text.count.formatted(singular: "char"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding()
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        if vm.text.isNotEmpty {
                            Button("Copy") {
                                UIPasteboard.general.string = vm.text
                            }
                        }
                    }
                    ToolbarItem(placement: .principal) {
                        Menu {
                            Button {
                                vm.shareItems = [Constants.appUrl]
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
                                    showEmailSheet.toggle()
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
                                MenuChevron()
                            }
                            .foregroundColor(.primary)
                        }
                    }
                    ToolbarItem(placement: .primaryAction) {
                        if UIPasteboard.general.hasStrings {
                            Button("Paste") {
                                vm.text = UIPasteboard.general.string ?? ""
                                vm.addAttributes()
                            }
                        }
                    }
                }
        }
        .shareSheet(items: vm.shareItems, isPresented: $vm.showShareSheet)
        .emailSheet(recipient: Constants.email, subject: "\(Constants.name) Feedback", isPresented: $showEmailSheet)
        .sheet(item: $vm.event) { event in
            EventView(event: event)
        }
        .onShake {
            if vm.previousTexts.isNotEmpty {
                showUndoAlert = true
                Haptics.success()
            }
        }
        .alert("Undo Edit", isPresented: $showUndoAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Undo") {
                vm.undoEdit()
            }
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                vm.objectWillChange.send()
            }
        }
        .environmentObject(vm)
        .navigationViewStyle(.stack)
    }
}
