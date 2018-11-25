//
//  CBOR.swift
//  WebAuthnKit
//
//  Created by Lyo Kato on 2018/11/20.
//  Copyright © 2018 Lyo Kato. All rights reserved.
//

import Foundation

internal class CBORBits {
    public static let falseBits:           UInt8 = 0xf4
    public static let trueBits:            UInt8 = 0xf5
    public static let nullBits:            UInt8 = 0xf6
    public static let headerPart:          UInt8 = 0b11100000
    public static let valuePart:           UInt8 = 0b00011111
    public static let stringHeader:        UInt8 = 0b01100000
    public static let bytesHeader:         UInt8 = 0b01000000
    public static let negativeHeader:      UInt8 = 0b00100000
    public static let floatBits:           UInt8 = 0xfa
    public static let doubleBits:          UInt8 = 0xfb
    public static let arrayHeader:         UInt8 = 0x80
    public static let mapHeader:           UInt8 = 0xa0
    public static let indefiniteArrayBits: UInt8 = 0x9f
    public static let indefiniteMapBits:   UInt8 = 0xbf
    public static let breakBits:           UInt8 = 0xff
}

public enum CBORError : Error {
    case readError
}


internal class SimpleOrderedDictionary<T1: Hashable> {
    
    var list = [(T1, Any)]()
    
    public var count: Int {
        get {
            return self.list.count
        }
    }
    
    public var isEmpty: Bool {
        get {
            return self.list.isEmpty
        }
    }
    
    public static func fromDictionary(_ dict: Dictionary<T1, Any>) -> SimpleOrderedDictionary<T1> {
        let dic = SimpleOrderedDictionary<T1>()
        for (key, value) in dict {
           dic.add(key, value)
        }
        return dic
    }
    
    init() {
        
    }
    
    public func addString(_ k: T1, _ v: String) {
        self.add(k, v)
    }
    
    public func addBytes(_ k: T1, _ v: [UInt8]) {
        self.add(k, v)
    }
    
    public func addStringKeyMap(_ k: T1, _ v: SimpleOrderedDictionary<String>) {
        self.add(k, v)
    }
    
    public func addIntKeyMap(_ k: T1, _ v: SimpleOrderedDictionary<Int>) {
        self.add(k, v)
    }
    
    public func addArray(_ k: T1, _ v: [Any]) {
        self.add(k, v)
    }
    
    public func addInt(_ k: T1, _ v: Int64) {
        self.add(k, v)
    }
    
    private func add(_ k: T1, _ v: Any) {
       self.list.append((k, v))
    }
    
    public func get(_ k: T1) -> Optional<Any> {
        return self.list.first { $0.0 == k } 
    }
    
    public func entries() -> [(T1, Any)] {
        return self.list
    }
}

internal class CBORReader {

    private var bytes: [UInt8]
    private let size: Int
    private var cursor: Int = 0

    init(bytes: [UInt8]) {
        self.bytes = bytes
        self.size = bytes.count
    }

    public func getReadSize() -> Int {
        return self.cursor
    }

    public func getRestSize() -> Int {
        return (self.size - self.cursor)
    }

    private func nextByte() -> Optional<UInt8> {
        if self.cursor < self.size {
            return self.bytes[self.cursor]
        } else {
            WAKLogger.debug("<CBORReader> no enough size")
            return nil
        }
    }
    
    private func replaceNextByte(_ val: UInt8) {
        self.bytes[self.cursor] = val
    }

    private func readByte() -> Optional<UInt8> {
        if self.cursor < self.size {
            let b = self.bytes[self.cursor]
            self.cursor = self.cursor + 1
            return b
        } else {
            WAKLogger.debug("<CBORReader> no enough size")
            return nil
        }
    }

    private func readBytes(_ size: Int) -> Optional<[UInt8]> {
        if (self.cursor + size - 1) < self.size {
            let b = Array(self.bytes[self.cursor..<self.cursor+size])
            self.cursor = self.cursor + size
            return b
        } else {
            WAKLogger.debug("<CBORReader> no enough size")
            return nil
        }
    }

    public func readAny() -> Optional<Any> {

        guard let v1 = self.nextByte() else {
            return nil
        }

        if v1 >= 0 && v1 <= 27 {

            // positive number
            return self.readNumber()

        } else if v1 >= 32 && v1 <= 59 {

            // negative number
            return self.readNumber()
            
        } else if v1 == CBORBits.trueBits {
            
            return true
            
        } else if v1 == CBORBits.falseBits {
            
            return false
            
        } else if v1 == CBORBits.nullBits {
            
            return ()

        } else if v1 == CBORBits.floatBits {

            return self.readFloat()

        } else if v1 == CBORBits.doubleBits {

            return self.readDouble()

        } else if (v1 & CBORBits.headerPart) == CBORBits.stringHeader {

            return self.readString()

        } else if (v1 & CBORBits.headerPart) == CBORBits.bytesHeader {

            return self.readByteString()

        } else if  (v1 & CBORBits.headerPart) == CBORBits.arrayHeader {

            return self.readArray()

        } else if  (v1 & CBORBits.headerPart) == CBORBits.mapHeader {

            // currently, support nested-map only when its key is string
            return self.readStringKeyMap()

        } else {
            WAKLogger.debug("<CBORReader> unsupported value type")
            return nil
        }
    }

