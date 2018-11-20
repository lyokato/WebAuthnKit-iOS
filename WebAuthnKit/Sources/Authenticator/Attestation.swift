//
//  Attestation.swift
//  WebAuthnKit
//
//  Created by Lyo Kato on 2018/11/20.
//  Copyright © 2018 Lyo Kato. All rights reserved.
//

import Foundation
import CryptoSwift

public class AttestationObject {
    
    let fmt: String
    let authData: AuthenticatorData
    let attStmt: [String: Any]
    
    init(fmt:      String,
         authData: AuthenticatorData,
         attStmt:  [String: Any]) {
        
        self.fmt      = fmt
        self.authData = authData
        self.attStmt  = attStmt
    }
    
    public func toNone() -> AttestationObject {
        // TODO copy authData with aaguid=0
        return AttestationObject(
            fmt: "none",
            authData: self.authData,
            attStmt: [String: Any]()
        )
    }
    
    public func isSelfAttestation() -> Bool {
        if self.fmt != "packed" {
            return false
        }
        if let _ = self.attStmt["x5c"] {
            return false
        }
        if let _ = self.attStmt["ecdaaKeyId"] {
            return false
        }
        guard let attestedCred = self.authData.attestedCredentialData else {
            return false
        }
        if attestedCred.aaguid.contains(where: { $0 != 0x00 }) {
            return false
        }
        return true
    }
    
    public func toBytes() -> Optional<[UInt8]> {
        
        let dict = SimpleOrderedDictionary<String, Any>()
        dict.add("authData", self.authData.toBytes())
        dict.add("fmt", "packed")
        dict.add("attStmt", self.attStmt)

        return CBORWriter()
            .putStringKeyMap(dict)
            .getResult()
    }
    
}
