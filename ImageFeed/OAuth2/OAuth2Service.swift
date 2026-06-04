import Foundation

final class OAuth2Service {
    static let shared = OAuth2Service()
    private init() {}
    
    private let urlSession = URLSession.shared
    private var task: URLSessionTask?
    private var lastCode: String?
    private let tokenStorage = OAuth2TokenStorage()
    
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
        // Отменяем предыдущий запрос, если он был с тем же кодом
        if lastCode == code {
            task?.cancel()
            print("🔄 [OAuth2Service] Отменён предыдущий запрос с тем же кодом")
        }
        
        lastCode = code
        
        guard let request = makeOAuthTokenRequest(code: code) else {
            print("❌ [OAuth2Service] Ошибка: \(NetworkError.invalidRequest.localizedDescription)")
            completion(.failure(NetworkError.invalidRequest))
            return
        }
        
        let task = urlSession.dataTask(with: request) { [weak self] data, response, error in
            // Очищаем сохранённый код после выполнения запроса
            defer {
                self?.task = nil
                self?.lastCode = nil
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
                    let statusCodeError = NetworkError.httpStatusCode(httpResponse.statusCode)
                    print("❌ [OAuth2Service] Ошибка сервера: HTTP \(httpResponse.statusCode)")
                    DispatchQueue.main.async {
                        completion(.failure(statusCodeError))
                    }
                    return
                }
            }
            
            // Проверяем наличие данных
            guard let data = data else {
                print("❌ [OAuth2Service] Ошибка: \(NetworkError.noData.localizedDescription)")
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
                let token = try self.decodeTokenResponse(data: data)
                print("✅ [OAuth2Service] Токен успешно получен и декодирован")
                
                // Сохраняем Bearer Token в UserDefaults
                self.tokenStorage.token = token
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


