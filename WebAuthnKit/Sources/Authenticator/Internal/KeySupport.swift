//
//  KeySupport.swift
//  WebAuthnKit
//
//  Created by Lyo Kato on 2018/11/20.
//  Copyright © 2018 Lyo Kato. All rights reserved.
//

import Foundation
import CryptoSwift
import SwiftyRSA
import EllipticCurveKeyPair

public protocol KeySupport {
    var selectedAlg: COSEAlgorithmIdentifier { get }
    func canHandle(alg: Int) -> Bool
    func createKeyPair() -> Optional<(String, String)>
    func convertPublicKeyPEMToCOSE(_ pem: String) -> Optional<COSEKey>
    func sign(data: [UInt8], pem: String) -> Optional<[UInt8]>
}

public class KeySupportChooser {
    
    public init() {}

    // TODO support ECDSA
    public func choose(_ requestedAlgorithms: [COSEAlgorithmIdentifier])
        -> Optional<KeySupport> {

        for alg in requestedAlgorithms {
            switch alg {
            case COSEAlgorithmIdentifier.rs256:
                return RSAKeySupport(alg: .rs256)
            case COSEAlgorithmIdentifier.rs384:
                return RSAKeySupport(alg: .rs384)
            case COSEAlgorithmIdentifier.rs512:
                return RSAKeySupport(alg: .rs512)
            default:
                WAKLogger.debug("<KeySupportChooser> currently this algorithm not supported")
                return nil
            }
        }

        return nil
    }
}

public class RSAKeySupport : KeySupport {

    public static let algorithms: [COSEAlgorithmIdentifier] = [.rs256, .rs384, .rs512]

    public let selectedAlg: COSEAlgorithmIdentifier
    public var keySize: Int = 2048

    public func canHandle(alg: Int) -> Bool {
        return type(of: self).algorithms.contains { $0.rawValue == alg }
    }

    init(alg: COSEAlgorithmIdentifier) {
        self.selectedAlg = alg
    }

    public func createKeyPair() -> Optional<(String, String)> {
        do {
            let keyPair    = try SwiftyRSA.generateRSAKeyPair(sizeInBits: self.keySize)
            let privateKey = try keyPair.privateKey.pemString()
            let publicKey  = try keyPair.publicKey.pemString()
            return (publicKey, privateKey)
        } catch let error {
            WAKLogger.debug("<RSAKeySupport> failed to create key-pair: \(error)")
            return nil
        }
    }

    public func sign(data: [UInt8], pem: String) -> Optional<[UInt8]> {
        do {
            let privateKey = try PrivateKey(pemEncoded: pem)
            let msg = ClearMessage(data: Data(bytes: data))
            let encrypted = try msg.signed(with: privateKey, digestType: self.getDigestType())
            return encrypted.data.bytes
        } catch let error {
            WAKLogger.debug("<RSAKeySupport> failed to sign: \(error)")
            return nil
        }
    }

    public func convertPublicKeyPEMToCOSE(_ pem: String) -> Optional<COSEKey> {
        return PEM.parseRSAPublicKey(
            pem: pem,
            alg: self.selectedAlg
        )
    }

    private func getDigestType() -> Signature.DigestType {
        switch self.selectedAlg {
        case .rs256:
            return .sha256
        case .rs384:
            return .sha384
        case .rs512:
            return .sha512
        default:
            fatalError("must not come here")
        }
    }
}
