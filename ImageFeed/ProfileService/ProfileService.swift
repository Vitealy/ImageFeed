import Foundation

// MARK: - Models

/// Модель ответа от сервера Unsplash API
struct ProfileResult: Codable, Sendable {
    let username: String
    let firstName: String
    let lastName: String?
    let bio: String?
    let profileImage: ProfileImage?
    
    enum CodingKeys: String, CodingKey {
        case username
        case firstName = "first_name"
        case lastName = "last_name"
        case bio
        case profileImage = "profile_image"
    }
}

/// Модель для изображений профиля
struct ProfileImage: Codable, Sendable {
    let small: String
    let medium: String
    let large: String
}

/// Модель профиля для UI-слоя
struct Profile {
    let username: String
    let name: String
    let loginName: String
    let bio: String?
    let avatarURL: String?
    
    /// Создаёт Profile из ProfileResult
    init(from result: ProfileResult) {
        self.username = result.username
        self.name = [result.firstName, result.lastName]
            .compactMap { $0 }
            .joined(separator: " ")
        self.loginName = "@\(result.username)"
        self.bio = result.bio
        self.avatarURL = result.profileImage?.large
    }
}

// MARK: - ProfileService

final class ProfileService {
    
    // MARK: - Singleton
    static let shared = ProfileService()
    private init() {}
    
    // MARK: - Properties
    private let urlSession = URLSession.shared
    private var task: URLSessionTask?
    private(set) var profile: Profile?
    
    // MARK: - Public Methods
    
    /// Создаёт URLRequest для получения профиля
    /// - Parameter token: Bearer токен авторизации
    /// - Returns: URLRequest или nil, если не удалось создать
    private func makeProfileRequest(token: String) -> URLRequest? {
        guard let url = URL(string: "\(Constants.defaultBaseURLString)/me") else {
            print("❌ [ProfileService] Не удалось создать URL")
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return request
    }
    
    private func decodeProfile(from data: Data) throws -> Profile {
        let decoder = JSONDecoder()
        let profileResult = try decoder.decode(ProfileResult.self, from: data)
        return Profile(from: profileResult)
    }
    
    /// Загружает профиль пользователя
    /// - Parameters:
    ///   - token: Bearer токен авторизации
    ///   - completion: Замыкание с результатом (Profile или Error)
    func fetchProfile(_ token: String, completion: @escaping (Result<Profile, Error>) -> Void) {
        assert(Thread.isMainThread) // Проверяем, что мы на главном потоке
        
        // Отменяем предыдущий запрос, если он был
        task?.cancel()
        
        guard let request = makeProfileRequest(token: token) else {
            print("❌ [ProfileService] Не удалось создать запрос для получения профиля")
            completion(.failure(NetworkError.invalidRequest))
            return
        }
        
        print("📡 [ProfileService] Отправка запроса на получение профиля...")
        
        let task = urlSession.dataTask(with: request) { [weak self] data, response, error in
            defer {
                DispatchQueue.main.async {
                    self?.task = nil
                }
            }
            
            // Проверяем ошибку сети
            if let error = error {
                print("❌ [ProfileService] Сетевая ошибка: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            // Проверяем HTTP статус
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 [ProfileService] HTTP статус код: \(httpResponse.statusCode)")
                
                guard 200..<300 ~= httpResponse.statusCode else {
                    print("❌ [ProfileService] Ошибка сервера: HTTP \(httpResponse.statusCode)")
                    DispatchQueue.main.async {
                        completion(.failure(NetworkError.httpStatusCode(httpResponse.statusCode)))
                    }
                    return
                }
            }
            
            // Проверяем наличие данных
            guard let data = data else {
                print("❌ [ProfileService] Данные не получены")
                DispatchQueue.main.async {
                    completion(.failure(NetworkError.noData))
                }
                return
            }
            
            // Декодируем ответ
            do {
                guard let self = self else {
                        throw NetworkError.invalidRequest
                    }
                    let profile = try self.decodeProfile(from: data)

                print("✅ [ProfileService] Профиль успешно получен и декодирован")
                
                self.profile = profile
                
                DispatchQueue.main.async {
                    completion(.success(profile))
                }
            } catch {
                print("❌ [ProfileService] Ошибка декодирования: \(error.localizedDescription)")
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
extension ProfileService {
    enum NetworkError: Error, LocalizedError {
        case invalidRequest
        case httpStatusCode(Int)
        case noData
        
        var errorDescription: String? {
            switch self {
            case .invalidRequest:
                return "Не удалось создать запрос"
            case .httpStatusCode(let code):
                return "Неверный статус код: \(code)"
            case .noData:
                return "Данные не получены"
            }
        }
    }
}