    public func readArray() -> Optional<[Any]> {
        
        guard let b1 = self.nextByte() else {
            return nil
        }
        
        if  (b1 & CBORBits.headerPart) != CBORBits.arrayHeader {
            WAKLogger.debug("<CBORReader> invalid 'array' format")
            return nil
        }
        
        self.replaceNextByte(b1 & CBORBits.valuePart)
        
        guard let count = self.readNumber() else {
            return nil
        }

        var results = [Any]()
        
        if count == 0 {
            return results
        }

        for _ in 0..<count {
            guard let result = self.readAny() else {
               return nil
            }
            results.append(result)
        }

        return results
    }

    // just for attestation
    public func readStringKeyMap() -> Optional<[String: Any]> {
        
        guard let b1 = self.nextByte() else {
            return nil
        }
        
        if  (b1 & CBORBits.headerPart) != CBORBits.mapHeader {
            WAKLogger.debug("<CBORReader> invalid 'map' format")
            return nil
        }
        
        self.replaceNextByte(b1 & CBORBits.valuePart)
        
        guard let count = self.readNumber() else {
            return nil
        }

        var results = [String: Any]()
        
        if count == 0 {
            return results
        }

        for _ in 0..<count {

            guard let key = self.readString() else {
                return nil
            }

            guard let result = self.readAny() else {
                return nil
            }

            results[key] = result
        }

        return results
    }

    // just for COSE key
    public func readIntKeyMap() -> Optional<[Int64: Any]> {
        
        guard let b1 = self.nextByte() else {
            return nil
        }
        
        if  (b1 & CBORBits.headerPart) != CBORBits.mapHeader {
            WAKLogger.debug("<CBORReader> invalid 'map' format")
            return nil
        }
        
        self.replaceNextByte(b1 & CBORBits.valuePart)
        
        guard let count = self.readNumber() else {
            return nil
        }

        var results = [Int64: Any]()
        
        if count == 0 {
            return results
        }

        for _ in 0..<count {

            guard let key: Int64 = self.readNumber() else {
                return nil
            }

            guard let result = self.readAny() else {
                return nil
            }

            results[key] = result
        }

        return results
    }

    public func readFloat() -> Optional<Float> {

        guard let b1 = self.readByte() else {
            return nil
        }

        if  b1 != CBORBits.floatBits {
            WAKLogger.debug("<CBORReader> invalid 'float' format")
            return nil
        }

        guard let b2 = self.readBytes(4) else {
            return nil
        }

        var f:Float = 0.0
        memccpy(&f, b2.reversed(), 4, 4)

        return f
    }

    public func readDouble() -> Optional<Double> {

        guard let b1 = self.readByte() else {
            return nil
        }

        if  b1 != CBORBits.doubleBits {
            WAKLogger.debug("<CBORReader> invalid 'double' format")
            return nil
        }

        guard let b2 = self.readBytes(8) else {
            return nil
        }

        var d:Double = 0.0
        memccpy(&d, b2.reversed(), 8, 8)

        return d
    }

    public func readByteString() -> Optional<[UInt8]> {

        guard let b1 = self.nextByte() else {
            return nil
        }

        if  (b1 & CBORBits.headerPart) != CBORBits.bytesHeader {
            WAKLogger.debug("<CBORReader> invalid 'bytes' format")
            return nil
        }
        
        self.replaceNextByte(b1 & CBORBits.valuePart)

        guard let len = self.readNumber() else {
            return nil
        }
        
        if len == 0 {
            return []
        }

        guard let b2 = self.readBytes(Int(len)) else {
            return nil
        }

        return b2

    }

    public func readString() -> Optional<String> {

        guard let b1 = self.nextByte() else {
            return nil
        }

        if  (b1 & CBORBits.headerPart) != CBORBits.stringHeader {
            WAKLogger.debug("<CBORReader> invalid 'string' format")
            return nil
        }
        
        self.replaceNextByte(b1 & CBORBits.valuePart)

        guard let len = self.readNumber() else {
            return nil
        }
        
        if len == 0 {
            return ""
        }

        guard let b2 = self.readBytes(Int(len)) else {
            return nil
        }

        if let str = String(bytes: b2, encoding: .utf8) {
            return str
        } else {
            WAKLogger.debug("<CBORReader> invalid utf-8 string")
            return nil
        }
    }
    
