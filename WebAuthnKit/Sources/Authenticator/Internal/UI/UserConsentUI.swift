//
//  UserConsent.swift
//  WebAuthnKit
//
//  Created by Lyo Kato on 2018/11/20.
//  Copyright © 2018 Lyo Kato. All rights reserved.
//

import Foundation
import LocalAuthentication

import PromiseKit
import CryptoSwift

public protocol UserConsentViewControllerDelegate: class {
    func consentViewControllerWillDismiss(viewController: UIViewController)
}

public class UserConsentUI: UserConsentViewControllerDelegate {
    
    public typealias MessageBuilder = ((PublicKeyCredentialRpEntity ,PublicKeyCredentialUserEntity) -> String)

    private let viewController: UIViewController
    public let config = UserConsentUIConfig()

    private let tempBackground: UIView
    
    public private(set) var opened: Bool = false
    private var cancelled: WAKError? = nil

    public init(viewController: UIViewController) {
        self.viewController = viewController
        self.tempBackground = UIView()
        self.tempBackground.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.tempBackground.backgroundColor = UIColor.black
        self.tempBackground.alpha = 0
    }
    
    private func willStartUserInteraction() {
        self.opened = true
        self.cancelled = nil
    }
    
    private func didFinishUserInteraction() {
        self.opened = false
    }
    
    public func cancel(reason: WAKError) {
        self.cancelled = reason
    }
    
    internal func askUserToCreateNewCredential(rpId: String) -> Promise<()> {
        
        WAKLogger.debug("<UserConsentUI> askUserToCreateNewCredential")
        
        self.willStartUserInteraction()

        return Promise { resolver in

            DispatchQueue.main.async {

                let alert = UIAlertController.init(
                    title:          self.config.excludeKeyFoundPopupTitle,
                    message:        self.config.excludeKeyFoundPopupMessage,
                    preferredStyle: .actionSheet
                )

                let okAction = UIAlertAction.init(title: self.config.excludeKeyFoundPopupCreateButtonText, style: .default) { _ in
                    DispatchQueue.global().async {
                        self.didFinishUserInteraction()
                        if let reason = self.cancelled {
                            resolver.reject(reason)
                        } else {
                            resolver.fulfill(())
                        }
                    }
                }

                let cancelAction = UIAlertAction.init(title: self.config.excludeKeyFoundPopupCancelButtonText, style: .cancel) { _ in
                    DispatchQueue.global().async {
                        self.didFinishUserInteraction()
                        if let reason = self.cancelled {
                            resolver.reject(reason)
                        } else {
                            resolver.reject(WAKError.notAllowed)
                        }
                    }
                }

                alert.addAction(okAction)
                alert.addAction(cancelAction)

                self.viewController.present(alert, animated: true, completion: nil)
            }

        }

    }

    internal func requestUserConsent(
        rpEntity:            PublicKeyCredentialRpEntity,
        userEntity:          PublicKeyCredentialUserEntity,
        requireVerification: Bool,
        context:             LAContext
        ) -> Promise<String> {
        
        WAKLogger.debug("<UserConsentUI> requestUserConsent")
        
        self.willStartUserInteraction()
        
        return Promise<String> { resolver in
            
            DispatchQueue.main.async {
            
                let vc = KeyRegistrationViewController(
                    resolver:          resolver,
                    config:            self.config,
                    user:              userEntity,
                    rp:                rpEntity
                )
                
                vc.delegate = self
                
                self.showBackground()
                
                self.viewController.present(vc, animated: true, completion: nil)
                
            }
            
        }.then { (keyName: String) -> Promise<String> in

            if let reason = self.cancelled {

                self.didFinishUserInteraction()
                throw reason

            } else {
                
                if requireVerification {
                    
                    return self.verifyUser(
                        message: "Create-Key Authentication",
                        params:  keyName,
                        context: context
                    )
                    
                } else {
                    
                    return Promise<String>{ $0.fulfill(keyName) }
                    
                }

            }
            
        }.then { (keyName: String) -> Promise<String> in
            
            self.didFinishUserInteraction()
            
            if let reason = self.cancelled {
          
                throw reason
                
            } else {
                
                return Promise<String>{ $0.fulfill(keyName) }
                
            }
            
        }.recover { error -> Promise<String> in
            
            self.didFinishUserInteraction()
            
            if let reason = self.cancelled {
                
                throw reason
                
            } else {
                
               throw error
                
            }
            
        }
    }
    
