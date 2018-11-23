//
//  CredentialEncryptor.swift
//  WebAuthnKit
//
//  Created by Lyo Kato on 2018/11/20.
//  Copyright © 2018 Lyo Kato. All rights reserved.
//

import Foundation
import CryptoSwift

public protocol CredentialEncryptor {
    func encryptCredentialSource(_ src: PublicKeyCredentialSource) -> Optional<[UInt8]>
    func decryptCredentialId(_ credentialId: [UInt8]) -> Optional<PublicKeyCredentialSource>
}

public class AESGCMCredentialEncryptor: CredentialEncryptor {

    private let credentialStore: CredentialStore

    public init(credentialStore: CredentialStore) {
        self.credentialStore = credentialStore
    }
    
    private func newIV() -> [UInt8] {
        return AES.randomIV(AES.blockSize)
    }

    private func newAES(iv: [UInt8], key: [UInt8]) -> AES {
        let gcm = GCM(iv: iv, mode: .combined)
        let aes = try! AES(key: key, blockMode: gcm, padding: .noPadding)
        return aes
    }

    public func encryptCredentialSource(_ src: PublicKeyCredentialSource) -> Optional<[UInt8]> {
        WAKLogger.debug("<AESGCMCredentialEncryptor> encryptCredentialSource")
        
        if src.isResidentKey {
            WAKLogger.debug("<AESGCMCredentialEncryptor> resident key should not be encrypted")
           return nil
        }
        
        let iv = newIV()
        if iv.count != 16 {
            WAKLogger.debug("<AESGCMCredentialEncryptor> length of 'iv' should be 16")
            return nil
        }
        
        guard let key = self.credentialStore.findOrCreateEncryptionKey() else {
            WAKLogger.debug("<AESGCMCredentialEncryptor> failed to load encryption key")
            return nil
        }
        
        do {
            if let bytes = src.toCBOR() {
                let encrypted = try self.newAES(iv: iv, key: key).encrypt(bytes)
                return iv + encrypted
            } else {
                return nil
            }
        } catch let error {
            WAKLogger.debug("<AESGCMCredentialEncryptor> failed to encrypt: \(error)")
            return nil
        }
    }

    public func decryptCredentialId(_ credentialId: [UInt8]) -> Optional<PublicKeyCredentialSource> {
        WAKLogger.debug("<AESGCMCredentialEncryptor> decryptCredentialSource")
        
        let len = credentialId.count
        if len < 17 {
            WAKLogger.debug("<AESGCMCredentialEncryptor> length of 'credentialId' should be more than 17")
            return nil
        }
        
        guard let key = self.credentialStore.findOrCreateEncryptionKey() else {
            WAKLogger.debug("<AESGCMCredentialEncryptor> failed to load encryption key")
            return nil
        }
        
        do {
            let iv = Array(credentialId[0..<16])
            let data = Array(credentialId[16..<len])
            let decrypted = try self.newAES(iv: iv, key: key).decrypt(data)
            return PublicKeyCredentialSource.fromCBOR(decrypted)
        } catch let error {
            WAKLogger.debug("<AESGCMCredentialEncryptor> failed to decrypt: \(error)")
            return nil
        }
    }

}