    public func readBool() -> Optional<Bool> {
        
        guard let b1 =  self.readByte() else {
            return nil
        }
       
        switch b1 {
        case CBORBits.falseBits:
            return false
        case CBORBits.trueBits:
            return true
        default:
            return nil
        }
    }
    
    // can't use Optional for result
    public func readNull() -> Optional<()> {
        
        guard let b1 =  self.readByte() else {
            return nil
        }
        
        if b1 == CBORBits.nullBits {
            return ()
        } else {
            return nil
        }
    }

    public func readNumber() -> Optional<Int64> {

        guard let b1 =  self.readByte() else {
            return nil
        }

        let value = Int64(b1 & CBORBits.valuePart)
        let isNegative = UInt8(b1 & CBORBits.headerPart) == CBORBits.negativeHeader
        
        var bytesToRead = 0
        switch (value) {
        case 0..<24:
            bytesToRead = 0
        case 24:
            bytesToRead = 1
        case 25:
            bytesToRead = 2
        case 26:
            bytesToRead = 4
        case 27:
            bytesToRead = 8
        default:
            WAKLogger.debug("<CBORReader> invalid 'number' format")
            return nil
        }

        if bytesToRead == 0 {
            if isNegative {
                return Int64((value + 1) * -1)
            } else {
                return value
            }
        }

        guard let b2 = self.readBytes(bytesToRead) else {
            return nil
        }

        var result:Int64 = 0

        switch bytesToRead {
        case 1:
            result = Int64(b2[0])
        case 2:
            result = Int64((UInt16(b2[0]) << 8) | UInt16(b2[1]))
        case 4:
            result = Int64((UInt32(b2[0]) << 24) | (UInt32(b2[1]) << 16) | (UInt32(b2[2]) << 8) | UInt32(b2[3]))
        case 8:
            let result1 = Int64((UInt64(b2[0]) << 56) | (UInt64(b2[1]) << 48) | (UInt64(b2[2]) << 40) | (UInt64(b2[3]) << 32))
            let result2 = Int64((UInt64(b2[4]) << 24) | (UInt64(b2[5]) << 16) | (UInt64(b2[6]) << 8) | UInt64(b2[7]))
            result = result1 | result2
        default:
            WAKLogger.debug("<CBORReader> invalid 'number' format")
            return nil
        }

        if isNegative {
           return (result + 1) * -1
        } else {
           return result
        }

    }
}

internal class CBORWriter {

    private var result: [UInt8]

    init() {
       self.result = [UInt8]()
    }

    // Any must be Int64 | String | Float | Double | Bool
    public func putArray(_ values: [Any]) -> CBORWriter {
        var bytes = composePositive(UInt64(values.count))
        bytes[0] = bytes[0] | CBORBits.arrayHeader
        self.result.append(contentsOf: bytes)
        values.forEach {
            if $0 is Int64 {
               _ = self.putNumber($0 as! Int64)
            } else if $0 is String {
               _ = self.putString($0 as! String)
            } else if $0 is [UInt8] {
                _ = self.putByteString($0 as! [UInt8])
            } else if $0 is Float {
               _ = self.putFloat($0 as! Float)
            } else if $0 is Double {
               _ = self.putDouble($0 as! Double)
            } else if $0 is Bool {
               _ = self.putBool($0 as! Bool)
            } else {
                fatalError("unsupported value type")
            }
        }
        return self
    }

    // for Attestation Object
    public func putStringKeyMap(_ values: SimpleOrderedDictionary<String>) -> CBORWriter {
        var bytes = composePositive(UInt64(values.count))
        bytes[0] = bytes[0] | CBORBits.mapHeader
        self.result.append(contentsOf: bytes)
        for (key, value) in values.entries() {
            _ = self.putString(key)
            if value is Int64 {
                _ = self.putNumber(value as! Int64)
            } else if value is String {
                _ = self.putString(value as! String)
            } else if value is [UInt8] {
                _ = self.putByteString(value as! [UInt8])
            } else if value is Float {
                _ = self.putFloat(value as! Float)
            } else if value is Double {
                _ = self.putDouble(value as! Double)
            } else if value is Bool {
                _ = self.putBool(value as! Bool)
            } else if value is SimpleOrderedDictionary<String> {
                _ = self.putStringKeyMap(value as! SimpleOrderedDictionary<String>)
            } else if value is [Any] {
                _ = self.putArray(value as! [Any])
            } else {
                fatalError("unsupported value type: \(value)")
            }
        }
        return self
    }

