//
//  SelfAttestation.swift
//  WebAuthnKit
//
//  Created by Lyo Kato on 2018/11/20.
//  Copyright © 2018 Lyo Kato. All rights reserved.
//

import Foundation

public class SelfAttestation {
    
    public static func create(
        authData:       AuthenticatorData,
        clientDataHash: [UInt8],
        alg:             COSEAlgorithmIdentifier,
        privateKey:      String
        ) -> Optional<AttestationObject> {
        
        var dataToBeSigned = authData.toBytes()
        dataToBeSigned.append(contentsOf: clientDataHash)
        
        guard let keySupport =
            KeySupportChooser().choose([alg]) else {
                WAKLogger.debug("<AttestationHelper> key-support not found")
                return nil
        }
        
        let sig = keySupport.sign(
            data: dataToBeSigned,
            pem:  privateKey
        )
        
        var stmt = [String: Any]()
        stmt["alg"] = alg
        stmt["sig"] = sig
        
        return AttestationObject(
            fmt:      "packed",
            authData: authData,
            attStmt:  stmt
        )
    }

    
}
