//
//  LoginWithClimateButton.swift
//  Pods
//
//  Created by Tommy Rogers on 1/21/16.
//
//

import Foundation
import UIKit

public protocol LoginWithClimateDelegate {
    func didLoginWithClimate(session: Session)
    func userDidCancelLoginWithClimate()
    func didFailLoginWithClimateWithError(error: NSError)
}

public extension LoginWithClimateDelegate {
    func userDidCancelLoginWithClimate() {}
    func didFailLoginWithClimateWithError(error: NSError) {}
}

public class LoginWithClimateButton: UIViewController, AuthorizationCodeDelegate {

    let oidc: OIDC
    public var delegate: LoginWithClimateDelegate?

    public init(clientId: String, clientSecret: String) {
        self.oidc = OIDC(clientId: clientId, clientSecret: clientSecret)
        super.init(nibName: nil, bundle: nil)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("NSCoding not supported")
    }

    func resourceBundle() -> NSBundle? {
        if let url = NSBundle(forClass: self.dynamicType).URLForResource("LoginWithClimate", withExtension: "bundle") {
            return NSBundle(URL: url)
        } else {
            return nil
        }
    }

    override public func loadView() {
        guard let img: UIImage = UIImage.init(named: "LoginWithClimateButton",
            // Cocoapods doesn't yet support asset catalogs inside resource bundle.
            inBundle: NSBundle(forClass: self.dynamicType),
            compatibleWithTraitCollection: nil) else {
                print("ERROR: Fatal error in LoginWithClimate. Could not locate button image.")
                view = UIView() // To avoid crashing the whole app when we can't load.

                return
        }

        let button = UIButton(type: .Custom)
        button.setImage(img, forState: .Normal)
        button.imageView?.contentMode = .ScaleAspectFit
        button.addTarget(self, action: "loginWithClimate:", forControlEvents: .TouchUpInside)

        view = button
    }

    func loginWithClimate(sender: AnyObject) {
        print("Beginning LoginWithClimate")

        guard let bundle = resourceBundle() else {
            print("ERROR: Fatal error in LoginWithClimate. Could not locate nested resource bundle with storyboard file.")
            return
        }

        let storyboard = UIStoryboard(name: "Login", bundle: bundle)

        if let rootViewController = storyboard.instantiateInitialViewController() as? UINavigationController {
            if let webViewController = rootViewController.topViewController as? ClimateWebViewController {
                webViewController.delegate = self
                webViewController.oidc = self.oidc
            } else {
                print("ERROR: not a ClimateWebViewController.")
            }
            self.presentViewController(rootViewController, animated: true, completion: nil)
        } else {
            print("ERROR: Failed to segue.")
        }
    }

    func didGetAuthorizationCode(code: String) {
        self.oidc.requestAuthToken(authorizationCode: code, onComplete: {
            (session: Session) in
            self.delegate?.didLoginWithClimate(session)
        })
    }
    
 
}