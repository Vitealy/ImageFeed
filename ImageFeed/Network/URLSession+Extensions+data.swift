import Foundation

// MARK: - Network Errors
enum NetworkError: Error, LocalizedError {
    case httpStatusCode(Int)
    case urlRequestError(Error)
    case urlSessionError
    case invalidRequest
    case noData
    case unauthorized
    
    var errorDescription: String? {
        switch self {
        case .httpStatusCode(let code):
            return "HTTP ошибка: \(code)"
        case .urlRequestError(let error):
            return "Ошибка запроса: \(error.localizedDescription)"
        case .urlSessionError:
            return "Неизвестная ошибка сессии"
        case .invalidRequest:
            return "Не удалось создать запрос"
        case .noData:
            return "Данные не получены"
        case .unauthorized:
            return "Не авторизован"
        }
    }
}

// MARK: - URLSession Extension
extension URLSession {
    
    // MARK: - Data Task
    func data(
        for request: URLRequest,
        completion: @escaping (Result<Data, Error>) -> Void
    ) -> URLSessionTask {
        // Оборачиваем completion, чтобы он всегда вызывался на главном потоке
        let fulfillCompletionOnTheMainThread: (Result<Data, Error>) -> Void = { result in
            DispatchQueue.main.async {
                completion(result)
            }
        }
        
        let task = dataTask(with: request, completionHandler: { data, response, error in
            // Проверяем, что есть данные и ответ
            if let data = data,
               let response = response,
               let statusCode = (response as? HTTPURLResponse)?.statusCode {
                
                // Проверяем статус код (200-299 — успех)
                if 200 ..< 300 ~= statusCode {
                    fulfillCompletionOnTheMainThread(.success(data))
                } else {
                    print("❌ [URLSession] HTTP ошибка: статус код \(statusCode) для запроса \(request.url?.absoluteString ?? "")")
                    fulfillCompletionOnTheMainThread(.failure(NetworkError.httpStatusCode(statusCode)))
                }
            } else if let error = error {
                // Ошибка сети
                print("❌ [URLSession] Сетевая ошибка: \(error.localizedDescription) для запроса \(request.url?.absoluteString ?? "")")
                fulfillCompletionOnTheMainThread(.failure(NetworkError.urlRequestError(error)))
            } else {
                // Неизвестная ошибка
                print("❌ [URLSession] Неизвестная ошибка: данные и ответ отсутствуют для запроса \(request.url?.absoluteString ?? "")")
                fulfillCompletionOnTheMainThread(.failure(NetworkError.urlSessionError))
            }
        })
        
        return task
    }
    
    // MARK: - Object Task
    func objectTask<T: Decodable>(
        for request: URLRequest,
        completion: @escaping (Result<T, Error>) -> Void
    ) -> URLSessionTask {
        let decoder = JSONDecoder()
        
        let task = data(for: request) { (result: Result<Data, Error>) in
            switch result {
            case .success(let data):
                // ✅ Логируем полученные данные для отладки
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("📡 [URLSession] Полученные данные: \(jsonString)")
                }
                
                do {
                    let decodedObject = try decoder.decode(T.self, from: data)
                    completion(.success(decodedObject))
                } catch {
                    // ✅ Детальная обработка ошибок декодирования
                    if let decodingError = error as? DecodingError {
                        print("❌ [URLSession] Ошибка декодирования: \(decodingError)")
                    } else {
                        print("❌ [URLSession] Ошибка декодирования: \(error.localizedDescription)")
                    }
                    // ✅ Показываем данные, которые не удалось декодировать
                    if let jsonString = String(data: data, encoding: .utf8) {
                        print("❌ [URLSession] Данные, которые не удалось декодировать: \(jsonString)")
                    }
                    completion(.failure(error))
                }
                
            case .failure(let error):
                print("❌ [URLSession] Ошибка запроса: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
        
        return task
    }
}
