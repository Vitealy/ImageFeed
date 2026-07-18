import UIKit
import WebKit

final class ProfileLogoutService {
    
    // MARK: - Singleton
    
    static let shared = ProfileLogoutService()
    private init() {}

    // MARK: - Public Methods
    
    func logout() {
        cleanCookies()
        clearToken()
        resetServices()
        switchToSplashScreen()
    }

    // MARK: - Private Methods

    /// Очищает все куки и данные веб-хранилища
    private func cleanCookies() {
        // Очищаем все куки из хранилища
        HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)

        // Удаляем все данные из локального хранилища WebKit
        WKWebsiteDataStore.default().fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
            records.forEach { record in
                WKWebsiteDataStore.default().removeData(
                    ofTypes: record.dataTypes,
                    for: [record],
                    completionHandler: {}
                )
            }
        }
        print("🗑️ [ProfileLogoutService] Куки и веб-данные очищены")
    }

    /// Удаляет токен из Keychain
    private func clearToken() {
        let storage = OAuth2TokenStorage()
        storage.clearToken()
        print("🗑️ [ProfileLogoutService] Токен удалён из Keychain")
    }

    /// Сбрасывает данные всех сервисов
    private func resetServices() {
        // ProfileService
        ProfileService.shared.reset()

        // ProfileImageService
        ProfileImageService.shared.reset()

        // ImagesListService
        ImagesListService.shared.reset()

        print("🗑️ [ProfileLogoutService] Данные сервисов сброшены")
    }

    /// Переключает на SplashViewController
    private func switchToSplashScreen() {
        guard let windowScene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive }),
                let window = windowScene.windows.first
            else {
                print("❌ [ProfileLogoutService] Не удалось получить окно")
                return
            }

        let splashViewController = SplashViewController()
        window.rootViewController = splashViewController
        window.makeKeyAndVisible()

        UIView.transition(
            with: window,
            duration: 0.3,
            options: .transitionCrossDissolve,
            animations: nil
        )
        print("🏆 [ProfileLogoutService] Переключено на SplashViewController")
    }
}
