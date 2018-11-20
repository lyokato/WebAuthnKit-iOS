//
//  CredentialStore.swift
//  WebAuthnKit
//
//  Created by Lyo Kato on 2018/11/20.
//  Copyright © 2018 Lyo Kato. All rights reserved.
//

import Foundation
import KeychainAccess
import CryptoSwift

public struct PublicKeyCredentialSource {

    var type:       PublicKeyCredentialType = .publicKey
    var signCount:  UInt32 = 0
    var id:         [UInt8]? // credential id
    var privateKey: String
    var rpId:       String
    var userHandle: [UInt8]
    var alg:        Int = COSEAlgorithmIdentifier.rs256.rawValue
    var otherUI:    String?

    var isResidentKey: Bool = false

    init(
        rpId:       String,
        privateKey: String,
        userHandle: [UInt8],
        alg:        Int
    ) {
        self.rpId       = rpId
        self.privateKey = privateKey
        self.userHandle = userHandle
        self.alg        = alg
    }

    public func toCBOR() -> Optional<[UInt8]> {

        let builder = CBORWriter()

        let dict = SimpleOrderedDictionary<String, Any>()
        
        dict.add("rpId"       , self.rpId)
        dict.add("privateKey" , self.privateKey)
        dict.add("userHandle" , self.userHandle)
        dict.add("alg"        , self.alg)

        if self.isResidentKey {
            dict.add("signCount", self.signCount)
            if let credId = self.id {
                dict.add("id", credId)
            } else {
                WAKLogger.debug("<PublicKeyCredentialSource> id not found")
                return nil
            }
        }

        if let ui = self.otherUI {
            dict.add("otherUI", ui)
        }

        return builder.putStringKeyMap(dict).getResult()
    }

    public static func fromCBOR(_ bytes: [UInt8]) -> Optional<PublicKeyCredentialSource> {

        var rpId:       String = ""
        var privateKey: String = ""
        var userHandle: [UInt8];
        var algId:      Int = 0

        guard let dict = CBORReader(bytes: bytes).readStringKeyMap()  else {
            return nil
        }

        if let foundKey = dict["privateKey"] as? String {
            privateKey = foundKey
        } else {
            WAKLogger.debug("<PublicKeyCredentialSource> private-key not found")
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
        if let alg = dict["alg"] as? Int {
            algId = alg
        } else {
            WAKLogger.debug("<PublicKeyCredentialSource> userHandle not found")
            return nil
        }
        var src = PublicKeyCredentialSource(
            rpId:       rpId,
            privateKey: privateKey,
            userHandle: userHandle,
            alg:        algId
        )
        if let id = dict["id"] as? [UInt8] {
            src.id = id
            src.isResidentKey = true
        }
        if let signCount = dict["signCount"] as? UInt32 {
            src.signCount = signCount
        }
        if let otherUI = dict["otherUI"] as? String {
            src.otherUI = otherUI
        }
        return src
    }
}

public protocol CredentialStore {
    func lookupCredentialSource(rpId: String, credentialId: [UInt8]) -> Optional<PublicKeyCredentialSource>
    func saveCredentialSource(_ cred: PublicKeyCredentialSource) -> Bool
    func loadAllCredentialSources(rpId: String) -> [PublicKeyCredentialSource]
    func loadGlobalSignCounter(rpId: String) -> Optional<UInt32>
    func saveGlobalSignCounter(rpId: String, count: UInt32) -> Bool
}

public class KeychainCredentialStore : CredentialStore {

    private static let globalCounterHandle: String = "global-sign-count"
    
    public init() {}

    public func loadAllCredentialSources(rpId: String) -> [PublicKeyCredentialSource] {
        let keychain = Keychain(service: rpId)
        return keychain.allKeys().filter { $0 != type(of: self).globalCounterHandle }
            .compactMap {
                if let result = try? keychain.getData($0) {
                    if let bytes = result?.bytes {
                        return PublicKeyCredentialSource.fromCBOR(bytes)
                    } else {
                        WAKLogger.debug("<KeychainStore> not found data for key:\($0)")
                        return nil
                    }
                } else {
                    WAKLogger.debug("<KeychainStore> failed to load data for key:\($0)")
                   return nil
                }
        }
    }

    public func loadGlobalSignCounter(rpId: String) -> Optional<UInt32> {
        let keychain = Keychain(service: rpId)
        if let result = try? keychain.getString(type(of: self).globalCounterHandle) {
            if let str = result {
                return Bytes.toUInt32([UInt8](hex: str))
            } else {
                return UInt32(0)
            }
        } else {
            WAKLogger.debug("<KeychainStore> failed to load global-sign-count")
            return nil
        }
    }

    public func saveGlobalSignCounter(rpId: String, count: UInt32) -> Bool {
        let keychain = Keychain(service: rpId)
        do {
            try keychain.set(Bytes.fromUInt32(count).toHexString(),
                             key: type(of: self).globalCounterHandle)
            return true
        } catch let error {
            WAKLogger.debug("<KeychainStore> failed to save global-sign-count: \(error)")
            return false
        }
    }

    public func lookupCredentialSource(rpId: String, credentialId: [UInt8])
        -> Optional<PublicKeyCredentialSource> {

            let handle = credentialId.toHexString()
            let keychain = Keychain(service: rpId)

            if let result = try? keychain.getData(handle) {
                if let bytes = result?.bytes {
                    return PublicKeyCredentialSource.fromCBOR(bytes)
                } else {
                    WAKLogger.debug("<KeychainStore> not found data for key:\(handle)")
                    return nil
                }
            } else {
                WAKLogger.debug("<KeychainStore> failed to load data for key:\(handle)")
                return nil
            }
    }

    public func saveCredentialSource(_ cred: PublicKeyCredentialSource) -> Bool {

        guard let credentialId = cred.id else {
            WAKLogger.debug("<KeychainStore> credential id not found")
            return false
        }

        if !cred.isResidentKey {
            WAKLogger.debug("<KeychainStore> credential is not a resident key")
            return false
        }

        let handle = credentialId.toHexString()
        let keychain = Keychain(service: cred.rpId)

        if let bytes = cred.toCBOR() {
            do {
                try keychain.set(Data(bytes: bytes), key: handle)
                return true
            } catch let error {
                WAKLogger.debug("<KeychainStore> failed to save credential-source: \(error)")
                return false
            }
        } else {
            return false
        }
    }
}
