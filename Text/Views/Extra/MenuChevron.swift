//
//  MenuChevron.swift
//  News
//
//  Created by Jack Finnis on 13/01/2023.
//

import SwiftUI

struct MenuChevron: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Image(systemName: "chevron.down.circle.fill")
            .font(.footnote.weight(.heavy))
            .foregroundStyle(.secondary, Color(colorScheme == .light ? .tertiarySystemFill : .systemFill))
            .foregroundColor(.primary)
            .imageScale(.large)
    }
}
