import Foundation
import WebKit
import os
import ThreeDSSDK


/// Delegate to receive authorizing payment events.
public protocol AuthorizingPaymentViewControllerDelegate: AnyObject {
    /// A delegation method called when the authorizing payment process is completed.
    /// - parameter viewController: The authorizing payment controller that call this method
    /// - parameter redirectedURL: A URL returned from the authorizing payment process.
    func authorizingPaymentViewController(_ viewController: AuthorizingPaymentViewController, didCompleteAuthorizingPaymentWithRedirectedURL redirectedURL: URL)
    /// A delegation method called when user cancel the authorizing payment process.
    func authorizingPaymentViewControllerDidCancel(_ viewController: AuthorizingPaymentViewController)
}

/// Delegate to receive new version of authorizing payment events.
public protocol AuthorizingPaymentDelegate: AnyObject {
    func didCompleted(transactionID: String, transactionStatus: String)
    func didCancelled()
    func didTimedout()
    func didError(error: Error)
    func didThrowbackAuthorizeToVersionOne(authorizeURI: String, expectedReturnURLPatterns: [URLComponents])
}


/*:
 Drop-in authorizing payment handler view controller that automatically display the authorizing payment verification form
 which supports `3DS`, `Internet Banking` and other offsite payment methods those need to be authorized via a web browser.
 
 - remark:
   This is still an experimental API. If you encountered with any problem with this API, please feel free to report to Omise.
 */
public class AuthorizingPaymentViewController: UIViewController {
    /// Authorized URL given from Omise in the created `Charge` object.
    public var authorizedURL: URL? {
        didSet {
            guard isViewLoaded else {
                return
            }
            
            startAuthorizingPaymentProcess()
        }
    }
    
    /// The expected return URL patterns described in the URLComponents object.
    ///
    /// The rule is the scheme and host must be matched and must have the path as a prefix.
    /// Example: if the return URL is `https://www.example.com/products/12345` the expected return URL should have a URLComponents with scheme of `https`, host of `www.example.com` and the path of `/products/`
    public var expectedReturnURLPatterns: [URLComponents] = []
    
    /// A delegate object that will recieved the authorizing payment events.
    public weak var delegate: AuthorizingPaymentViewControllerDelegate?
    
    let webView: WKWebView = WKWebView(frame: CGRect.zero, configuration: WKWebViewConfiguration())
    
    
    /// A factory method for creating a authorizing payment view controller comes in UINavigationController stack.
    ///
    /// - parameter authorizedURL: The authorized URL given in `Charge` object that will be set to `OmiseAuthorizingPaymentViewController`
    /// - parameter expectedReturnURLPatterns: The expected return URL patterns.
    /// - parameter delegate: A delegate object that will recieved authorizing payment events.
    ///
    /// - returns: A UINavigationController with `OmiseAuthorizingPaymentViewController` as its root view controller
    public static func makeAuthorizingPaymentViewControllerNavigationWithAuthorizedURL(_ authorizedURL: URL, expectedReturnURLPatterns: [URLComponents], delegate: AuthorizingPaymentViewControllerDelegate) -> UINavigationController {
        let storyboard = UIStoryboard(name: "OmiseSDK", bundle: Bundle(for: AuthorizingPaymentViewController.self))
        let navigationController = storyboard.instantiateViewController(withIdentifier: "DefaultAuthorizingPaymentViewControllerWithNavigation") as! UINavigationController
        let viewController = navigationController.topViewController as! AuthorizingPaymentViewController
        viewController.authorizedURL = authorizedURL
        viewController.expectedReturnURLPatterns = expectedReturnURLPatterns
        viewController.delegate = delegate
        
        return navigationController
    }

