//
//  EventView.swift
//  Text
//
//  Created by Jack Finnis on 12/02/2023.
//

import SwiftUI
import EventKitUI

struct EventView: UIViewControllerRepresentable {
    @Environment(\.dismiss) var dismiss
    
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

    func updateUIViewController(_ uiViewController: EKEventEditViewController, context: Context) {}

    class Coordinator: NSObject, EKEventEditViewDelegate {
        let parent: EventView

        init(_ parent: EventView) {
            self.parent = parent
        }

        func eventEditViewController(_ controller: EKEventEditViewController, didCompleteWith action: EKEventEditViewAction) {
            try? EKEventStore.shared.save(parent.event, span: .thisEvent)
            parent.dismiss()
        }
    }
}
