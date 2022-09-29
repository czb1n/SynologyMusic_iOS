//
//  DictionaryExtension.swift
//  SynologyMusic
//
//  Created by czb1n on 2022/9/29.
//

import Foundation

extension Data {
    func toDictionary() -> Dictionary<String, AnyObject> {
        guard let json = try? JSONSerialization.jsonObject(with: self, options: .mutableContainers) as? Dictionary<String, AnyObject> else {
            return Dictionary.init()
        }
        return json
    }
}

extension Data? {
    func toDictionary() -> Dictionary<String, AnyObject> {
        guard let data = self, let json = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? Dictionary<String, AnyObject> else {
            return Dictionary.init()
        }
        return json
    }
}

extension Dictionary<String, AnyObject> {
    func str(_ key: String) -> String {
        return self[key] as? String ?? ""
    }
    
    func long(_ key: String) -> Int64 {
        return self[key] as? Int64 ?? 0
    }
    
    func bool(_ key: String) -> Bool {
        return self[key] as? Bool ?? false
    }
    
    func dic(_ key: String) -> Dictionary<String, AnyObject> {
        return self[key] as? Dictionary<String, AnyObject> ?? Dictionary.init()
    }
    
    func dicArray(_ key: String) -> Array<Dictionary<String, AnyObject>> {
        return self[key] as? Array<Dictionary<String, AnyObject>> ?? Array.init()
    }
}
