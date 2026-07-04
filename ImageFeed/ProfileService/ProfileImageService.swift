import Foundation

// MARK: - Constants
extension ProfileImageService {
    static let didChangeNotification = Notification.Name(rawValue: "ProfileImageProviderDidChange")
}

// MARK: - Models

/// Модель ответа от сервера Unsplash API для получения изображений профиля

struct UserResult: Codable, Sendable {
    let profileImage: ProfileImage
    
    enum CodingKeys: String, CodingKey {
        case profileImage = "profile_image"
    }
}

/// Модель для изображений профиля
struct ProfileImage: Codable, Sendable {
    let small: String
    let medium: String
    let large: String
}

// MARK: - ProfileImageService

final class ProfileImageService {
    
    // MARK: - Singleton
    static let shared = ProfileImageService()
    private init() {}
    
    // MARK: - Properties
    private let urlSession = URLSession.shared
    private var task: URLSessionTask?
    private let tokenStorage = OAuth2TokenStorage()
    private(set) var avatarURL: String?
    
    // MARK: - Private Methods
    
    /// Создаёт URLRequest для получения аватарки пользователя
    /// - Parameters:
    ///   - username: Имя пользователя
    ///   - token: Bearer токен авторизации
    /// - Returns: URLRequest или nil, если не удалось создать
    private func makeProfileImageRequest(username: String, token: String) -> URLRequest? {
        guard let url = URL(string: "\(Constants.defaultBaseURLString)/users/\(username)") else {
            print("❌ [ProfileImageService] Не удалось создать URL")
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return request
    }
    
    // MARK: - Public Methods
    
    /// Загружает URL аватарки пользователя
    /// - Parameters:
    ///   - username: Имя пользователя
    ///   - completion: Замыкание с результатом (String URL или Error)
    func fetchProfileImageURL(username: String, completion: @escaping (Result<String, Error>) -> Void) {
        assert(Thread.isMainThread)
        
        // Отменяем предыдущий запрос
        task?.cancel()
        
        // Проверяем наличие токена
        guard let token = tokenStorage.token else {
            print("❌ [ProfileImageService] Токен не найден")
            completion(.failure(NetworkError.unauthorized))
            return
        }
        
        // Создаём запрос
        guard let request = makeProfileImageRequest(username: username, token: token) else {
            print("❌ [ProfileImageService] Не удалось создать запрос")
            completion(.failure(NetworkError.invalidRequest))
            return
        }
        
        print("📡 [ProfileImageService] Отправка запроса на получение аватарки для пользователя: \(username)...")
        
        let task = urlSession.objectTask(for: request) { [weak self] (result: Result<UserResult, Error>) in
            defer {
                DispatchQueue.main.async {
                    self?.task = nil
                }
            }
            
            guard let self = self else { return }
            
            switch result {
            case .success(let userResult):
                let avatarURL = userResult.profileImage.large
                self.avatarURL = avatarURL
                
                print("✅ [ProfileImageService] Аватарка успешно получена: \(avatarURL)")
                
                // ✅ ОТПРАВЛЯЕМ НОТИФИКАЦИЮ
                NotificationCenter.default.post(
                    name: ProfileImageService.didChangeNotification,
                    object: self,
                    userInfo: ["URL": avatarURL]
                )
                
                completion(.success(avatarURL))
                
            case .failure(let error):
                print("❌ [ProfileImageService] Ошибка: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
        
        self.task = task
        task.resume()
    }
}
