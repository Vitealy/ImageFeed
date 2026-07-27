import UIKit
import WebKit

//// MARK: - Сonstants
//enum WebViewConstants {
//    static let unsplashAuthorizeURLString = "https://unsplash.com/oauth/authorize"
//    
//}

// MARK: - Protocol
protocol WebViewViewControllerDelegate: AnyObject {
    func webViewViewController(_ vc: WebViewViewController, didAuthenticateWithCode code: String)
    func webViewViewControllerDidCancel(_ vc: WebViewViewController)
}

public protocol WebViewViewControllerProtocol: AnyObject {
    var presenter: WebViewPresenterProtocol? { get set }
    func load(request: URLRequest)
    func setProgressValue(_ newValue: Float)
    func setProgressHidden(_ isHidden: Bool)
}

// MARK: - WebView
final class WebViewViewController: UIViewController, WebViewViewControllerProtocol {
    
    // MARK: - IBOutlets
    @IBOutlet private var webView: WKWebView!
    @IBOutlet private var progressView: UIProgressView!
    
    // MARK: - Properties
    weak var delegate: WebViewViewControllerDelegate?
    private var estimatedProgressObservation: NSKeyValueObservation?
    var presenter: WebViewPresenterProtocol?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        print("✅ [WebViewViewController] viewDidLoad, webView = \(webView != nil ? "не nil" : "nil")")
        webView.navigationDelegate = self
        
        let request = URLRequest(url: URL(string: "https://unsplash.com")!)
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ URLSession: \(error)")
            } else {
                print("✅ URLSession: успех")
            }
        }
        task.resume()
        
        presenter?.viewDidLoad()
//        updateProgress()
        
        estimatedProgressObservation = webView.observe(
            \.estimatedProgress,
             options: []
        ) { [weak self] _, _ in
            guard let self = self else { return }
            self.presenter?.didUpdateProgressValue(self.webView.estimatedProgress)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
//        updateProgress()
    }
    
    // MARK: - Private Methods
//    private func updateProgress() {
//        progressView.progress = Float(webView.estimatedProgress)
//        progressView.isHidden = fabs(webView.estimatedProgress - 1) <= 0.0001
//    }
    
    func setProgressValue(_ newValue: Float) {
        progressView.progress = newValue
    }

    func setProgressHidden(_ isHidden: Bool) {
        progressView.isHidden = isHidden
    }
    
    func load(request: URLRequest) {
        print("✅ [WebViewViewController] load вызван с URL: \(request.url?.absoluteString ?? "nil")")
        webView.load(request)
    }
    
//    private func loadAuthView() {
//        guard var urlComponents = URLComponents(string: WebViewConstants.unsplashAuthorizeURLString) else {
//            return
//        }
//        
//        urlComponents.queryItems = [
//            URLQueryItem(name: "client_id", value:Constants.accessKey),
//            URLQueryItem(name: "redirect_uri", value: Constants.redirectURI),
//            URLQueryItem(name: "response_type", value: "code"),
//            URLQueryItem(name: "scope", value: Constants.accessScope)
//        ]
//        
//        guard let url = urlComponents.url else {
//            return
//        }
//        
//        let request = URLRequest(url: url)
//        webView.load(request)
//    }
    
}

// MARK: - Extension
extension WebViewViewController: WKNavigationDelegate {
    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        if let code = code(from: navigationAction) {
            delegate?.webViewViewController(self, didAuthenticateWithCode: code)
            decisionHandler(.cancel)
        } else {
            decisionHandler(.allow)
        }
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print("❌ [WebView] Ошибка загрузки: \(error.localizedDescription)")
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("✅ [WebView] Загрузка завершена")
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("❌ [WebView] Ошибка после начала загрузки: \(error)")
    }
    
    private func code(from navigationAction: WKNavigationAction) -> String? {
        
//        if
//            let url = navigationAction.request.url,
//            let urlComponents = URLComponents(string: url.absoluteString),
//            urlComponents.path == "/oauth/authorize/native",
//            let items = urlComponents.queryItems,
//            let codeItem = items.first(where: { $0.name == "code" })
//        {
//            return codeItem.value
//        } else {
//            return nil
//        }
        
        guard let url = navigationAction.request.url else { return nil }
        return presenter?.code(from: url)
    }
}
