# DRAFT
# 3D-Secure SDK

## What is 3DS (3D-Secure)

## 3DS Version 1
## 3DS Version 2

## Requirements
* Omise API public key. [Register for an Omise account](https://dashboard.omise.co/signup) to obtain your API keys.
* iOS 11 or higher deployment target.
* Xcode 10.0 or higher (Xcode 12.2 is recommended)
* Swift 5.0 or higher (Swift 5.3.1 is recommended)

## Installation
The 3DS-SDK is available in Omise iOS SDK or download directly from [OmiseThreeDSSDK]()

## Usage
### Authorizing Payment
##### Create an `3D-Secure service version 2 for authorization` by code
You can create an instance of `ThreeDSService` and set it with `authorized URL` given with the Omise Charge and `expected return URL` patterns those were created by merchants in the case. If your authorization cannot use 3D-Secure version 2, the SDK will throwback to the `throwbackToAuthorizeVersionOne` delegate method.
```swift
In ViewController

import OmiseSDK
import OmiseThreeDSSDK

let authorizeURL = URL(string: "http://localhost:8080/payments/123456789/authorize")!
let expectedReturnURLPatterns = [URLComponents(string: "http://localhost:8080/charge/order")!]
let omiseThreeDSService = OmiseThreeDSService()
omiseThreeDSService.doAuthorizePayment(challengeStatusReceiver: self, authorizeURL: authorizeURL, expectedReturnURLPatterns: expectedReturnURLPatterns)
```

#### Receive `3D-Secure version 2 Authorizing Payment` events via the delegate for handle result of Authorization
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
You can create your own theme for Authorization UI.
Omise SDK provides custom UI components to make it easier to custom your theme.
* `NavigationBar`
* `Label`
* `TextField`
* `Button`

##### NavigationBarCustomization
List of customizable elements on Authorization UI NavigationBar
* `textFont`
* `textColor`
* `backgroundColor`
* `headerText`
* `buttonText`

Create a NavigationBarCustomization
```swift
let navigationBarUICustomization = NavigationBarCustomization(textFont: UIFont?,
                                                                  textColor: UIColor?,
                                                                  backgroundColor: UIColor?,
                                                                  headerText: String?,
                                                                  buttonText: String?)
```

##### LabelCustomization
List of customizable elements on Authorization UI Label
* `textFont`
* `textColor`
* `headerTextFont`
* `headerTextColor`

Create a LabelCustomization
```swift
let labelUICustomization = LabelCustomization(textFont: UIFont?,
                                                textColor: UIColor?,
                                                headerTextFont: UIFont?,
                                                headerTextColor: UIColor?)
```

##### TextFieldCustomization
List of customizable elements on Authorization UI TextField
* `textFont`
* `textColor`
* `borderWidth`
* `borderColor`
* `cornerRadius`

Create a TextFieldCustomization
```swift
let textFieldUICustomization = TextFieldCustomization(textFont: UIFont?,
                                                      textColor: UIColor?,
                                                      borderWidth: CGFloat?,
                                                      borderColor: UIColor?,
                                                      cornerRadius: CGFloat?)
```

##### ButtonCustomization
List of customizable elements on Authorization UI Button
* `textFont`
* `textColor`
* `backgroundColor`
* `cornerRadius`

Create a ButtonCustomization
```swift
let buttonUICustomization = ButtonCustomization(textFont: UIFont?,
                                                textColor: UIColor?,
                                                backgroundColor: UIColor?,
                                                cornerRadius: CGFloat?)                                                
```

List of ButtonType
`submit`, `continue`, `next`, `cancel`, `resend`, `other(string)`


##### UICustomization
```swift
let uiCustomization = UICustomization(toolbarCustomization: NavigationBarCustomization?,
                                      labelCustomization: LabelCustomization?,
                                      textBoxCustomization: TextFieldCustomization?,
                                      buttonCustomizations: [ButtonType: ButtonCustomization])             
```
Then you can put UICustomize instance when initial `ThreeDSService`
```swift
let threeDSService = ThreeDSService(uiCustomization: uiCustomization)
```

#### Custom Authorization Timeout
Timeout interval (in minutes) within which the challenge process must be completed. The minimum timeout interval shall be 5 minutes in default.
```swift
// Use default timeout
let threeDSService = ThreeDSService()

// Use custom timeout. Ex. 2 minutes
let threeDSService = ThreeDSService(timeout: 2)
```

## How to check status of Omise Charge by Omise Token ID
We also prepare methods for checking `Charge` status by `OmiseTokenID`
```swift
import OmiseSDK

let client = OmiseSDK.Client.init(publicKey: "omise_public_key")
client.retrieveChargeStatusWithCompletionHandler(from tokenID: omiseTokenID, completionHandler: (((ChargeStatus, Error?)) -> Void)?) {
// Handle ChargeStatus or Error here
}

// Or use this method for polling (pull Charge status every 3 second until exceed the limit(10 times) or Charge status changed to Success or Failed)
client.observeChargeStatus(from tokenID: String,
                                updated: @escaping (ChargeStatus) -> Void,
                                failure: @escaping (Error) -> Void)

```
