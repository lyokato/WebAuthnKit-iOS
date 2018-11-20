//
//  PEM.swift
//  WebAuthnKit
//
//  Created by Lyo Kato on 2018/11/20.
//  Copyright © 2018 Lyo Kato. All rights reserved.
//

import Foundation
import CryptoSwift

internal class PEM {

    public static func parseRSAPublicKey(pem: String, alg: COSEAlgorithmIdentifier) -> Optional<COSEKeyRSA> {

        let regex = try! NSRegularExpression(
            pattern: "-----BEGIN RSA PUBLIC KEY-----",
            options: .caseInsensitive
        )

        let matches = regex.matches(
            in: pem,
            options: [],
            range: NSMakeRange(0, pem.count)
        )

        if matches.isEmpty {
            WAKLogger.debug("<PEM> invalid format: no header")
           return nil
        }

        let lines = pem.split(separator: "\n").filter { !$0.isEmpty }

        if lines[lines.count - 1] != "-----END RSA PUBLIC KEY-----" {
            WAKLogger.debug("<PEM> invalid format: no footer")
            return nil
        }

        let b64: String = lines[1..<lines.count-1].joined()

        if let bytes = Data(base64Encoded: b64)?.bytes {

            let reader = DERReader(bytes: bytes)
            let _ = reader.readNext() // Ignore SEQUENCE
            guard let n1 = reader.readNext() else {
                WAKLogger.debug("<PEM> failed to read first int")
                return nil
            }
            guard let n2 = reader.readNext() else {
                WAKLogger.debug("<PEM> failed to read 2nd int")
                return nil
            }

            switch (n1, n2) {
            case ((.integer, let bytes1), (.integer, let bytes2)):
                return COSEKeyRSA(
                    alg: alg.rawValue,
                    n:   bytes1,
                    e:   bytes2
                )
            default:
                return nil
            }

        } else {
            WAKLogger.debug("<PEM> failed to decode base64")
            return nil
        }

    }


}
