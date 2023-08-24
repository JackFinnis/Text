//
//  Defaults.swift
//  Change
//
//  Created by Jack Finnis on 07/11/2022.
//

import Foundation

protocol OptionalProtocol {
    var isNil: Bool { get }
}
extension Optional: OptionalProtocol {
    var isNil: Bool { self == nil }
}

protocol KeyValueStore {
    func object(forKey key: String) -> Any?
    func set(_ object: Any?, forKey key: String)
    func removeObject(forKey key: String)
}
extension UserDefaults: KeyValueStore {}
extension NSUbiquitousKeyValueStore: KeyValueStore {}

@propertyWrapper
struct Storage<T> {
    let key: String
    let defaultValue: T
    let store: KeyValueStore
    
    init(wrappedValue defaultValue: T, _ key: String, iCloudSync: Bool = false) {
        self.key = key
        self.defaultValue = defaultValue
        self.store = iCloudSync ? NSUbiquitousKeyValueStore.default : UserDefaults.standard
    }
    
    var wrappedValue: T {
        get {
            store.object(forKey: key) as? T ?? defaultValue
        }
        set {
            if let optionalValue = newValue as? OptionalProtocol, optionalValue.isNil {
                store.removeObject(forKey: key)
            } else {
                store.set(newValue, forKey: key)
            }
        }
    }
}
