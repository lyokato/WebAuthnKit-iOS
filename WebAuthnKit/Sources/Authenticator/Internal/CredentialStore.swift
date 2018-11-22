//
//  CredentialStore.swift
//  WebAuthnKit
//
//  Created by Lyo Kato on 2018/11/20.
//  Copyright © 2018 Lyo Kato. All rights reserved.
//

import Foundation
import Security
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
        WAKLogger.debug("<PublicKeyCredentialSource> toCBOR")

        let builder = CBORWriter()

        let dict = SimpleOrderedDictionary<String>()
        
        dict.addString("rpId", self.rpId)
        dict.addString("privateKey", self.privateKey)
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
        if let alg = dict["alg"] as? Int64 {
            algId = Int(alg)
        } else {
            WAKLogger.debug("<PublicKeyCredentialSource> alg not found")
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
    
    private func newRandom() -> Optional<[UInt8]> {
        var randomBytes = [UInt8](repeating: 0, count: 16)
        if SecRandomCopyBytes(kSecRandomDefault, 16, &randomBytes) == errSecSuccess {
            return randomBytes
        } else {
            WAKLogger.debug("<KeychainStore> failed to create random")
            return nil
        }
    }

    public func loadAllCredentialSources(rpId: String) -> [PublicKeyCredentialSource] {
        WAKLogger.debug("<KeychainStore> loadAllCredentialSources")
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
        WAKLogger.debug("<KeychainStore> loadGlobalSignCounter")
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
        WAKLogger.debug("<KeychainStore> saveGlobalSignCounter")
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
            WAKLogger.debug("<KeychainStore> lookupCredentialSource")

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
        WAKLogger.debug("<KeychainStore> saveCredentialSource")

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
