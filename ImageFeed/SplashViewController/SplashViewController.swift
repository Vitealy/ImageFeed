import UIKit

final class SplashViewController: UIViewController {
    
    private let showAuthenticationScreenSegueIdentifier = "ShowAuthenticationScreen"
    
    private let storage = OAuth2TokenStorage()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setNeedsStatusBarAppearanceUpdate()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if storage.token != nil {
            print("✅ [SplashViewController] Токен найден, переход в галерею")
            switchToTabBarController()
        } else {
            print("🔄 [SplashViewController] Токен не найден, переход на экран авторизации")
            performSegue(withIdentifier: showAuthenticationScreenSegueIdentifier, sender: nil)
        }
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == showAuthenticationScreenSegueIdentifier {
            
            guard
                let navigationController = segue.destination as? UINavigationController,
                let authViewController = navigationController.viewControllers.first as? AuthViewController
            else {
                assertionFailure("Failed to prepare for \(showAuthenticationScreenSegueIdentifier)")
                return
            }
            
            authViewController.delegate = self
        } else {
            super.prepare(for: segue, sender: sender)
        }
    }
    
    // MARK: - Private Methods
    private func switchToTabBarController() {
        var window: UIWindow? = view.window
        
        if window == nil {
            guard let windowScene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else {
                assertionFailure("❌ [SplashViewController] Не удалось найти активную UIWindowScene")
                return
            }
            window = windowScene.windows.first
        }
        
        guard let window = window else {
            assertionFailure("❌ [SplashViewController] Не удалось получить окно для смены rootViewController. Проверьте конфигурацию окон приложения.")
            return
        }
        
        let tabBarController = UIStoryboard(name: "Main", bundle: .main)
            .instantiateViewController(withIdentifier: "TabBarViewController")
        
        window.rootViewController = tabBarController
        
        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: nil, completion: { _ in
            print("🏆 [SplashViewController] Переход на TabBarController выполнен успешно")
        })
    }
    
}

// MARK: - AuthViewControllerDelegate
extension SplashViewController: AuthViewControllerDelegate {
    func didAuthenticate(_ vc: AuthViewController) {
        print("✅ [SplashViewController] Успешная авторизация, закрываем AuthViewController и переходим в галерею")
        
        // Закрываем экран авторизации
        vc.dismiss(animated: true) { [weak self] in
            // После закрытия переходим в галерею
            self?.switchToTabBarController()
        }
    }
}