    // for COSE_Key format
    public func putIntKeyMap(_ values: SimpleOrderedDictionary<Int>) -> CBORWriter {
        var bytes = composePositive(UInt64(values.count))
        bytes[0] = bytes[0] | CBORBits.mapHeader
        self.result.append(contentsOf: bytes)
        for (key, value) in values.entries() {
            _ = self.putNumber(Int64(key))
            if value is Int64 {
                _ = self.putNumber(value as! Int64)
            } else if value is String {
                _ = self.putString(value as! String)
            } else if value is [UInt8] {
                _ = self.putByteString(value as! [UInt8])
            } else if value is Float {
                _ = self.putFloat(value as! Float)
            } else if value is Double {
                _ = self.putDouble(value as! Double)
            } else if value is Bool {
                _ = self.putBool(value as! Bool)
            } else {
                fatalError("unsupported value type \(value)")
            }
        }
        return self
    }

    public func startArray() -> CBORWriter {
        self.result.append(CBORBits.indefiniteArrayBits)
        return self
    }

    public func startMap() -> CBORWriter {
        self.result.append(CBORBits.indefiniteMapBits)
        return self
    }

    public func end() -> CBORWriter{
        self.result.append(CBORBits.breakBits)
        return self
    }

    public func putString(_ value: String) -> CBORWriter {
        let data: [UInt8] = Array(value.utf8)
        var header = self.composePositive(UInt64(data.count))
        header[0] = header[0] | CBORBits.stringHeader
        self.result.append(contentsOf: header)
        if data.count > 0 {
            self.result.append(contentsOf: data)
        }
        return self
    }

    public func putByteString(_ value: [UInt8]) -> CBORWriter {
        var header = self.composePositive(UInt64(value.count))
        header[0] = header[0] | CBORBits.bytesHeader
        self.result.append(contentsOf: header)
        if value.count > 0 {
            self.result.append(contentsOf: value)
        }
        return self
    }

    public func putFloat(_ value: Float) -> CBORWriter {
        var fv: Float = value
        let bytes = [UInt8](Data(bytes: &fv, count: MemoryLayout.size(ofValue: fv)))
        self.result.append(CBORBits.floatBits)
        self.result.append(contentsOf: bytes.reversed())
        return self
    }

    public func putDouble(_ value: Double) -> CBORWriter {
        var dv: Double = value
        let bytes = [UInt8](Data(bytes: &dv, count: MemoryLayout.size(ofValue: dv)))
        self.result.append(CBORBits.doubleBits)
        self.result.append(contentsOf: bytes.reversed())
        return self
    }

    public func putBool(_ value: Bool) -> CBORWriter {
        if value {
            result.append(CBORBits.trueBits)
        } else {
            result.append(CBORBits.falseBits)
        }
        return self
    }

    public func putNull() -> CBORWriter {
        result.append(CBORBits.nullBits)
        return self
    }

    public func putNumber(_ value: Int64) -> CBORWriter {
        if value >= 0 {
            result.append(contentsOf: self.composePositive(UInt64(value)))
        } else {
            result.append(contentsOf: self.composeNegative(value))
        }
        return self
    }

    public func getResult() -> [UInt8] {
        return self.result
    }

    private func composeNegative(_ value: Int64) -> [UInt8] {
        assert(value < 0)
        let v = value == Int64.min ? Int64.max : (-1 - value)
        var data = composePositive(UInt64(v))
        data[0] = data[0] | CBORBits.negativeHeader
        return data
    }

    private func composePositive(_ value: UInt64) -> [UInt8] {
        if value >= 0 && value <= 23 {
            return [UInt8(value)]
        } else if value <= UInt8.max {
            return [
                UInt8(24),
                UInt8(value)
            ]
        } else if value <= UInt16.max {
            return [
                UInt8(25),
                UInt8((value & 0xff00) >> 8),
                UInt8(value & 0x00ff)
            ]
        } else if value <= UInt32.max {
            return [
                UInt8(26),
                UInt8((value & 0xff000000) >> 24),
                UInt8((value & 0x00ff0000) >> 16),
                UInt8((value & 0x0000ff00) >> 8),
                UInt8(value & 0x000000ff)
            ]
        } else if value <= UInt64.max {
            return [
                UInt8(27),
                UInt8((value & 0xff00000000000000) >> 56),
                UInt8((value & 0x00ff000000000000) >> 48),
                UInt8((value & 0x0000ff0000000000) >> 40),
                UInt8((value & 0x000000ff00000000) >> 32),
                UInt8((value & 0x00000000ff000000) >> 24),
                UInt8((value & 0x0000000000ff0000) >> 16),
                UInt8((value & 0x000000000000ff00) >> 8),
                UInt8(value & 0x00000000000000ff),
            ]
        } else {
            fatalError("too big number")
        }
    }

}
