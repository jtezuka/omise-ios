import UIKit
import ThreeDSSDK

public class AuthorizingPaymentUICustomization {
    public var customization: UICustomization?
    public init(
        navigationBarCustomization: AuthorizingPaymentNavigationBarCustomization? = nil,
        labelCustomization: AuthorizingPaymentLabelCustomization? = nil,
        textFieldCustomization: AuthorizingPaymentTextFieldCustomization? = nil,
        buttonCustomization: AuthorizingPaymentButtonCustomization? = nil
    ) {
        self.customization = UICustomization(toolbarCustomization: navigationBarCustomization?.value, labelCustomization: labelCustomization?.value, textBoxCustomization: textFieldCustomization?.value)
    }
}

public struct AuthorizingPaymentNavigationBarCustomization {
    public var value: NavigationBarCustomization?
    public init(
      textFont: UIFont? = nil, textColor: UIColor? = nil,
      backgroundColor: UIColor? = nil, headerText: String? = nil, buttonText: String? = nil
      ) {
        self.value = NavigationBarCustomization(textFont: textFont, textColor: textColor, backgroundColor: backgroundColor, headerText: headerText, buttonText: buttonText)
    }
}

public struct AuthorizingPaymentLabelCustomization {
    public var value: LabelCustomization?
    public init(
      textFont: UIFont? = nil, textColor: UIColor? = nil,
      headerTextFont: UIFont? = nil, headerTextColor: UIColor? = nil
      ) {
        self.value = LabelCustomization(textFont: textFont, textColor: textColor, headerTextFont: headerTextFont, headerTextColor: headerTextColor)
    }
}

public struct AuthorizingPaymentTextFieldCustomization {
    public var value: TextFieldCustomization?
    public init(
      textFont: UIFont? = nil, textColor: UIColor? = nil,
      borderWidth: CGFloat? = nil, borderColor: UIColor? = nil, cornerRadius: CGFloat? = nil
      ) {
        self.value = TextFieldCustomization(textFont: textFont, textColor: textColor, borderWidth: borderWidth, borderColor: borderColor, cornerRadius: cornerRadius)
    }
}

public struct AuthorizingPaymentButtonCustomization {
    public var value: ButtonCustomization?
}
