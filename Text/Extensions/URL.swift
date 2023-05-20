//
//  URL.swift
//  Text
//
//  Created by Jack Finnis on 20/05/2023.
//

import Foundation

extension URL {
    var isWebsite: Bool { scheme?.starts(with: "http") ?? false }
    var isMailto: Bool { scheme == "mailto" }
    var email: String? {
        guard isMailto else { return nil }
        return URLComponents(string: absoluteString)?.path
    }
}
