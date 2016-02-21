//
//  ClimateWebViewController.swift
//  Pods
//
//  Created by Tommy Rogers on 1/21/16.
//
//

import Foundation
import UIKit

protocol AuthorizationCodeDelegate {
    func didGetAuthorizationCode(code: String)
}

class ClimateWebViewController: UIViewController, UIWebViewDelegate {

    @IBOutlet var webView: UIWebView!

    var delegate: AuthorizationCodeDelegate?
    var oidc: OIDC!

    override func viewDidLoad() {
        webView.delegate = self

        let loginPageURLWithParams = self.oidc.loginPageURLWithParams()
        webView.loadRequest(NSURLRequest(URL: loginPageURLWithParams))
//        webView.scrollView.scrollEnabled = false
    }

    @IBAction func cancel(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    func webViewDidStartLoad(webView: UIWebView) {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
    }

    func webViewDidFinishLoad(webView: UIWebView) {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
    }

    func webView(webView: UIWebView, didFailLoadWithError error: NSError?) {
        // We are sure to get these errors when we prevent the redirect in shouldStartLoadWithRequest
        if (error?.code == NSURLErrorCancelled || error?.code == 102 || error?.code == 101) {
            return
        }

        print("Webview failed to load with error: \(error)")
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
    }

    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        print(request)

        // TODO can this all happen on this thread before returning?
        if let url = request.URL {
            if (self.oidc.isRedirectURL(url)) {
                self.dismissViewControllerAnimated(true, completion: nil)
                if let queryItems = NSURLComponents(URL: url, resolvingAgainstBaseURL: false)?.queryItems {
                    var queryParamDictionary = [String: String]()
                    queryItems.forEach({(item: NSURLQueryItem) in
                        queryParamDictionary[item.name] = item.value
                    })

                    if let code = queryParamDictionary["code"] {
                        self.delegate?.didGetAuthorizationCode(code)
                    } else {
                        // TODO error callback
                        print("Did not get an authorization code in redirect: \(request.URL)")
                    }
                }
            }
        }

        return true
    }

}