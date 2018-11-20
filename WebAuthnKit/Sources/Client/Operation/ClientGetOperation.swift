//
//  ClientGetOperation.swift
//  WebAuthnKit
//
//  Created by Lyo Kato on 2018/11/20.
//  Copyright © 2018 Lyo Kato. All rights reserved.
//

import Foundation
import PromiseKit

public class ClientGetOperation: AuthenticatorGetAssertionSessionDelegate {
    
    public let id = UUID().uuidString
    public let type = ClientOperationType.get
    public var delegate: ClientOperationDelegate?

    private let options:        PublicKeyCredentialRequestOptions
    private let rpId:           String
    private let clientData:     CollectedClientData
    private let clientDataJSON: String
    private let clientDataHash: [UInt8]
    private let lifetimeTimer:  UInt64

    private var savedCredentialId: [UInt8]?

    private var session: AuthenticatorGetAssertionSession
    private var resolver: Resolver<WebAuthnClient.GetResponse>?
    private var stopped: Bool = false

    private var timer: Timer?

    internal init(
        options:        PublicKeyCredentialRequestOptions,
        rpId:           String,
        session:        AuthenticatorGetAssertionSession,
        clientData:     CollectedClientData,
        clientDataJSON: String,
        clientDataHash: [UInt8],
        lifetimeTimer:  UInt64
    ) {
        self.options        = options
        self.rpId           = rpId
        self.session        = session
        self.clientData     = clientData
        self.clientDataJSON = clientDataJSON
        self.clientDataHash = clientDataHash
        self.lifetimeTimer  = lifetimeTimer
    }

    public func start() -> Promise<WebAuthnClient.GetResponse> {
        return Promise { resolver in
            DispatchQueue.global().async {
                
                if self.stopped {
                    WAKLogger.debug("<GetOperation> already stopped")
                    DispatchQueue.main.async {
                        resolver.reject(WAKError.badOperation)
                    }
                    self.delegate?.operationDidFinish(opType: self.type, opId: self.id)
                    return
                }
                
                let transports: [AuthenticatorTransport] =
                    self.options.allowCredentials.flatMap { $0.transports }
                
                if !transports.isEmpty
                    && !transports.contains(self.session.transport) {
                    WAKLogger.debug("<GetOperation> transport mismatch")
                    DispatchQueue.main.async {
                        resolver.reject(WAKError.notAllowed)
                    }
                    self.delegate?.operationDidFinish(opType: self.type, opId: self.id)
                    return
                }
                
                if self.resolver != nil {
                    WAKLogger.debug("<GetOperation> already started")
                    DispatchQueue.main.async {
                        resolver.reject(WAKError.badOperation)
                    }
                    self.delegate?.operationDidFinish(opType: self.type, opId: self.id)
                    return
                }
                self.resolver = resolver
                
                // start timer
                // 5.1.4 - 17 Start lifetime timer
                self.startLifetimeTimer()
                
                self.session.delegate = self
                self.session.start()
                
            }
        }
    }
    
    public func cancel() {
        DispatchQueue.global().async {
            self.stop(by: .cancelled)
        }
    }

    private func stop() {
        if self.resolver == nil {
            WAKLogger.debug("<GetOperation> not started")
            return
        }
        if self.stopped {
            WAKLogger.debug("<GetOperation> already stopped")
            return
        }
        self.stopped = true
        self.stopLifetimeTimer()
        self.session.cancel()
        self.delegate?.operationDidFinish(opType: self.type, opId: self.id)
    }

    // MARK: Private Methods

    private func startLifetimeTimer() {
        if self.timer != nil {
            return
        }
        self.timer = Timer.scheduledTimer(
            timeInterval: TimeInterval(self.lifetimeTimer),
            target:       self,
            selector:     #selector(ClientGetOperation.lifetimeTimerTimeout),
            userInfo:     nil,
            repeats:      false
        )
    }

    private func stop(by error: WAKError) {
        self.stop()
        self.dispatchError(error)
    }