    /// A factory method for creating a authorizing payment view controller comes in UINavigationController stack.
    ///
    /// - parameter authorizedURL: The authorized URL given in `Charge` object that will be set to `OmiseAuthorizingPaymentViewController`
    /// - parameter expectedReturnURLPatterns: The expected return URL patterns.
    /// - parameter delegate: A delegate object that will recieved authorizing payment events.
    ///
    /// - returns: An `OmiseAuthorizingPaymentViewController` with given authorized URL and delegate.
    public static func makeAuthorizingPaymentViewControllerWithAuthorizedURL(_ authorizedURL: URL, expectedReturnURLPatterns: [URLComponents], delegate: AuthorizingPaymentViewControllerDelegate) -> AuthorizingPaymentViewController {
        let storyboard = UIStoryboard(name: "OmiseSDK", bundle: Bundle(for: AuthorizingPaymentViewController.self))
        let viewController = storyboard.instantiateViewController(withIdentifier: "DefaultAuthorizingPaymentViewController") as! AuthorizingPaymentViewController
        viewController.authorizedURL = authorizedURL
        viewController.expectedReturnURLPatterns = expectedReturnURLPatterns
        viewController.delegate = delegate
        
        return viewController
    }

    public override func loadView() {
        super.loadView()
        
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)
        
        webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        webView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        webView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        webView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        webView.navigationDelegate = self
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startAuthorizingPaymentProcess()
    }
    
    @IBAction func cancelAuthorizingPaymentProcess(_ sender: UIBarButtonItem) {
        os_log("Authorization process was cancelled, trying to notify the delegate", log: uiLogObject, type: .info)
        delegate?.authorizingPaymentViewControllerDidCancel(self)
        if delegate == nil {
            os_log("Authorization process was cancelled but no delegate to be notified", log: uiLogObject, type: .default)
        }
    }
    
    private func startAuthorizingPaymentProcess() {
        guard let authorizedURL = authorizedURL, !expectedReturnURLPatterns.isEmpty else {
            assertionFailure("Insufficient authorizing payment information")
            os_log("Refusing to initialize sdk client with a non-public key: %{private}@", log: uiLogObject, type: .error)
            return
        }
        os_log("Starting the authorizing process with %{private}@ URL", log: uiLogObject, type: .info, authorizedURL.absoluteString)
        let request = URLRequest(url: authorizedURL, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 60.0)
        webView.load(request)
    }
    
    private func verifyPaymentURL(_ url: URL) -> Bool {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            return false
        }
        
        return expectedReturnURLPatterns.contains(where: { expectedURLComponents -> Bool in
            return expectedURLComponents.scheme == components.scheme && expectedURLComponents.host == components.host && components.path.hasPrefix(expectedURLComponents.path)
        })
    }
    
}

extension AuthorizingPaymentViewController: WKNavigationDelegate {
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Swift.Void) {
        if let url = navigationAction.request.url, verifyPaymentURL(url) {
            os_log("Redirected to expected %{private}@ URL, trying to notify the delegate", log: uiLogObject, type: .info, url.absoluteString)
            decisionHandler(.cancel)
            delegate?.authorizingPaymentViewController(self, didCompleteAuthorizingPaymentWithRedirectedURL: url)
            if delegate == nil {
                os_log("Redirected to expected %{private}@ URL but no delegate to be notified", log: uiLogObject, type: .default, url.absoluteString)
            }
        } else {
            os_log("Redirected to non-expected %{private}@ URL", log: uiLogObject, type: .debug, navigationAction.request.url?.absoluteString ?? "<empty>")
            decisionHandler(.allow)
        }
    }
}


// MARK: For testing with new 3DS-V2
extension AuthorizingPaymentViewController {
    public struct OmiseChallengeStatusReceiver: ThreeDSChallengeStatusReceiver {
        let authorizingPaymentDelegate: AuthorizingPaymentDelegate
        init(authorizingPaymentDelegate: AuthorizingPaymentDelegate) {
            self.authorizingPaymentDelegate = authorizingPaymentDelegate
        }
        
        public func completed(_ completionEvent: ThreeDSCompletionEvent) {
            print("OmiseSDK - OmiseChallengeStatusReceiver : complete")
            authorizingPaymentDelegate.didCompleted(transactionID: completionEvent.getSDKTransactionID(), transactionStatus: completionEvent.getTransactionStatus())
        }
        
        public func cancelled() {
            print("OmiseSDK - OmiseChallengeStatusReceiver : cancelled")
            authorizingPaymentDelegate.didCancelled()
        }
        
