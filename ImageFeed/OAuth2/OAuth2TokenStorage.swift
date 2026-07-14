import Foundation
import SwiftKeychainWrapper

final class OAuth2TokenStorage {
    
    // MARK: - Constants
    
    //    private let userDefaults = UserDefaults.standard
    private let tokenKey = "bearerToken"
    
    // MARK: - Properties
    
    var token: String? {
        get {
            //            return userDefaults.string(forKey: tokenKey)
            return KeychainWrapper.standard.string(forKey: tokenKey)
        }
        set {
            //            userDefaults.set(newValue, forKey: tokenKey)
            if let newValue = newValue {
                let isSuccess = KeychainWrapper.standard.set(newValue, forKey: tokenKey)
                if isSuccess {
                    print("💾 [OAuth2TokenStorage] Токен успешно сохранён в Keychain")
                } else {
                    print("❌ [OAuth2TokenStorage] Не удалось сохранить токен в Keychain")
                }
            } else {
                // Удаляем токен из Keychain
                let isRemoved = KeychainWrapper.standard.removeObject(forKey: tokenKey)
                if isRemoved {
                    print("🗑️ [OAuth2TokenStorage] Токен удалён из Keychain")
                } else {
                    print("❌ [OAuth2TokenStorage] Не удалось удалить токен из Keychain")
                }
            }
        }
    }
    
    func clearToken() {
//        userDefaults.removeObject(forKey: tokenKey)
        token = nil 
    }
}
