import UIKit

final class AuthViewController: UIViewController {
    private let showWebViewSegueIdentifier = "ShowWebView"
    private let oauth2Service = OAuth2Service.shared
    private let tokenStorage = OAuth2TokenStorage()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
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
        oauth2Service.fetchOAuthToken(code) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let token):
                print("✅ [AuthViewController] Токен успешно получен!")
                print("🔑 [AuthViewController] Токен: \(token.prefix(30))...")
                // TODO: Сохранить токен и перейти на следующий экран
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
        // TODO: Сохранить токен в Keychain или UserDefaults
        // TODO: Перейти на главный экран приложения
        if let savedToken = tokenStorage.token {
            print("💾 [AuthViewController] Токен сохранён в хранилище: \(savedToken.prefix(30))...")
        }
        print("🏆 Авторизация успешна! Токен: \(token.prefix(20))...")
        
        // Закрываем WebView и возвращаемся на экран авторизации
        dismiss(animated: true) {
            // TODO: Показать главный экран
        }
    }
    
    private func handleAuthError(_ error: Error) {
            // TODO: Показать алерт с ошибкой
            let alert = UIAlertController(
                title: "Ошибка авторизации",
                message: "Не удалось получить токен. Попробуйте ещё раз.\n\(error.localizedDescription)",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
}

