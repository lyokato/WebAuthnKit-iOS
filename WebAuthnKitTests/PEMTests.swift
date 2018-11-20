//
//  PEMTests.swift
//  WebAuthnKitTests
//
//  Created by Lyo Kato on 2018/11/20.
//  Copyright © 2018 Lyo Kato. All rights reserved.
//

import XCTest

@testable import WebAuthnKit
@testable import CryptoSwift
@testable import SwiftyRSA

class PEMTests: XCTestCase {
    
    let rsaPubKey = """
-----BEGIN RSA PUBLIC KEY-----
MIIBCgKCAQEArFCnxLZOMpZcpCzQiGKehzrAtGrhJxKyZlCSS5QKP12XRYlZxAFL
17tK3Y3YcWqx1IMoj1h0I9d2r8VKgkLRSP1AJ1eb2G4D2gaooXHKJsfJLQhrTpdl
kLNXvYmGPFnWRR6hGmfiwC577HjF5+fR11G2ceQsQegkqxjcEaJu1pxVwug5wTh0
/2bmsPFSIMGH7Sv/QAGENf2Vdqr2P1/qaJKLk+lSYO48OcmgWndigMZh0qnMRTil
FpZRiHGkRLcHCFxt2bMAfsdrjP/ldnQSQ7sAKcIFWQrgYzpKZIY6+1YIwOeHalFo
D+cRTETfvmxFKlbYkhAvhbmXWMALe/ql5QIDAQAB
-----END RSA PUBLIC KEY-----
"""
    
    let rsaPrivKey = """
-----BEGIN RSA PRIVATE KEY-----
MIIEogIBAAKCAQEArFCnxLZOMpZcpCzQiGKehzrAtGrhJxKyZlCSS5QKP12XRYlZ
xAFL17tK3Y3YcWqx1IMoj1h0I9d2r8VKgkLRSP1AJ1eb2G4D2gaooXHKJsfJLQhr
TpdlkLNXvYmGPFnWRR6hGmfiwC577HjF5+fR11G2ceQsQegkqxjcEaJu1pxVwug5
wTh0/2bmsPFSIMGH7Sv/QAGENf2Vdqr2P1/qaJKLk+lSYO48OcmgWndigMZh0qnM
RTilFpZRiHGkRLcHCFxt2bMAfsdrjP/ldnQSQ7sAKcIFWQrgYzpKZIY6+1YIwOeH
alFoD+cRTETfvmxFKlbYkhAvhbmXWMALe/ql5QIDAQABAoIBABrbyDKuCdqdEPFE
Ik2dNZbgI7Ow1HRvLSCBNDRp7aj6e77fzalIBxwoD4ogzG5tPNe3iTsYBKOmN36R
SBpYCOARcrj50QsMpuFf1/6wylt+GOTsjYamrDLq9A+minuzXbsmBDgl84mUv/CC
01zg3OvsytJ4yCSOZydwzLNGTXQk5df3qhZd1WHs28gcNONLBr0e4v2Jr5olTNV5
EVowqi1EncIrRqR7NAPh9ikpPJychd6zoddXvwFCtqamD/1IZDMiKDgagSK2MjGQ
rdd6Tp9Mzo49XoP4hdB6ZgeqHbhzq+2rbYeEweQU+Sz5qsXLnX5NIVNZag0986zM
M5O6n6cCgYEA68mICo0AYVsOVOcRDipKZdgnJ6ZMkug0/AUrKSKi9w/UHg36lx+C
Ab6xmrkevdBeo4w3MPvsHhWlKJnERxlcY2QIz2ir2TsMStf4bSd6eKKCnl1LuMRf
4Uif7jEvo6E9amYRoG5VCJVav0O/G4v0jLYQqt6ZM0gWnPK0YXtQf5MCgYEAuxYy
BnZ1+YsFK57p70/HqkZ/js8hyD74j+JZsTz7hsfn9yQ2G/mwrpoaWxFWSxV69yDW
+mSBIBmL1lO98T6suvxCmAPnTsNnM5vkaYoitbY8SFgYIp7Xd9JX3ppK6Ez71cju
X5Hb2bu+MozFrX0kqoKNL19M7n/WuOvMSu2M/6cCgYBtZcD33Dnr8bpxjA/uuZJx
NFveWps2ogRLVf6ThF2GMdLh6ux0h4rjUl3HAtMPkIkIarsEwC3qO3K4prdZoZur
BbPMv6zUCkCGzTOXOXTqWcQuw+ypGnu949tIQYvv6JS9NARDok1TwTAsg7s8ha/+
RU7waH0+PNk5Eqa8f+F2fwKBgBvVQ3/+o7KKYiyJKdh2kAffER8X5bi61ZPiYuGh
ZvI4T2RPONWUohp3xrABtkrZWT/m3NTHmwZBhrJOJxX68wumd+nRutnW7EWbTbH9
4QgToohIwt5zry6eVoBBiB9jRJwblosVUhXkfnlaxBX5ZjkPzx1bGkDpN/Ku8ee7
y5xFAoGANnhuiLqjHN5eGWYxy5pldz5IBNVQLQOC+pAh4Phtd30JZOVFugIgvHLO
fTJIy2TKIh5KCcEYljHbHOPNGabcvWWtx5PS+wYTF2PvSavGS/UsLAvtkRhNdxDi
ohO8DgWJTevWSdq2u7bKyWweolgNMQOMELRR8RAJnpGQbOF8SuY=
-----END RSA PRIVATE KEY-----
"""
    
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
"""
    
    override func setUp() {
        WAKLogger.available = true
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testRsaPubKey() {
        let result = PEM.parseRSAPublicKey(
            pem: rsaPubKey,
            alg: COSEAlgorithmIdentifier.rs256
        )!
        let modulusHex = modulus
            .replacingOccurrences(of: ":", with: "")
            .replacingOccurrences(of: "\n", with: "")
        XCTAssertEqual(result.n.toHexString(), modulusHex)
        XCTAssertEqual(result.e.toHexString(), "010001")
        XCTAssertEqual(result.alg, COSEAlgorithmIdentifier.rs256.rawValue)
    }

}
