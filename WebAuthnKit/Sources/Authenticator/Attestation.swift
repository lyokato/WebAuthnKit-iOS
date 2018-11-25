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
    let attStmt: SimpleOrderedDictionary<String>
    
    init(fmt:      String,
         authData: AuthenticatorData,
         attStmt:  SimpleOrderedDictionary<String>) {
        
        self.fmt      = fmt
        self.authData = authData
        self.attStmt  = attStmt
    }
    
    public func toNone() -> AttestationObject {
        // TODO copy authData with aaguid=0
        return AttestationObject(
            fmt: "none",
            authData: self.authData,
            attStmt: SimpleOrderedDictionary<String>()
        )
    }
    
    public func isSelfAttestation() -> Bool {
        if self.fmt != "packed" {
            return false
        }
        if let _ = self.attStmt.get("x5c") {
            return false
        }
        if let _ = self.attStmt.get("ecdaaKeyId") {
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
        
        let dict = SimpleOrderedDictionary<String>()
        dict.addBytes("authData", self.authData.toBytes())
        dict.addString("fmt", "packed")
        dict.addStringKeyMap("attStmt", self.attStmt)

        return CBORWriter()
            .putStringKeyMap(dict)
            .getResult()
    }
    
}
