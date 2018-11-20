//
//  CBORTests.swift
//  WebAuthnKitTests
//
//  Created by Lyo Kato on 2018/11/20.
//  Copyright © 2018 Lyo Kato. All rights reserved.
//

import XCTest

@testable import WebAuthnKit
@testable import CryptoSwift

class CBORTests: XCTestCase {

    override func setUp() {
        WAKLogger.available = true
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }
    
    func assertNumber(_ num: Int64, _ hex: String) {
        print("assertNumber:\(num):\(hex)")
        XCTAssertEqual(CBORWriter().putNumber(num).getResult().toHexString(), hex)
        
        let reader = CBORReader(bytes: Data(hex: hex).bytes)
        XCTAssertEqual(reader.readNumber()!, num)
    }
    
    func assertFloat(_ num: Float, _ hex: String) {
        XCTAssertEqual(CBORWriter().putFloat(num).getResult().toHexString(), hex)
        
        let reader = CBORReader(bytes: Data(hex: hex).bytes)
        XCTAssertEqual(reader.readFloat()!, num)
    }
    
    func assertDouble(_ num: Double, _ hex: String) {
        XCTAssertEqual(CBORWriter().putDouble(num).getResult().toHexString(), hex)
        
        let reader = CBORReader(bytes: Data(hex: hex).bytes)
        XCTAssertEqual(reader.readDouble()!, num)
    }
    
    func assertString(_ val: String, _ hex: String) {
        print("assertString:\(val):\(hex)")
        XCTAssertEqual(CBORWriter().putString(val).getResult().toHexString(), hex)
        
        let reader = CBORReader(bytes: Data(hex: hex).bytes)
        XCTAssertEqual(reader.readString()!, val)
    }
    
    func assertBool(_ val: Bool, _ hex: String) {
        XCTAssertEqual(CBORWriter().putBool(val).getResult().toHexString(), hex)
        
        let reader = CBORReader(bytes: Data(hex: hex).bytes)
        XCTAssertEqual(reader.readBool()!, val)
    }
    
    func assertByteString(_ val: [UInt8], _ hex: String) {
        XCTAssertEqual(CBORWriter().putByteString(val).getResult().toHexString(), hex)
        let reader = CBORReader(bytes: Data(hex: hex).bytes)
        XCTAssertEqual(reader.readByteString()!, val)
    }
    
    func testInteger() {
        // https://tools.ietf.org/html/rfc7049#appendix-A
        [
            (0, "00"),
            (1, "01"),
            (10, "0a"),
            (23, "17"),
            (24, "1818"),
            (25, "1819"),
            (100, "1864"),
            (1000, "1903e8"),
            (1000000, "1a000f4240"),
            (1000000000000, "1b000000e8d4a51000"),
             //(18446744073709551615, "1bffffffffffffffff"),
             //(18446744073709551616, "c249010000000000000000"),
             //( -18446744073709551616, "3bffffffffffffffff"),
             //(-18446744073709551617 , "c349010000000000000000")
            (-1, "20"),
            (-10, "29"),
            (-100, "3863"),
            (-1000, "3903e7")
        ].forEach {
           assertNumber($0.0, $0.1)
        }
    }
    
    func testFloat() {
        [
            // TODO support half precision float?
            //(0.0, "f90000"),
            //(-0.0, "f98000"),
            //(1.0, "f93c00"),
            //(1.1, "fb3ff199999999999a"),
            //(1.5, "f93e00"),
            //(65504.0, "f97bff"),
            (100000.0, "fa47c35000"),
            (3.4028234663852886e+38, "fa7f7fffff")
            ].forEach {
                assertFloat($0.0, $0.1)
        }
    }
    
    func testDouble() {
        [
            (1.1, "fb3ff199999999999a"),
            (1.0e+300, "fb7e37e43c8800759c"),
            (-4.1, "fbc010666666666666")
            ].forEach {
                assertDouble($0.0, $0.1)
        }
    }
    
