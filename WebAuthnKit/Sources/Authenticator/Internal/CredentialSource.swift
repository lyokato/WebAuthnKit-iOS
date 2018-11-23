//
//  CredentialSource.swift
//  WebAuthnKit
//
//  Created by Lyo Kato on 2018/11/23.
//  Copyright © 2018 Lyo Kato. All rights reserved.
//

import Foundation
import CryptoSwift

public struct PublicKeyCredentialSource {
    
    public var keyLabel: String {
        get {
            let userHex = self.userHandle.toHexString()
            return "\(self.rpId)/\(userHex)"
        }
    }
    
    var type:       PublicKeyCredentialType = .publicKey
    var signCount:  UInt32 = 0
    var id:         [UInt8]? // credential id
    var rpId:       String
    var userHandle: [UInt8]
    var alg:        Int = COSEAlgorithmIdentifier.rs256.rawValue
    var otherUI:    String?
    
    var isResidentKey: Bool = false
    
    init(
        rpId:       String,
        userHandle: [UInt8],
        alg:        Int
        ) {
        self.rpId       = rpId
        self.userHandle = userHandle
        self.alg        = alg
    }
    
    public func toCBOR() -> Optional<[UInt8]> {
        WAKLogger.debug("<PublicKeyCredentialSource> toCBOR")
        
        let builder = CBORWriter()
        
        let dict = SimpleOrderedDictionary<String>()
        
        dict.addString("rpId", self.rpId)
        dict.addBytes("userHandle", self.userHandle)
        dict.addInt("alg", Int64(self.alg))
        
        if self.isResidentKey {
            dict.addInt("signCount", Int64(self.signCount))
            if let credId = self.id {
                dict.addBytes("id", credId)
            } else {
                WAKLogger.debug("<PublicKeyCredentialSource> id not found")
                return nil
            }
        }
        
        if let ui = self.otherUI {
            dict.addString("otherUI", ui)
        }
        
        return builder.putStringKeyMap(dict).getResult()
    }
    
    public static func fromCBOR(_ bytes: [UInt8]) -> Optional<PublicKeyCredentialSource> {
        WAKLogger.debug("<PublicKeyCredentialSource> fromCBOR")
        
        var rpId:       String = ""
        var userHandle: [UInt8];
        var algId:      Int = 0
        
        guard let dict = CBORReader(bytes: bytes).readStringKeyMap()  else {
            return nil
        }
        
        if let foundRpId = dict["rpId"] as? String {
            rpId = foundRpId
        } else {
            WAKLogger.debug("<PublicKeyCredentialSource> rpId not found")
            return nil
        }
        if let handle = dict["userHandle"] as? [UInt8] {
            userHandle = handle
        } else {
            WAKLogger.debug("<PublicKeyCredentialSource> userHandle not found")
            return nil
        }
        if let alg = dict["alg"] as? Int64 {
            algId = Int(alg)
        } else {
            WAKLogger.debug("<PublicKeyCredentialSource> alg not found")
            return nil
        }
        var src = PublicKeyCredentialSource(
            rpId:       rpId,
            userHandle: userHandle,
            alg:        algId
        )
        if let id = dict["id"] as? [UInt8] {
            src.id = id
            src.isResidentKey = true
        } else {
            WAKLogger.debug("<PublicKeyCredentialSource> id not found")
        }
        if let signCount = dict["signCount"] as? Int64 {
            src.signCount = UInt32(signCount)
        } else {
            WAKLogger.debug("<PublicKeyCredentialSource> signCount not found")
        }
        if let otherUI = dict["otherUI"] as? String {
            src.otherUI = otherUI
        } else {
            WAKLogger.debug("<PublicKeyCredentialSource> otherUI not found")
        }
        return src
    }
}
