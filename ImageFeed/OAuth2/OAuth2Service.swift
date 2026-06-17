import Foundation

final class OAuth2Service {
    static let shared = OAuth2Service()
    private init() {}
    
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
            print("❌ [OAuth2Service] Ошибка: \(AuthServiceError.invalidRequest.localizedDescription)")
            completion(.failure(AuthServiceError.invalidRequest))
            return
        }
        
        let task = urlSession.dataTask(with: request) { [weak self] data, response, error in
            // Очищаем сохранённый код после выполнения запроса
            defer {
                DispatchQueue.main.async {
                    self?.task = nil
                    self?.lastCode = nil
                }
                
            }
            
            // Проверяем ошибку сети
            if let error = error {
                print("❌ [OAuth2Service] Сетевая ошибка: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            // Проверяем HTTP статус
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 [OAuth2Service] HTTP статус код: \(httpResponse.statusCode)")
                
                guard 200..<300 ~= httpResponse.statusCode else {
                    // Ошибка, которую вернул сервис Unsplash
                    let statusCodeError = AuthServiceError.httpStatusCode(httpResponse.statusCode)
                    print("❌ [OAuth2Service] Ошибка сервера: HTTP \(httpResponse.statusCode)")
                    DispatchQueue.main.async {
                        completion(.failure(statusCodeError))
                    }
                    return
                }
            }
            
            // Проверяем наличие данных
            guard let data = data else {
                print("❌ [OAuth2Service] Ошибка: \(AuthServiceError.noData.localizedDescription)")
                DispatchQueue.main.async {
                    completion(.failure(AuthServiceError.noData))
                }
                return
            }
            
            // Декодируем ответ
            do {
                guard let self = self else {
                    throw AuthServiceError.invalidRequest
                }
                let token = try self.decodeTokenResponse(data: data)
                print("✅ [OAuth2Service] Токен успешно получен и декодирован")
                
                // Сохраняем Bearer Token в UserDefaults
                self.authToken = token
                print("💾 [OAuth2Service] Токен сохранён в UserDefaults")
                
                DispatchQueue.main.async {
                    completion(.success(token))
                }
            } catch {
                print("❌ [OAuth2Service] Ошибка декодирования: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
        
        self.task = task
        task.resume()
    }
    
    // MARK: - Private Methods
    private func decodeTokenResponse(data: Data) throws -> String {
        let decoder = JSONDecoder()
        let tokenResponse = try decoder.decode(OAuthTokenResponseBody.self, from: data)
        return tokenResponse.accessToken
    }
}

// MARK: - Network Error
extension OAuth2Service {
    enum AuthServiceError: Error, LocalizedError {
        case invalidRequest
        case duplicateRequest
        case invalidState
        case httpStatusCode(Int)
        case noData
        
        var errorDescription: String? {
            switch self {
            case .invalidRequest:
                return "Не удалось создать запрос"
            case .duplicateRequest:
                return "Запрос уже выполняется"
            case .invalidState:
                return "Некорректное состояние"
            case .httpStatusCode(let code):
                return "Неверный статус код: \(code)"
            case .noData:
                return "Данные не получены"
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


