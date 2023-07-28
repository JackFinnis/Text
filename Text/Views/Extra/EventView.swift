//
//  EventView.swift
//  Text
//
//  Created by Jack Finnis on 12/02/2023.
//

import SwiftUI
import EventKitUI

struct EventView: UIViewControllerRepresentable {
    @EnvironmentObject var vm: ViewModel
    
    let event: EKEvent
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> EKEventEditViewController {
        let vc = EKEventEditViewController()
        vc.event = event
        vc.eventStore = .shared
        vc.editViewDelegate = context.coordinator

        return vc
    }
    
    func updateUIViewController(_ vc: EKEventEditViewController, context: Context) {}
    
    class Coordinator: NSObject, EKEventEditViewDelegate {
        let parent: EventView

        init(_ parent: EventView) {
            self.parent = parent
        }
        
        @MainActor
        func eventEditViewController(_ vc: EKEventEditViewController, didCompleteWith action: EKEventEditViewAction) {
            if action == .saved {
                do {
                    try EKEventStore.shared.save(parent.event, span: .thisEvent)
                } catch {
                    parent.vm.error = .addEvent
                }
            }
            vc.dismiss(animated: true)
        }
    }
}
