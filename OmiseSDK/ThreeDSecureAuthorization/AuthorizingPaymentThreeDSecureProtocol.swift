import Foundation
import ThreeDSSDK

/// Delegate to receive authorizing payment 3D Secure version 2 events
@objc(OMSAuthorizingPaymentThreeDSecureDelegate)
public protocol AuthorizingPaymentThreeDSecureDelegate: AnyObject {
    /// A delegation method called when the 3D Secure version 2 authorizing payment process is completed.
    func authorizingPaymentThreeDSecureDidCompleted(transactionID: String, transactionStatus: String)

    /// A delegation method called when user cancel the 3D Secure version 2 authorizing payment process.
    func authorizingPaymentThreeDSecureDidCancelled()

    /// A delegation method called when the 3D Secure version 2 authorizing payment process is timedout.
    func authorizingPaymentThreeDSecureDidTimedout()

    /// A delegation method called when the 3D Secure version 2 authorizing payment process is error.
    func authorizingPaymentThreeDSecureDidError(error: Error)

    /// A delegation method called when the 3D Secure version 2 authorizing payment process is throwback to 3D Secure version 1.
    func authorizingPaymentThreeDSecureDidThrowbackAuthorizeWithAuthorizedURL(authorizedURL: URL, expectedReturnURLPatterns: [URLComponents])
}

/*:
 Drop-in authorizing payment handler authorize UI that automatically display the authorizing payment verication form which support `3DS Version 2`.
 */
@objc(OMSAuthorizingPayment)
public class AuthorizingPayment: NSObject {
    public struct OmiseChallengeStatusReceiver: ThreeDSChallengeStatusReceiver {
        weak var delegate: AuthorizingPaymentThreeDSecureDelegate?
        init(delegate: AuthorizingPaymentThreeDSecureDelegate) {
            self.delegate = delegate
        }

        public func completed(_ completionEvent: ThreeDSCompletionEvent) {
            delegate?.authorizingPaymentThreeDSecureDidCompleted(transactionID: completionEvent.getSDKTransactionID(), transactionStatus: completionEvent.getTransactionStatus())
        }

        public func cancelled() {
            delegate?.authorizingPaymentThreeDSecureDidCancelled()
        }

        public func timedout() {
            delegate?.authorizingPaymentThreeDSecureDidTimedout()
        }

        public func protocolError(_ protocolErrorEvent: ThreeDSProtocolErrorEvent) {
            delegate?.authorizingPaymentThreeDSecureDidError(error: OmiseError.unexpected(error: OmiseError.UnexpectedError.other(protocolErrorEvent.getErrorMessage().getErrorDescription()), underlying: nil))
        }

        public func runtimeError(_ runtimeErrorEvent: ThreeDSRuntimeErrorEvent) {
            delegate?.authorizingPaymentThreeDSecureDidError(error: OmiseError.unexpected(error: OmiseError.UnexpectedError.other(runtimeErrorEvent.getErrorMessage()), underlying: nil))
        }

        public func throwbackToAuthorizeVersionOne(_ authorizeURI: String, _ expectedReturnURLPatterns: [URLComponents]) {
            guard let authorizedURL = URL(string: authorizeURI) else {
                delegate?.authorizingPaymentThreeDSecureDidError(error: OmiseError.unexpected(error: OmiseError.UnexpectedError.other("Incorrect authorize URI"), underlying: nil))
                return
            }

            delegate?.authorizingPaymentThreeDSecureDidThrowbackAuthorizeWithAuthorizedURL(authorizedURL: authorizedURL, expectedReturnURLPatterns: expectedReturnURLPatterns)
        }
    }

    /// A factory method for creating a authorizing payment view for 3D Secure version 2
    ///
    /// - parameter authorizedURL: The authorized URL given in `Charge` object
    /// - parameter expectedReturnURLPatterns: The expected return URL patterns.
    /// - parameter delegate: A delegate object that will recieved authorizing payment events.
    /// - parameter locale: A locale representing the user's region settings
    /// - parameter uiCustomization: UI component for customize authorization UI
    ///
    public static func makeAuthorizingPaymentWithAuthorizedURL(_ authorizeURL: URL, expectedReturnURLPatterns: [URLComponents], delegate: AuthorizingPaymentThreeDSecureDelegate, locale: Locale? = nil, uiCustomization: UICustomization? = nil) {
        let challengeStatusReceiver = OmiseChallengeStatusReceiver(delegate: delegate)
        let threeDSService = ThreeDSService(locale: locale, uiCustomization: uiCustomization)
        threeDSService.doAuthorizePayment(challengeStatusReceiver: challengeStatusReceiver, authorizeURL: authorizeURL, expectedReturnURLPatterns: expectedReturnURLPatterns)
    }
}

