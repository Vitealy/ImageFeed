import UIKit
import ProgressHUD

// MARK: - Delegate Protocol
protocol AuthViewControllerDelegate: AnyObject {
    func didAuthenticate(_ vc: AuthViewController)
}

// MARK: - AuthViewController
final class AuthViewController: UIViewController {
    
    // MARK: - Constants
    private let showWebViewSegueIdentifier = "ShowWebView"
    
    // MARK: - Properties
    private let oauth2Service = OAuth2Service.shared
    private let tokenStorage = OAuth2TokenStorage()
    
    weak var delegate: AuthViewControllerDelegate?
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == showWebViewSegueIdentifier {
            guard
                let webViewViewController = segue.destination as? WebViewViewController
            else {
                assertionFailure("Failed to prepare for \(showWebViewSegueIdentifier)")
                return
            }
            webViewViewController.delegate = self
        } else {
            super.prepare(for: segue, sender: sender)
        }
    }
    
}

extension AuthViewController: WebViewViewControllerDelegate {
    func webViewViewController(_ vc: WebViewViewController, didAuthenticateWithCode code: String) {
        
        print("🔄 [AuthViewController] Получен код авторизации: \(code)")
        
        vc.dismiss(animated: true)
        
        // Показываем индикатор загрузки
        UIBlockingProgressHUD.show()
        
        oauth2Service.fetchOAuthToken(code) { result in
            // Скрываем индикатор загрузки
            UIBlockingProgressHUD.dismiss()
            
            switch result {
            case .success(let token):
                print("✅ [AuthViewController] Токен успешно получен!")
                print("🔑 [AuthViewController] Токен: \(token.prefix(30))...")
                self.handleAuthSuccess(token: token)
                
            case .failure(let error):
                print("❌ [AuthViewController] Ошибка получения токена: \(error.localizedDescription)")
                self.handleAuthError(error)
            }
        }
    }
    
    func webViewViewControllerDidCancel(_ vc: WebViewViewController) {
        vc.dismiss(animated: true)
    }
    
    private func handleAuthSuccess(token: String) {
        
        if let savedToken = tokenStorage.token {
            print("💾 [AuthViewController] Токен сохранён в хранилище: \(savedToken.prefix(30))...")
        }
        print("🏆 Авторизация успешна! Токен: \(token.prefix(20))...")
        self.delegate?.didAuthenticate(self)
    }
    
    private func handleAuthError(_ error: Error) {
        print("❌ [AuthViewController] Ошибка получения токена: \(error.localizedDescription)")
        
        let alert = UIAlertController(
            title: "Что-то пошло не так(",
            message: "Не удалось войти в систему",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Ок", style: .default))
        present(alert, animated: true)
    }
}

