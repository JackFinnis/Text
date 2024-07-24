//
//  Constants.swift
//  Text
//
//  Created by Jack Finnis on 16/05/2023.
//

import Foundation

struct Constants {
    static let name = "Notepad"
    #if os(iOS)
    static let verticalPadding = 8.0
    static let horizontalPadding = 16.0
    #elseif os(visionOS)
    static let verticalPadding = 0.0
    static let horizontalPadding = 25.0
    #endif
    static let welcomeMessage = """
Jot down ideas
Save important links
Easily create calendar events
Take notes in a meeting or lecture
Check the character-count of a Tweet
Look up a word in the dictionary
Translate a scentence to any language
Scan text from a document
Convert text to speech
"""
}
