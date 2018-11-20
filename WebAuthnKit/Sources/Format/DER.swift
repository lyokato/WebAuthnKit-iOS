//
//  DER.swift
//  WebAuthnKit
//
//  Created by Lyo Kato on 2018/11/20.
//  Copyright © 2018 Lyo Kato. All rights reserved.
//

import Foundation

internal enum DERClass {
    case universal
    case application
    case contextSpecific
    case private_
}

internal enum DERType {
    case primitive
    case constructed
}

internal enum DERTag {
    case end
    case boolean
    case integer
    case bitString
    case octetString
    case null
    case objectIdentifier
    case objectDescriptor
    case sequence
    case unsupported
}

internal class DERReader {

    private let bytes: [UInt8]
    private let size: Int
    private var cursor: Int = 0

    init(bytes: [UInt8]) {
        self.bytes = bytes
        self.size = bytes.count
    }

    private func nextByte() -> Optional<UInt8> {
        if self.cursor < self.size {
            return self.bytes[self.cursor]
        } else {
            WAKLogger.debug("<DERReader> no enough size")
            return nil
        }
    }

    private func readByte() -> Optional<UInt8> {
        if self.cursor < self.size {
            let b = self.bytes[self.cursor]
            self.cursor = self.cursor + 1
            return b
        } else {
            WAKLogger.debug("<DERReader> no enough size")
            return nil
        }
    }

    private func readBytes(_ size: Int) -> Optional<[UInt8]> {
        if (self.cursor + size - 1) < self.size {
            let b = Array(self.bytes[self.cursor..<self.cursor+size])
            self.cursor = self.cursor + size
            return b
        } else {
            WAKLogger.debug("<DERReader> no enough size")
            return nil
        }
    }

    private func getClass(_ b: UInt8) -> DERClass {
        switch b & 0b11000000 {
        case 0b00000000:
            return .universal
        case 0b01000000:
            return .application
        case 0b10000000:
            return .contextSpecific
        case 0b11000000:
            return .private_
        default:
            return .universal
        }
    }

    private func getType(_ b: UInt8) -> DERType {
        switch b & 0b00100000 {
        case 0b00010000:
            return .constructed
        case 0b00000000:
            return .primitive
        default:
            return .primitive
        }
    }

    private func getTag(_ b: UInt8) -> DERTag {
        switch b & 0b00011111 {
        case 0:
            return .end
        case 1:
            return .boolean
        case 2:
            return .integer
        case 3:
            return .bitString
        case 4:
            return .octetString
        case 5:
            return .null
        case 6:
            return .objectIdentifier
        case 7:
            return .objectDescriptor
        case 16:
            return .sequence
        default:
            return .unsupported
        }
    }

    private func readLength() -> Optional<Int> {

        guard let l = self.readByte() else {
            return nil
        }

        if l == 0x80 {
            WAKLogger.debug("<DER> variable length not supported")
            return nil
        } else if l > 0x80 {
            let bytesToRead = Int(l & 0b01111111)
            guard let lenBytes = self.readBytes(bytesToRead) else {
               return nil
            }
            switch lenBytes.count {
            case 1:
                return Int(lenBytes[0])
            case 2:
                return Int(Bytes.toUInt16(lenBytes))
            default:
                // TODO how about 3?
                WAKLogger.debug("<DER> unsupported length")
                return nil
            }
        } else {
            return Int(l)
        }

    }

    public func readNext() -> Optional<(DERTag, [UInt8])> {

        guard let identifier = self.readByte() else {
           return nil
        }

        // let klass = self.getClass(identifier)
        // let type = self.getType(identifier)
        let tag = self.getTag(identifier)

        switch tag {
        case .null:
            guard let _ = self.readByte() else {
                return nil
            }
            return (.null, [UInt8(0x00)] /* dummy */ )
        case .sequence:
            guard let len = self.readLength() else {
                return nil
            }
            if len == 0 {
                return nil
            }
            return (.sequence, [UInt8(0x00)] /* dummy */ )
        default:
            guard let len = self.readLength() else {
                return nil
            }
            if len == 0 {
                return nil
            }

            guard let contents = self.readBytes(len) else {
                return nil
            }

            return (tag, contents)

        }

    }

}
