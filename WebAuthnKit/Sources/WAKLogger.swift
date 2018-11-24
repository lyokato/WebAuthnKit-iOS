//
//  WAKLogger.swift
//  WebAuthnKit
//
//  Created by Lyo Kato on 2018/11/20.
//  Copyright © 2018 Lyo Kato. All rights reserved.
//

import Foundation

public class WAKLogger {

    public static var available: Bool = false

    public static func debug(_ msg: String) {
        if available {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyyMMddHHmmss"
            let dateString = formatter.string(from: Date())
            print("\(dateString) [WebAuthnKit]" + msg)
        }
    }
}
