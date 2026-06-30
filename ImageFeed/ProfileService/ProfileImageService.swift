import Foundation


// MARK: - Models

/// Модель ответа от сервера Unsplash API для получения изображений профиля
struct UserResult: Codable, @unchecked Sendable {
    let profileImage: ProfileImage
    
    enum CodingKeys: String, CodingKey {
        case profileImage = "profile_image"
    }
}

/// Модель для изображений профиля
struct ProfileImage: Codable, @unchecked Sendable {
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
    
    // MARK: - Public Methods
    
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
        
        let task = urlSession.dataTask(with: request) { [weak self] data, response, error in
            defer {
                DispatchQueue.main.async {
                    self?.task = nil
                }
            }
            
            // Проверяем ошибку сети
            if let error = error {
                print("❌ [ProfileImageService] Сетевая ошибка: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            // Проверяем HTTP статус
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 [ProfileImageService] HTTP статус код: \(httpResponse.statusCode)")
                
                guard 200..<300 ~= httpResponse.statusCode else {
                    print("❌ [ProfileImageService] Ошибка сервера: HTTP \(httpResponse.statusCode)")
                    DispatchQueue.main.async {
                        completion(.failure(NetworkError.httpStatusCode(httpResponse.statusCode)))
                    }
                    return
                }
            }
            
            // Проверяем наличие данных
            guard let data = data else {
                print("❌ [ProfileImageService] Данные не получены")
                DispatchQueue.main.async {
                    completion(.failure(NetworkError.noData))
                }
                return
            }
            
            // Декодируем ответ
            do {
                let decoder = JSONDecoder()
                let userResult = try decoder.decode(UserResult.self, from: data)
                
                // Сохраняем URL аватарки
                let avatarURL = userResult.profileImage.large
                self?.avatarURL = avatarURL
                
                print("✅ [ProfileImageService] Аватарка успешно получена: \(avatarURL)")
                
                DispatchQueue.main.async {
                    completion(.success(avatarURL))
                }
            } catch {
                print("❌ [ProfileImageService] Ошибка декодирования: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
        
        self.task = task
        task.resume()
    }
}

// MARK: - Network Error
extension ProfileImageService {
    enum NetworkError: Error, LocalizedError {
        case invalidRequest
        case unauthorized
        case httpStatusCode(Int)
        case noData
        
        var errorDescription: String? {
            switch self {
            case .invalidRequest:
                return "Не удалось создать запрос"
            case .unauthorized:
                return "Не авторизован"
            case .httpStatusCode(let code):
                return "Неверный статус код: \(code)"
            case .noData:
                return "Данные не получены"
            }
        }
    }
}