    func testString() {
        [
            ("", "60"),
            ("a", "6161"),
            ("IETF", "6449455446"),
            ("\"\\", "62225c"),
            ("\u{00fc}", "62c3bc"),
            ("\u{6c34}", "63e6b0b4"),
            ("\u{00fc}", "62c3bc")
            //("\u{d800}\u{dd51}", "64f0908591")
            ].forEach {
                assertString($0.0, $0.1)
        }
    }
    
    func testByteString() {
        [
            ([], "40"),
            ([0x01,0x02,0x03,0x04], "4401020304"),
            ].forEach {
                assertByteString($0.0, $0.1)
        }
    }
    
    func testBool() {
        [
            (false, "f4"),
            (true, "f5")
            ].forEach {
                assertBool($0.0, $0.1)
        }
    }
    
    func testNull() {
        XCTAssertEqual(CBORWriter().putNull().getResult().toHexString(), "f6")
    }
    
    func testArray() {
        let val1: [Int64] = []
        XCTAssertEqual(CBORWriter().putArray(val1).getResult().toHexString(), "80")
        
        let result1 = CBORReader(bytes: Data(hex: "80").bytes).readArray()
        XCTAssertEqual(result1!.count, 0)
        
        let val2: [Int64] = [1, 2, 3]
        XCTAssertEqual(CBORWriter().putArray(val2).getResult().toHexString(), "83010203")
        let result2 = CBORReader(bytes: Data(hex: "83010203").bytes).readArray()
        XCTAssertEqual(result2!.count, 3)
        XCTAssertEqual(result2![0] as! Int64, 1)
        XCTAssertEqual(result2![1] as! Int64, 2)
        XCTAssertEqual(result2![2] as! Int64, 3)
        
        
        let val3: [Int64] = [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25]
        XCTAssertEqual(CBORWriter().putArray(val3).getResult().toHexString(), "98190102030405060708090a0b0c0d0e0f101112131415161718181819")
        
        let result3 = CBORReader(bytes: Data(hex: "98190102030405060708090a0b0c0d0e0f101112131415161718181819").bytes).readArray()
        XCTAssertEqual(result3!.count, 25)
        XCTAssertEqual(result3![0] as! Int64, 1)
        XCTAssertEqual(result3![24] as! Int64, 25)
        
        /* TODO support nested array
        let val4: [Any] = [
            Int64(1), [Int64(2), Int64(3)], [Int64(4), Int64(5)]
        ]
        XCTAssertEqual(CBORWriter().putArray(val4).getResult().toHexString(), "8301820203820405")
         */
    }
    
    func testMap() {
        
        let val1 = SimpleOrderedDictionary<String, Any>()
        XCTAssertEqual(CBORWriter().putStringKeyMap(val1).getResult().toHexString(), "a0")
        
        let result1 = CBORReader(bytes: Data(hex: "a0").bytes).readStringKeyMap()
        XCTAssertEqual(result1!.count, 0)
        
        let val2 = SimpleOrderedDictionary<String, Any>()
        val2.add("a", Int64(1))
        let val3: [Any] = [Int64(2), Int64(3)]
        val2.add("b", val3)
        XCTAssertEqual(CBORWriter().putStringKeyMap(val2).getResult().toHexString(), "a26161016162820203")
        
        let result2 = CBORReader(bytes: Data(hex: "a26161016162820203").bytes).readStringKeyMap()
        XCTAssertEqual(result2!.count, 2)
        XCTAssertEqual(result2!["a"] as! Int64, Int64(1))
        
        let val4 = SimpleOrderedDictionary<Int, Any>()
        val4.add(1, Int64(2))
        val4.add(3, Int64(4))
        XCTAssertEqual(CBORWriter().putIntKeyMap(val4).getResult().toHexString(), "a201020304")
        let result3 = CBORReader(bytes: Data(hex: "a201020304").bytes).readIntKeyMap()
        XCTAssertEqual(result3!.count, 2)
        XCTAssertEqual(result3![1] as! Int64, Int64(2))
        XCTAssertEqual(result3![3] as! Int64, Int64(4))
        
    }

}
