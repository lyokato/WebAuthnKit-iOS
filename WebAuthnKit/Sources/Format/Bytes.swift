//
//  Bytes.swift
//  WebAuthnKit
//
//  Created by Lyo Kato on 2018/11/20.
//  Copyright © 2018 Lyo Kato. All rights reserved.
//

import Foundation

public class Bytes {
    
    public static func fromHex(_ value: String) -> [UInt8] {
        return Data(hex: value).bytes
    }
    
    public static func fromString(_ value: String) -> [UInt8] {
        return value.bytes // This is CryptoSwift method
    }

    public static func fromUInt64(_ value: UInt64) -> [UInt8] {
       return [
            UInt8((value & 0xff00000000000000) >> 56),
            UInt8((value & 0x00ff000000000000) >> 48),
            UInt8((value & 0x0000ff0000000000) >> 40),
            UInt8((value & 0x000000ff00000000) >> 32),
            UInt8((value & 0x00000000ff000000) >> 24),
            UInt8((value & 0x0000000000ff0000) >> 16),
            UInt8((value & 0x000000000000ff00) >> 8),
            UInt8(value & 0x00000000000000ff),
        ]
    }

    public static func toUInt64(_ bytes: [UInt8]) -> UInt64 {
        var b = bytes
        while b.count < 8 {
            b.insert(UInt8(0x00), at: 0)
        }
        while b.count > 8 {
           b.removeFirst()
        }
        let A = (UInt64(b[0]) << 56)
        let B = (UInt64(b[1]) << 48)
        let C = (UInt64(b[2]) << 40)
        let D = (UInt64(b[3]) << 32)
        let result1 = UInt64( A | B | C | D )
        
        let result2 = UInt64((UInt64(b[4]) << 24) | (UInt64(b[5]) << 16) | (UInt64(b[6]) << 8) | UInt64(b[7]))
        return result1 | result2
    }

    public static func fromUInt32(_ value: UInt32) -> [UInt8] {
        return [
            UInt8((value & 0xff000000) >> 24),
            UInt8((value & 0x00ff0000) >> 16),
            UInt8((value & 0x0000ff00) >> 8),
            UInt8(value & 0x000000ff),
        ]
    }

    public static func toUInt32(_ bytes: [UInt8]) -> UInt32 {
        var b = bytes
        while b.count < 4 {
            b.insert(UInt8(0x00), at: 0)
        }
        while b.count > 4 {
            b.removeFirst()
        }
        return UInt32((UInt32(b[0]) << 24) | (UInt32(b[1]) << 16) | (UInt32(b[2]) << 8) | UInt32(b[3]))
    }

    public static func fromUInt16(_ value: UInt16) -> [UInt8] {
        return [
            UInt8((value & 0xff00) >> 8),
            UInt8(value & 0x00ff),
        ]
    }

    public static func toUInt16(_ bytes: [UInt8]) -> UInt16 {
        var b = bytes
        while b.count < 2 {
            b.insert(UInt8(0x00), at: 0)
        }
        while b.count > 2 {
            b.removeFirst()
        }
        return UInt16(UInt16(b[1]) << 8 | UInt16(b[0]))
    }
}
