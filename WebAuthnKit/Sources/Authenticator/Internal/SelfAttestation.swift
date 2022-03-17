//
//  SelfAttestation.swift
//  WebAuthnKit
//
//  Created by Lyo Kato on 2018/11/20.
//  Copyright © 2018 Lyo Kato. All rights reserved.
//

import Foundation
import LocalAuthentication

public class SelfAttestation {
    
    public static func create(
        authData:       AuthenticatorData,
        clientDataHash: [UInt8],
        alg:            COSEAlgorithmIdentifier,
        keyLabel:       String,
        context:        LAContext
        ) -> Optional<AttestationObject> {
        
        WAKLogger.debug("<SelfAttestation> create")
        
        var dataToBeSigned = authData.toBytes()
        dataToBeSigned.append(contentsOf: clientDataHash)
        
        guard let keySupport =
            KeySupportChooser().choose([alg]) else {
                WAKLogger.debug("<SelfAttestation> key-support not found")
                return nil
        }
        
        guard let sig = keySupport.sign(
            data:  dataToBeSigned,
            label: keyLabel,
            context: context
        ) else {
            WAKLogger.debug("<AttestationHelper> failed to sign")
            return nil
        }
        
        let stmt = SimpleOrderedDictionary<String>()
        stmt.addInt("alg", Int64(alg.rawValue))
        stmt.addBytes("sig", sig)
        
        return AttestationObject(
            fmt:      "packed",
            authData: authData,
            attStmt:  stmt
        )
    }

    
}
