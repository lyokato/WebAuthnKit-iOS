//
//  COSETests.swift
//  WebAuthnKitTests
//
//  Created by Lyo Kato on 2018/11/20.
//  Copyright © 2018 Lyo Kato. All rights reserved.
//

import XCTest

@testable import WebAuthnKit
@testable import CryptoSwift

class COSETests: XCTestCase {

    override func setUp() {
        WAKLogger.available = true
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }
    
    func testRsaCoseKey() {
        
        let modulus = """
00:ac:50:a7:c4:b6:4e:32:96:5c:a4:2c:d0:88:62:
9e:87:3a:c0:b4:6a:e1:27:12:b2:66:50:92:4b:94:
0a:3f:5d:97:45:89:59:c4:01:4b:d7:bb:4a:dd:8d:
d8:71:6a:b1:d4:83:28:8f:58:74:23:d7:76:af:c5:
4a:82:42:d1:48:fd:40:27:57:9b:d8:6e:03:da:06:
a8:a1:71:ca:26:c7:c9:2d:08:6b:4e:97:65:90:b3:
57:bd:89:86:3c:59:d6:45:1e:a1:1a:67:e2:c0:2e:
7b:ec:78:c5:e7:e7:d1:d7:51:b6:71:e4:2c:41:e8:
24:ab:18:dc:11:a2:6e:d6:9c:55:c2:e8:39:c1:38:
74:ff:66:e6:b0:f1:52:20:c1:87:ed:2b:ff:40:01:
84:35:fd:95:76:aa:f6:3f:5f:ea:68:92:8b:93:e9:
52:60:ee:3c:39:c9:a0:5a:77:62:80:c6:61:d2:a9:
cc:45:38:a5:16:96:51:88:71:a4:44:b7:07:08:5c:
6d:d9:b3:00:7e:c7:6b:8c:ff:e5:76:74:12:43:bb:
00:29:c2:05:59:0a:e0:63:3a:4a:64:86:3a:fb:56:
08:c0:e7:87:6a:51:68:0f:e7:11:4c:44:df:be:6c:
45:2a:56:d8:92:10:2f:85:b9:97:58:c0:0b:7b:fa:
a5:e5
""".replacingOccurrences(of: ":", with: "")
   .replacingOccurrences(of: "\n", with: "")
        
        let key = COSEKeyRSA(
            alg: COSEAlgorithmIdentifier.rs256.rawValue,
            n: Data(hex: modulus).bytes,
            e: Data(hex: "010001").bytes
        )

        XCTAssertEqual(key.toBytes().toHexString(), "a40103033901002059010100ac50a7c4b64e32965ca42cd088629e873ac0b46ae12712b26650924b940a3f5d97458959c4014bd7bb4add8dd8716ab1d483288f587423d776afc54a8242d148fd4027579bd86e03da06a8a171ca26c7c92d086b4e976590b357bd89863c59d6451ea11a67e2c02e7bec78c5e7e7d1d751b671e42c41e824ab18dc11a26ed69c55c2e839c13874ff66e6b0f15220c187ed2bff40018435fd9576aaf63f5fea68928b93e95260ee3c39c9a05a776280c661d2a9cc4538a51696518871a444b707085c6dd9b3007ec76b8cffe576741243bb0029c205590ae0633a4a64863afb5608c0e7876a51680fe7114c44dfbe6c452a56d892102f85b99758c00b7bfaa5e52143010001")
    }
    
    func testEc2CoseKey() {
        let key = COSEKeyEC2(
            alg: COSEAlgorithmIdentifier.es256.rawValue,
            crv: 1,
            xCoord: Data(hex: "65eda5a12577c2bae829437fe338701a10aaa375e1bb5b5de108de439c08551d").bytes,
            yCoord: Data(hex: "1e52ed75701163f7f9e40ddf9f341b3dc9ba860af7e0ca7ca7e9eecd0084d19c").bytes
        )
        XCTAssertEqual(key.toBytes().toHexString(), "a501020326200121582065eda5a12577c2bae829437fe338701a10aaa375e1bb5b5de108de439c08551d2258201e52ed75701163f7f9e40ddf9f341b3dc9ba860af7e0ca7ca7e9eecd0084d19c")
    }

}
