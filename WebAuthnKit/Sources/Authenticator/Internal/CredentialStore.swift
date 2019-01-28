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

public protocol CredentialStore {
    func lookupCredentialSource(rpId: String, credentialId: [UInt8]) -> Optional<PublicKeyCredentialSource>
    func saveCredentialSource(_ cred: PublicKeyCredentialSource) -> Bool
    func loadAllCredentialSources(rpId: String) -> [PublicKeyCredentialSource]
    func deleteCredentialSource(_ cred: PublicKeyCredentialSource) -> Bool
    func deleteAllCredentialSources(rpId: String, userHandle: [UInt8])
}

public class KeychainCredentialStore : CredentialStore {

    private static let webAuthnKitService: String = "webauthnkit"
    private static let encryptionKeyHandle: String = "encryption-key"
    
    public init() {}
    
    public func loadAllCredentialSources(rpId: String) -> [PublicKeyCredentialSource] {
        WAKLogger.debug("<KeychainStore> loadAllCredentialSources")
        let keychain = Keychain(service: rpId)
        return keychain.allKeys().compactMap {
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
    
    public func deleteAllCredentialSources(rpId: String, userHandle: [UInt8]) {
        self.loadAllCredentialSources(rpId: rpId, userHandle: userHandle).forEach {
            _ = self.deleteCredentialSource($0)
        }
    }
    
    public func loadAllCredentialSources(rpId: String, userHandle: [UInt8]) -> [PublicKeyCredentialSource] {
        WAKLogger.debug("<KeychainStore> loadAllCredentialSources with userHandle")
        return self.loadAllCredentialSources(rpId: rpId).filter { $0.userHandle.elementsEqual(userHandle) }
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
    
    public func deleteCredentialSource(_ cred: PublicKeyCredentialSource) -> Bool {
        
        WAKLogger.debug("<KeychainStore> deleteCredentialSource")
        
        let handle = cred.id.toHexString()
        let keychain = Keychain(service: cred.rpId)
        
        do {
            try keychain.remove(handle)
            return true
        } catch let error {
            WAKLogger.debug("<KeychainStore> failed to delete credential-source: \(error)")
            return false
        }

    }

    public func saveCredentialSource(_ cred: PublicKeyCredentialSource) -> Bool {
        WAKLogger.debug("<KeychainStore> saveCredentialSource")

        let handle = cred.id.toHexString()
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
