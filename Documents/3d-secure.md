# 3D-Secure SDK

## What is 3DS (3D-Secure)

## 3DS Version 1
## 3DS Version 2

## Installation
The 3DS-SDK is available in Omise iOS SDK

## Usage
### Authorizing Payment
##### Create an `3D-Secure service version 2 for authorization` by code
```swift
let authorizeURL = URL(string: "http://localhost:8080/payments/123456789/authorize")!
let expectedReturnURLPatterns = [URLComponents(string: "http://localhost:8080/charge/order")!]
let threeDSService = ThreeDSService()
threeDSService.doAuthorizePayment(challengeStatusReceiver: self, authorizeURL: authorizeURL, expectedReturnURLPatterns: expectedReturnURLPatterns)
```

#### Receive `3D-Secure version 2 Authorizing Payment` events via the delegate
```swift
extension ViewController: ThreeDSChallengeStatusReceiver {
  func completed(_ completionEvent: ThreeDSCompletionEvent) {
    // Called when the challenge process (that is, the transaction) is completed.
  }

  func cancelled() {
    // Called when the Cardholder selects the option to cancel the transaction on the challenge screen.
  }

  func timedout() {
    // Called when the challenge process reaches or exceeds the timeout interval.
  }

  func protocolError(_ protocolErrorEvent: ThreeDSProtocolErrorEvent) {
    // Called when the 3DS SDK receives an EMV 3-D Secure protocol-defined error message from the ACS.
  }

  func runtimeError(_ runtimeErrorEvent: ThreeDSRuntimeErrorEvent) {
    // Called when the 3DS SDK encounters errors during the challenge process. 
  }

  func throwbackToAuthorizeVersionOne(_ authorizeURI: String, _ expectedReturnURLPatterns: [URLComponents]) {
    // Called when the authorization flow don't support the 3d-secure version 2
  }
}
```

## How to config 3DS SDK version 2
#### Authorization UI Customization
#### Authorization Timeout

## How to handle result of Authorization
## How to check status of Omise Charge by Omise Token ID