    internal func requestUserSelection(
        sources:             [PublicKeyCredentialSource],
        requireVerification: Bool,
        context:             LAContext
        ) -> Promise<PublicKeyCredentialSource> {
        
        WAKLogger.debug("<UserConsentUI> requestUserSelection")
        
        self.willStartUserInteraction()
        
        return self.userSelectionTask(sources: sources)
            .then { (source: PublicKeyCredentialSource) -> Promise<PublicKeyCredentialSource> in
                
                if let reason = self.cancelled {
                    
                    self.didFinishUserInteraction()
                    throw reason
                    
                } else {
                    
                    if requireVerification {
                        
                        return self.verifyUser(
                            message: "Use-Key Authentication",
                            params: source,
                            context: context
                        )
                        
                    } else {
                        
                        return Promise<PublicKeyCredentialSource>{ $0.fulfill(source) }
                        
                    }
                    
                }
            }.then { (source: PublicKeyCredentialSource) -> Promise<PublicKeyCredentialSource> in
    
                self.didFinishUserInteraction()
        
                if let reason = self.cancelled {
                    throw reason
                } else {
                    return Promise<PublicKeyCredentialSource>{ $0.fulfill(source) }
                }
    
            }.recover { error -> Promise<PublicKeyCredentialSource> in
        
                self.didFinishUserInteraction()
        
                if let reason = self.cancelled {
        
                    throw reason
        
                } else {
        
                    throw error
        
                }
        
            }

    }
    
    private func userSelectionTask(sources: [PublicKeyCredentialSource]) -> Promise<PublicKeyCredentialSource> {
        
        if sources.count == 1 && !self.config.alwaysShowKeySelection {
            
            return Promise<PublicKeyCredentialSource> { resolver in
                DispatchQueue.main.async {
                    resolver.fulfill(sources[0])
                }
            }
            
        } else {
            
            return Promise<PublicKeyCredentialSource> { resolver in
                
                DispatchQueue.main.async {
                    
                    let vc = KeySelectionViewController(
                        resolver: resolver,
                        config:   self.config,
                        sources:  sources.reversed()
                    )
                    
                    vc.delegate = self
                    
                    self.showBackground()
                    
                    self.viewController.present(vc, animated: true, completion: nil)
                    
                }
                
            }
        }
    }

    private func verifyUser<T>(message: String, params: T, context: LAContext) -> Promise<T> {
        
        WAKLogger.debug("<UserConsentUI> verifyUser")

        return Promise<T> { resolver in

            DispatchQueue.main.async {

                var authError: NSError?
                
                if context.canEvaluatePolicy(self.config.localAuthPolicy, error: &authError) {
                    context.evaluatePolicy(self.config.localAuthPolicy,
                                       localizedReason: message,
                                       reply: { success, error in
                                        if success {
                                            DispatchQueue.global().async {
                                                resolver.fulfill(params)
                                            }
                                        } else if let error = error {
                                            switch LAError(_nsError: error as NSError) {
                                            case LAError.userFallback:
                                                WAKLogger.debug("<UserConsentUI> user fallback")
                                                self.dispatchError(resolver, .notAllowed)
                                            case LAError.userCancel:
                                                WAKLogger.debug("<UserConsentUI> user cancel")
                                                self.dispatchError(resolver, .notAllowed)
                                            case LAError.authenticationFailed:
                                                WAKLogger.debug("<UserConsentUI> authentication failed")
                                                self.dispatchError(resolver, .notAllowed)
                                            case LAError.passcodeNotSet:
                                                WAKLogger.debug("<UserConsentUI> passcode not set")
                                                self.dispatchError(resolver, .notAllowed)
                                            case LAError.systemCancel:
                                                WAKLogger.debug("<UserConsentUI> system cancel")
                                                self.dispatchError(resolver, .notAllowed)
                                            default:
                                                WAKLogger.debug("<UserConsentUI> must not come here")
                                                self.dispatchError(resolver, .unknown)
                                            }

                                        } else {
                                            WAKLogger.debug("<UserConsentUI> must not come here")
                                            self.dispatchError(resolver, .unknown)
                                        }
                    })
                } else {
                    let reason = authError?.localizedDescription ?? ""
                    WAKLogger.debug("<UserConsentUI> device not supported: \(reason)")
                    self.dispatchError(resolver, .notAllowed)
                }
            }
        }
    }
    
    private func dispatchError<T>(_ resolver: Resolver<T>, _ error: WAKError) {
        WAKLogger.debug("<UserConsentUI> dispatchError")
        DispatchQueue.global().async {
            resolver.reject(error)
        }
    }
    
    public func consentViewControllerWillDismiss(viewController: UIViewController) {
        self.hideBackground()
    }
    
    private func showBackground() {
        self.viewController.view.addSubview(self.tempBackground)
        self.tempBackground.frame = self.viewController.view.frame
        UIView.animate(withDuration: 0.2, delay: 0.0, options: [.curveEaseIn], animations: {
            self.tempBackground.alpha = 0.4
        }, completion: nil)
    }
    
    private func hideBackground() {
        if self.tempBackground.superview != nil {
            UIView.animate(withDuration: 0.2, delay: 0.0, options: [.curveEaseIn], animations: {
                self.tempBackground.alpha = 0.0
            }, completion: { _ in
                self.tempBackground.removeFromSuperview()
            })
        }
    }


}
