//
//  UUID.swift
//  WebAuthnKit
//
//  Created by Lyo Kato on 2018/11/20.
//  Copyright © 2018 Lyo Kato. All rights reserved.
//

import Foundation

internal class UUIDHelper {

    public static let zero = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!

    public static let zeroBytes: [UInt8] = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]

    public static func toBytes(_ uuid: UUID) -> [UInt8] {
        return [
            uuid.uuid.0,
            uuid.uuid.1,
            uuid.uuid.2,
            uuid.uuid.3,
            uuid.uuid.4,
            uuid.uuid.5,
            uuid.uuid.6,
            uuid.uuid.7,
            uuid.uuid.8,
            uuid.uuid.9,
            uuid.uuid.10,
            uuid.uuid.11,
            uuid.uuid.12,
            uuid.uuid.13,
            uuid.uuid.14,
            uuid.uuid.15
        ]

    }
}