        public func timedout() {
            print("OmiseSDK - OmiseChallengeStatusReceiver : timedout")
            authorizingPaymentDelegate.didTimedout()
        }
        
        public func protocolError(_ protocolErrorEvent: ThreeDSProtocolErrorEvent) {
            print("OmiseSDK - OmiseChallengeStatusReceiver : protocolError")
            dump(protocolErrorEvent)
            authorizingPaymentDelegate.didError(error: OmiseError.unexpected(error: OmiseError.UnexpectedError.other(protocolErrorEvent.getErrorMessage().getErrorDescription()), underlying: nil))
        }
        
        public func runtimeError(_ runtimeErrorEvent: ThreeDSRuntimeErrorEvent) {
            print("OmiseSDK - OmiseChallengeStatusReceiver : runtimeError")
            dump(runtimeErrorEvent)
            authorizingPaymentDelegate.didError(error: OmiseError.unexpected(error: OmiseError.UnexpectedError.other(runtimeErrorEvent.getErrorMessage()), underlying: nil))
        }
        
        public func throwbackToAuthorizeVersionOne(_ authorizeURI: String, _ expectedReturnURLPatterns: [URLComponents]) {
            print("OmiseSDK - OmiseChallengeStatusReceiver : throwbackToAuthorizeVersionOne \(authorizeURI)")
            authorizingPaymentDelegate.didThrowbackAuthorizeToVersionOne(authorizeURI: authorizeURI, expectedReturnURLPatterns: expectedReturnURLPatterns)
        }
    }
    
    public static func makeAuthorizingPayment(_ currentViewController: UIViewController,
                                              omiseTokenID: String,
                                              authorizeURL: URL,
                                              expectedReturnURLPatterns: [URLComponents],
                                              delegate: AuthorizingPaymentDelegate,
                                              uiCustomization: UICustomization? = nil) {
        print("OmiseSDK call 3DS-SDK to makeAuthorizingPayment on \(authorizeURL.absoluteString)")
        let challengeStatusReceiver = OmiseChallengeStatusReceiver(authorizingPaymentDelegate: delegate)
        let navigationBarCustomization = NavigationBarCustomization(textFont: UIFont.italicSystemFont(ofSize: 22), textColor: .blue, backgroundColor: .brown, headerText: "xSecurex", buttonText: "Bacxx")
        let submitButtonCustomization = ButtonCustomization(textFont: UIFont.italicSystemFont(ofSize: 12), textColor: .blue, backgroundColor: .magenta, cornerRadius: 10)
        let resendButtonCustomization = ButtonCustomization(textFont: UIFont.italicSystemFont(ofSize: 12), textColor: .green, backgroundColor: .black, cornerRadius: 12)
        let continueButtonCustomization = ButtonCustomization(textFont: UIFont.italicSystemFont(ofSize: 12), textColor: .orange, backgroundColor: .blue, cornerRadius: 14)
        let labelCustomization = LabelCustomization(textFont: UIFont.italicSystemFont(ofSize: 14), textColor: .orange, headerTextFont: UIFont.boldSystemFont(ofSize: 18), headerTextColor: .magenta)
        let textBoxCustomization = TextFieldCustomization(textFont: UIFont.boldSystemFont(ofSize: 10), textColor: .cyan, borderWidth: 4, borderColor: .red, cornerRadius: 0)

        var uiCustomization = UICustomization(toolbarCustomization: navigationBarCustomization,
                                              labelCustomization: labelCustomization,
                                              textBoxCustomization: textBoxCustomization)

        uiCustomization.setButtonCustomization(submitButtonCustomization, for: .submit)
        uiCustomization.setButtonCustomization(resendButtonCustomization, for: .resend)
        uiCustomization.setButtonCustomization(continueButtonCustomization, for: .continue)

        let threeDSService = ThreeDSService(locale: nil, uiCustomization: uiCustomization)
        threeDSService.doAuthorizePayment(challengeStatusReceiver: challengeStatusReceiver, authorizeURL: authorizeURL, expectedReturnURLPatterns: expectedReturnURLPatterns)
    }
}

