import UIKit

final class SplashViewController: UIViewController {
    
    // MARK: - Properties
    
    private let storage = OAuth2TokenStorage()
    private let profileService = ProfileService.shared
    private let profileImageService = ProfileImageService.shared
    
    private var imageView: UIImageView!
    
    // MARK: - Lifecycle
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setNeedsStatusBarAppearanceUpdate()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .ypBlack
        setupImageView()
        print("✅ [SplashViewController] viewDidLoad вызван")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let token = storage.token {
            print("✅ [SplashViewController] Токен найден, загружаем профиль...")
            fetchProfile(token: token)
        } else {
            print("🔄 [SplashViewController] Токен не найден, переход на экран авторизации")
            presentAuthViewController()
        }
    }
    
    // MARK: - Navigation
    
    private func presentAuthViewController() {
        let storyboard = UIStoryboard(name: "Main", bundle: .main)
        guard let authViewController = storyboard.instantiateViewController(
            withIdentifier: "AuthViewController"
        ) as? AuthViewController else {
            assertionFailure("Не удалось найти AuthViewController по идентификатору")
            return
        }
        authViewController.delegate = self
        authViewController.modalPresentationStyle = .fullScreen
        present(authViewController, animated: true)
    }
    
    // MARK: - Private Methods
    
    private func setupImageView() {
        let splashImage = UIImage(named: "splash_screen_logo")
        imageView = UIImageView(image: splashImage)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)
        
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func fetchProfile(token: String) {
        
        UIBlockingProgressHUD.show()
        
        profileService.fetchProfile(token) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let profile):
                print("✅ [SplashViewController] Профиль успешно загружен: \(profile.name)")
                self.profileImageService.fetchProfileImageURL(username: profile.username) { _ in
                    UIBlockingProgressHUD.dismiss()
                    self.switchToTabBarController()
                }
                
            case .failure(let error):
                UIBlockingProgressHUD.dismiss()
                print("❌ [SplashViewController] Ошибка загрузки профиля: \(error.localizedDescription)")
                self.showErrorAlert(message: "Не удалось загрузить профиль. Проверьте подключение к интернету.")
            }
        }
    }
    
    private func switchToTabBarController() {
        
        guard let window = view.window else {
            print("❌ [SplashViewController] window not found")
            return
        }
        
        let tabBarController = TabBarController()
        window.rootViewController = tabBarController
        
        UIView.transition(
            with: window,
            duration: 0.3,
            options: .transitionCrossDissolve,
            animations: nil
        )
        print("🏆 [SplashViewController] Переход на TabBarController выполнен")
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
                self.presentAuthViewController()
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
