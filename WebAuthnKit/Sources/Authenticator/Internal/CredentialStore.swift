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

public protocol CredentialStore {
    func lookupCredentialSource(rpId: String, credentialId: [UInt8]) -> Optional<PublicKeyCredentialSource>
    func saveCredentialSource(_ cred: PublicKeyCredentialSource) -> Bool
    func loadAllCredentialSources(rpId: String) -> [PublicKeyCredentialSource]
    func loadGlobalSignCounter(rpId: String) -> Optional<UInt32>
    func saveGlobalSignCounter(rpId: String, count: UInt32) -> Bool
    func deleteCredentialSource(_ cred: PublicKeyCredentialSource) -> Bool
    func deleteAllCredentialSources(rpId: String, userHandle: [UInt8]) 
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
    
    public func deleteAllCredentialSources(rpId: String, userHandle: [UInt8]) {
        self.loadAllCredentialSources(rpId: rpId, userHandle: userHandle).forEach {
            _ = self.deleteCredentialSource($0)
        }
    }
    
    public func loadAllCredentialSources(rpId: String, userHandle: [UInt8]) -> [PublicKeyCredentialSource] {
        WAKLogger.debug("<KeychainStore> loadAllCredentialSources with userHandle")
        return self.loadAllCredentialSources(rpId: rpId).filter { $0.userHandle.elementsEqual(userHandle) }
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
    
    public func deleteCredentialSource(_ cred: PublicKeyCredentialSource) -> Bool {
        
        WAKLogger.debug("<KeychainStore> deleteCredentialSource")
        
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
