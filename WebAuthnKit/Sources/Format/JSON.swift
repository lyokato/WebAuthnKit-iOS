//
//  JSON.swift
//  WebAuthnKit
//
//  Created by Lyo Kato on 2018/11/20.
//  Copyright © 2018 Lyo Kato. All rights reserved.
//

import Foundation

public class JSONHelper<T: Codable> {

    public static func decode(_ json: String) -> Optional<T> {
        if let data: Data = json.data(using: .utf8) {
            do {
                return try JSONDecoder().decode(T.self, from: data)
            } catch let error {
                WAKLogger.debug("<JSONHelper> failed to decode: \(error)")
                return nil
            }
        } else {
            WAKLogger.debug("<JSONHelper> invalid UTF-8 string")
            return nil
        }
    }

    public static func encode(_ obj: T) -> Optional<String> {
        do {
            let data = try JSONEncoder().encode(obj)
            if let str = String(data: data, encoding: .utf8) {
                return str
            } else {
                WAKLogger.debug("<JSONHelper> invalid UTF-8 string")
                return nil
            }
        } catch let error {
            WAKLogger.debug("<JSONHelper> failed to encode: \(error)")
            return nil
        }
    }
}