    private func dispatchError(_ error: WAKError) {
        DispatchQueue.main.async {
            if let resolver = self.resolver {
                resolver.reject(error)
                self.resolver = nil
            }
        }
    }

    private func stopLifetimeTimer() {
        self.timer?.invalidate()
        self.timer = nil
    }

    @objc func lifetimeTimerTimeout() {
        self.stopLifetimeTimer()
    }

    private func judgeUserVerificationExecution(_ session: AuthenticatorGetAssertionSession) -> Bool {
        switch self.options.userVerification {
        case .required:
            return true
        case .preferred:
            return session.canPerformUserVerification()
        case .discouraged:
            return false
        }
    }

    // MARK: AuthenticatorGetAssertionSessionDelegate Methods

    public func authenticatorSessionDidBecomeAvailable(session: AuthenticatorGetAssertionSession) {

        if self.stopped {
            WAKLogger.debug("<GetOperation> already stopped")
            return
        }

        if self.options.userVerification == .required
            && !session.canPerformUserVerification() {
            WAKLogger.debug("<GetOperation> user-verification is required, but this authenticator doesn't support")
            self.stop(by: .unsupported)
            return
        }

        let userVerification =
            self.judgeUserVerificationExecution(session)

        let userPresence = !userVerification

        if self.options.allowCredentials.isEmpty {

            session.getAssertion(
                rpId:                          self.rpId,
                hash:                          self.clientDataHash,
                allowCredentialDescriptorList: self.options.allowCredentials,
                requireUserPresence:           userPresence,
                requireUserVerification:       userVerification
            )

        } else {

            var allowCredentialDescriptorList = self.options.allowCredentials.filter {
                // TODO more check for id
                $0.transports.contains(session.transport)
            }

            if (allowCredentialDescriptorList.isEmpty) {
                WAKLogger.debug("<GetOperation> no matched credential on this authenticator")
                self.stop(by: .notAllowed)
                return
            }

            // need to remember the credential Id
            // because authenticator doesn't return credentialId for single descriptor
            if allowCredentialDescriptorList.count == 1 {
                self.savedCredentialId = allowCredentialDescriptorList[0].id
            }

            session.getAssertion(
                rpId:                          self.rpId,
                hash:                          self.clientDataHash,
                allowCredentialDescriptorList: allowCredentialDescriptorList,
                requireUserPresence:           userPresence,
                requireUserVerification:       userVerification
            )

        }
    }

    public func authenticatorSessionDidDiscoverCredential(
        session:   AuthenticatorGetAssertionSession,
        assertion: AuthenticatorAssertionResult
    ) {
        var credentialId: [UInt8]
        if let savedId = self.savedCredentialId {
           credentialId = savedId
        } else {
            guard let resultId = assertion.credentailId else {
                self.dispatchError(.unknown)
                return
            }
            credentialId = resultId
        }

        // TODO support extensionResult
        let cred = PublicKeyCredential<AuthenticatorAssertionResponse>(
            rawId:    credentialId,
            id:       Base64.encodeBase64URL(credentialId),
            response: AuthenticatorAssertionResponse(
                clientDataJSON:    self.clientDataJSON,
                authenticatorData: assertion.authenticatorData,
                signature:         assertion.signature,
                userHandler:       assertion.userHandle
            )
        )

        self.stop()
        DispatchQueue.main.async {
            if let resolver = self.resolver {
                resolver.fulfill(cred)
                self.resolver = nil
            }
        }
    }

    public func authenticatorSessionDidBecomeUnavailable(session: AuthenticatorGetAssertionSession) {
        self.stop(by: .notAllowed)
    }

    public func authenticatorSessionDidStopOperation(
        session: AuthenticatorGetAssertionSession,
        reason:  AuthenticatorError
    ) {
        switch reason {
        case .userCancelled:
            self.stop(by: .cancelled)
        case .invalidStateError:
            self.stop(by: .invalidState)
        default:
            self.stop(by: .notAllowed)
        }
    }

}

