//
//  Helpers.swift
//  Food
//
//  Created by Jack Finnis on 12/05/2024.
//

import UIKit

struct Haptics {
    static func tap() {
#if os(iOS)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
#endif
    }
    
    static func success() {
#if os(iOS)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
#endif
    }
    
    static func error() {
#if os(iOS)
        UINotificationFeedbackGenerator().notificationOccurred(.error)
#endif
    }
}
