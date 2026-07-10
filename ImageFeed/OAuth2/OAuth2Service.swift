import Foundation

final class OAuth2Service {
    
    // MARK: - Singleton
    static let shared = OAuth2Service()
    private init() {}
    
    // MARK: - Properties
    private let urlSession = URLSession.shared
    private var task: URLSessionTask?
    private var lastCode: String?
    private let tokenStorage = OAuth2TokenStorage()
    private(set) var authToken: String? {
        get { tokenStorage.token }
        set { tokenStorage.token = newValue }
    }
    
    // MARK: - Public Methods
    func makeOAuthTokenRequest(code: String) -> URLRequest? {
        guard var urlComponents = URLComponents(string: "https://unsplash.com/oauth/token") else {
            print("❌ [OAuth2Service] Не удалось создать URLComponents")
            return nil
        }
        
        urlComponents.queryItems = [
            URLQueryItem(name: "client_id", value: Constants.accessKey),
            URLQueryItem(name: "client_secret", value: Constants.secretKey),
            URLQueryItem(name: "redirect_uri", value: Constants.redirectURI),
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "grant_type", value: "authorization_code"),
        ]
        
        guard let authTokenUrl = urlComponents.url else {
            print("❌ [OAuth2Service] Не удалось создать URL из компонентов")
            return nil
        }
        
        var request = URLRequest(url: authTokenUrl)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }
    
    func fetchOAuthToken(
        _ code: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        assert(Thread.isMainThread) // Проверяем, что мы на главном потоке
        
        if task != nil {
            if lastCode != code { // Запрос уже выполняется!
                print("🔄 [OAuth2Service] Новый код, отменяем старый запрос")
                task?.cancel()
            } else { // Второй запрос не нужен — первый уже в процессе
                print("⚠️ [OAuth2Service] Запрос с таким кодом уже выполняется, игнорируем")
                completion(.failure(AuthServiceError.duplicateRequest))
                return
            }
        } else {
            if lastCode == code { // Запроса нет — проверяем, не сохранили ли мы уже этот код?
                print("⚠️ [OAuth2Service] Нет активного запроса, но lastCode совпадает")
                completion(.failure(AuthServiceError.invalidState))
                return
            }
        }
        
        lastCode = code
        
        guard let request = makeOAuthTokenRequest(code: code) else {
            print("❌ [OAuth2Service] Ошибка: \(NetworkError.invalidRequest.localizedDescription)")
            completion(.failure(NetworkError.invalidRequest))
            return
        }
        
        print("📡 [OAuth2Service] Отправка запроса на получение токена...")
        
        let task = urlSession.objectTask(for: request) { [weak self] (result: Result<OAuthTokenResponseBody, Error>) in
            defer {
                DispatchQueue.main.async {
                    self?.task = nil
                    self?.lastCode = nil
                }
            }
            
            guard let self = self else { return }
            
            switch result {
            case .success(let tokenResponse):
                let token = tokenResponse.accessToken
                print("✅ [OAuth2Service] Токен успешно получен и декодирован")
                self.authToken = token
                print("💾 [OAuth2Service] Токен сохранён в Keychain")
                completion(.success(token))
                
            case .failure(let error):
                print("❌ [OAuth2Service] Ошибка: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
        
        self.task = task
        task.resume()
    }
}

// MARK: - Network Error
extension OAuth2Service {
    enum AuthServiceError: Error, LocalizedError {
        case duplicateRequest
        case invalidState
        
        var errorDescription: String? {
            switch self {
            case .duplicateRequest:
                return "Запрос уже выполняется"
            case .invalidState:
                return "Некорректное состояние"
            }
        }
    }
}

// MARK: - Decodable Models
struct OAuthTokenResponseBody: Decodable, @unchecked Sendable {
    let accessToken: String
    let tokenType: String
    let scope: String
    let createdAt: Int
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case scope
        case createdAt = "created_at"
    }
}


