import UIKit

final class SplashViewController: UIViewController {
    
    private let showAuthenticationScreenSegueIdentifier = "ShowAuthenticationScreen"
    
    private let storage = OAuth2TokenStorage()
    private let profileService = ProfileService.shared
    private let profileImageService = ProfileImageService.shared
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setNeedsStatusBarAppearanceUpdate()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let token = storage.token {
            print("✅ [SplashViewController] Токен найден, загружаем профиль...")
            fetchProfile(token: token)
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
    
    private func fetchProfile(token: String) {
        UIBlockingProgressHUD.show()
        
        profileService.fetchProfile(token) { [weak self] result in
            UIBlockingProgressHUD.dismiss()
            
            guard let self = self else { return }
            
            switch result {
            case .success(let profile):
                print("✅ [SplashViewController] Профиль успешно загружен: \(profile.name)")
                self.fetchProfileImage(username: profile.username) {
                    UIBlockingProgressHUD.dismiss()
                    self.switchToTabBarController()
                }
                
            case .failure(let error):
                print("❌ [SplashViewController] Ошибка загрузки профиля: \(error.localizedDescription)")
                self.showErrorAlert(message: "Не удалось загрузить профиль. Проверьте подключение к интернету.")
            }
        }
    }
    
    private func fetchProfileImage(username: String, completion: @escaping () -> Void) {
            profileImageService.fetchProfileImageURL(username: username) { result in
                switch result {
                case .success(let avatarURL):
                    print("✅ [SplashViewController] Аватарка успешно загружена: \(avatarURL)")
                case .failure(let error):
                    print("❌ [SplashViewController] Ошибка загрузки аватарки: \(error.localizedDescription)")
                    // Не блокируем переход, даже если аватарка не загрузилась
                }
                completion()
            }
        }
    
    private func switchToTabBarController() {
        var window: UIWindow? = view.window
        
        if window == nil {
            guard let windowScene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else {
                assertionFailure("❌ [SplashViewController] Не удалось найти активную UIWindowScene")
                showErrorAlert(message: "Не удалось перейти на главный экран")
                return
            }
            window = windowScene.windows.first
        }
        
        guard let window = window else {
            assertionFailure("❌ [SplashViewController] Не удалось получить окно для смены rootViewController. Проверьте конфигурацию окон приложения.")
            showErrorAlert(message: "Не удалось перейти на главный экран")
            return
        }
        
        let tabBarController = UIStoryboard(name: "Main", bundle: .main)
            .instantiateViewController(withIdentifier: "TabBarViewController")
        
        window.rootViewController = tabBarController
        
        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: nil, completion: { _ in
            print("🏆 [SplashViewController] Переход на TabBarController выполнен успешно")
        })
    }
    
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(
            title: "Ошибка",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            guard let self = self else { return }
            
            if let token = self.storage.token {
                self.fetchProfile(token: token)
            } else {
                self.performSegue(withIdentifier: self.showAuthenticationScreenSegueIdentifier, sender: nil)
            }
        })
        present(alert, animated: true)
    }
}

// MARK: - AuthViewControllerDelegate
extension SplashViewController: AuthViewControllerDelegate {
    func didAuthenticate(_ vc: AuthViewController) {
        print("✅ [SplashViewController] Успешная авторизация")
        
        // Закрываем экран авторизации
        vc.dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            guard let token = self.storage.token else {
                print("❌ [SplashViewController] Токен не найден после авторизации")
                return
            }
            self.fetchProfile(token: token)
        }
    }
}
