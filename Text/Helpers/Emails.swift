//
//  Emails.swift
//  News
//
//  Created by Jack Finnis on 21/04/2023.
//

import SwiftUI

struct Emails {
    static func mailtoUrl(subject: String) -> URL? {
        guard let encodedSubject = subject.urlEncoding else { return nil }
        return URL(string: "mailto:\(Constants.email)?subject=\(encodedSubject)")
    }
}
