import Foundation

// MARK: - Models

/// Модель ответа от сервера Unsplash API
struct ProfileResult: Codable, Sendable {
    let username: String
    let firstName: String
    let lastName: String?
    let bio: String?
    
    enum CodingKeys: String, CodingKey {
        case username
        case firstName = "first_name"
        case lastName = "last_name"
        case bio
    }
}

/// Модель профиля для UI-слоя
struct Profile {
    let username: String
    let name: String
    let loginName: String
    let bio: String?
    
    /// Создаёт Profile из ProfileResult
    init(from result: ProfileResult) {
        self.username = result.username
        self.name = [result.firstName, result.lastName]
            .compactMap { $0 }
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespaces)
        self.loginName = "@\(result.username)"
        self.bio = result.bio
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
        
        let task = urlSession.objectTask(for: request) { [weak self] (result: Result<ProfileResult, Error>) in
            defer {
                DispatchQueue.main.async {
                    self?.task = nil
                }
            }
            
            guard let self = self else { return }
            
            switch result {
            case .success(let profileResult):
                let profile = Profile(from: profileResult)
                print("✅ [ProfileService] Профиль успешно получен и декодирован")
                self.profile = profile
                completion(.success(profile))
                
            case .failure(let error):
                print("❌ [ProfileService] Ошибка: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
        
        self.task = task
        task.resume()
    }
}

