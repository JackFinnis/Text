//
//  ContentView.swift
//  Text
//
//  Created by Jack Finnis on 12/02/2023.
//

import SwiftUI

struct RootView: View {
    @StateObject var vm = ViewModel()
    @State var showUndoAlert = false
    
    var body: some View {
        NavigationView {
            TextView(vm: vm)
                .overlay(alignment: .topLeading) {
                    if vm.text.isEmpty {
                        Text("Enter text here")
                            .padding(.top, 10)
                            .padding(.leading, 20)
                            .foregroundColor(Color(.placeholderText))
                    }
                }
                .overlay(alignment: .bottom) {
                    if !vm.editing {
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
                            Button("Clear") {
                                vm.text = ""
                                vm.textView?.becomeFirstResponder()
                            }
                        }
                    }
                    ToolbarItem(placement: .primaryAction) {
                        if vm.editing {
                            Button("Done") {
                                vm.textView?.resignFirstResponder()
                            }
                            .font(.body.bold())
                        } else if UIPasteboard.general.hasStrings {
                            Button("Paste") {
                                vm.text = UIPasteboard.general.string ?? ""
                                vm.addAttributes()
                            }
                        }
                    }
                }
        }
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
    }
}
