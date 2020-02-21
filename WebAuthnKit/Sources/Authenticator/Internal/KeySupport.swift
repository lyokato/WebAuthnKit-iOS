//
//  KeySupport.swift
//  WebAuthnKit
//
//  Created by Lyo Kato on 2018/11/20.
//  Copyright © 2018 Lyo Kato. All rights reserved.
//

import Foundation
import CryptoSwift
import EllipticCurveKeyPair

public protocol KeySupport {
    var selectedAlg: COSEAlgorithmIdentifier { get }
    func createKeyPair() -> Optional<COSEKey>
    func sign(data: [UInt8]) -> Optional<[UInt8]>
    func setup(label: String)
}

public class KeySupportChooser {
    
    public init() {}

    public func choose(_ requestedAlgorithms: [COSEAlgorithmIdentifier])
        -> Optional<KeySupport> {
        WAKLogger.debug("<KeySupportChooser> choose")

        for alg in requestedAlgorithms {
            switch alg {
            case COSEAlgorithmIdentifier.es256:
                return ECDSAKeySupport(alg: .es256)
            default:
                WAKLogger.debug("<KeySupportChooser> currently this algorithm not supported")
                return nil
            }
        }

        return nil
    }
}

enum ECDSAKeySupportError : Error {
    case noKeyPair
}

public class ECDSAKeySupport : KeySupport {
    
    public let selectedAlg: COSEAlgorithmIdentifier
    public var pair: EllipticCurveKeyPair.Manager?
    
    init(alg: COSEAlgorithmIdentifier) {
        self.selectedAlg = alg
    }
    
    private func createPair(label: String) -> EllipticCurveKeyPair.Manager {
        let publicAccessControl = EllipticCurveKeyPair.AccessControl(
            protection: kSecAttrAccessibleAlwaysThisDeviceOnly,
            flags:      []
        )
        let privateAccessControl = EllipticCurveKeyPair.AccessControl(
            protection: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
            flags:      [.privateKeyUsage]
        )
        let config = EllipticCurveKeyPair.Config(
            publicLabel:             "\(label)/public",
            privateLabel:            "\(label)/private",
            operationPrompt:         "KeyPair",
            publicKeyAccessControl:  publicAccessControl,
            privateKeyAccessControl: privateAccessControl,
            token:                   EllipticCurveKeyPair.Token.secureEnclaveIfAvailable
        )
        return EllipticCurveKeyPair.Manager(config: config)
    }
    
    public func setup(label: String) {
        self.pair = self.createPair(label: label)
    }
    
    public func sign(data: [UInt8]) -> Optional<[UInt8]> {
        do {
            guard let pair = self.pair else { throw ECDSAKeySupportError.noKeyPair }
            let signature = try pair.sign(Data(bytes: data), hash: .sha256)
            return signature.bytes
        } catch let error {
            WAKLogger.debug("<ECDSAKeySupport> failed to sign: \(error)")
            return nil
        }
    }
    
    public func createKeyPair() -> Optional<COSEKey> {
        WAKLogger.debug("<ECDSAKeySupport> createKeyPair")
        do {
            guard let pair = self.pair else { throw ECDSAKeySupportError.noKeyPair }
            let publicKey = try pair.publicKey().data().DER.bytes
            if publicKey.count != 91 {
                WAKLogger.debug("<ECDSAKeySupport> length of pubKey should be 91: \(publicKey.count)")
                return nil
            }
            
            let x = Array(publicKey[27..<59])
            let y = Array(publicKey[59..<91])
            
            let key: COSEKey = COSEKeyEC2(
                alg: self.selectedAlg.rawValue,
                crv: COSEKeyCurveType.p256,
                xCoord: x,
                yCoord: y
            )
            return key
            
        } catch let error {
            WAKLogger.debug("<ECDSAKeySupport> failed to create key-pair: \(error)")
            return nil
        }
    }
}
