# WebAuthnKit

This library provides you a way to handle W3C Web Authentication API (a.k.a. WebAuthN / FIDO 2.0) easily.

#### Demo App

![webauthreg_5](https://user-images.githubusercontent.com/30877/48976478-bc1f5f00-f0cb-11e8-88ef-c6d7704b40b4.gif)

## Getting Started

### Info.plist

Beforehand, modify your Info.plist for FaceID permission.

Add `Privacy - Face ID Usage Description (NSFaceIDUsageDescription)` item, and write your purpose.

![webauthn_plist](https://user-images.githubusercontent.com/30877/48976918-3d2e2480-f0d3-11e8-8c8a-2406fd36d189.png)

### Setup your WebAuthnClient

At first, compose your client object like following.

```swift
import WebAuthnKit

let userConsentUI = UserConsentUI(viewController: self)
let authenticator = InternalAuthenticator(ui: userConsentUI)

self.webAuthnClient = WebAuthnClient(
    origin:        "https://example.org",
    authenticator: authenticator
)
```

## Registration Flow

With a flow which is described in following documents,
WebAuthnClient creates a credential if success.

- https://www.w3.org/TR/webauthn/#createCredential
- https://www.w3.org/TR/webauthn/#op-make-cred


```swift
var options = PublicKeyCredentialCreationOptions()
options.challenge = Bytes.fromHex(challenge) // must be Array<UInt8>
options.user.id = Bytes.fromString(userId) // must be Array<UInt8>
options.user.name = userName
options.user.displayName = displayName
options.user.icon = iconURL  // Optional
options.rp.id = "https://example.org"
options.rp.name = "your_service_name"
options.rp.icon = yourServiceIconURL // Optional
options.attestation = .required // (choose from .required, .preferred, .discouraged)
options.addPubKeyCredParam(alg: .es256)
options.authenticatorSelection = AuthenticatorSelectionCriteria(
    requireResidentKey: requireResidentKey, // this flag is ignored by InternalAuthenticator
    userVerification: verification
)

self.webAuthnClient.create(options).then { credential in
  // sent parameters to your server

  // credential.id
  // credential.rawId
  // credential.response.attestationObject
  // credential.response.clientDataJSON

}.catch { error in
  // error handling
}
```

Each option-parameter corresponds to JavaScript API implemented on web-browsers.


### Flow with PromiseKit

WebAuthnKit currently adopt PromiseKit, so,
whole registration process can be written like this.

```swift
import PromiseKit

firstly {

  self.yourServiceHTTPClient.getRegistrationOptions()

}.then { response in

  let options = self.createCreationOptionsFromHTTPResponse(response)
  self.webAuthnClient.create(options)

}.then { credential in

  let request = self.createHTTPRequestFromCredential(credential)
  self.yourServiceHTTPClient.postdRegistrationCredential(request)

}.done { resp

   // show completion message on UI

}.catch { error in

  // error handling

}
```

If you would like to stop while client is in progress, you can call `cancel` method.

```swift
self.webAuthnClient.cancel()
```

`WAKError.cancelled` will be dispatched as an Error of waiting Promise.

### Authentication Flow

With a flow which is described in following documents,
WebAuthnClient finds credentials, let user to select one (if multiple), and signs the response with it.

- https://www.w3.org/TR/webauthn/#getAssertion
- https://www.w3.org/TR/webauthn/#op-get-assertion

```swift
var options = PublicKeyCredentialRequestOptions()
options.challenge = Bytes.fromHex(challenge) // must be Array<UInt8>
options.rpId = "https://example.org"
options.userVerification = .required // (choose from .required, .preferred, .discouraged)
options.addAllowCredential(
    credentialId: Bytes.fromHex(credId),
    transports:   [.internal_]
)

self.webAuthnClient.get(options).then { assertion in
  // send parameters to your server

  // assertion.id
  // assertion.rawId
  // assertion.response.authenticatorData
  // assertion.response.signature
  // assertion.response.userHandle
  // assertion.response.clientDataJSON

}.catch {
  // error handling
}
```


You may want to write whole assertion process like following.

```swift

firstly {

  self.yourServiceHTTPClient.getAuthenticationOptions()

}.then { response in

  let options = self.createRequestOptionsFromHTTPResponse(response)
  self.webAuthnClient.get(options)

}.then { assertion in

  let request = self.createHTTPRequestFromAssertion(assertion)
  self.yourServiceHTTPClient.postAssertion(request)

}.done {

  // show completion message on UI

}.catch { error in

  // error handling

}

```

## Features

### Not implemented yet

- [ ] Token Binding
- [ ] Extensions
- [ ] BLE Authenticator
- [ ] BLE Roaming Service

### Key Algorithm Support

- ES256

### Resident Key

InternalAuthenticator forces to use resident-key.

## See Also

- https://www.w3.org/TR/webauthn/
- https://fidoalliance.org/specs/fido-v2.0-rd-20170927/fido-client-to-authenticator-protocol-v2.0-rd-20170927.html

## License

MIT-LICENSE

## Author

Lyo Kato <lyo.kato __at__ gmail.com>
