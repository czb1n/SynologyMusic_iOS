//
//  Debug.swift
//  SynologyMusic
//
//  Created by czb1n on 2022/9/29.
//

import Foundation

class Debug: NSObject {
    static func log<T>(_ message: T, file: String = #file, functionName: String = #function, lineNumber: Int = #line) {
        #if DEBUG
        let filename = (file as NSString).lastPathComponent
        print("\(filename):\(lineNumber) - \(message)")
        #endif
    }
}
