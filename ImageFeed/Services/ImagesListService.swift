import Foundation

import Foundation

final class ImagesListService {
    
    // MARK: - Singleton
    static let shared = ImagesListService()
    private init() {}
    
    // MARK: - Properties
    private(set) var photos: [Photo] = []
    private var lastLoadedPage: Int?
    private var task: URLSessionTask?
    private let urlSession = URLSession.shared
    private let tokenStorage = OAuth2TokenStorage()
    
    // MARK: - Notification
    static let didChangeNotification = Notification.Name(rawValue: "ImagesListServiceDidChange")
    
    // MARK: - Public Methods
    
    /// Загружает следующую страницу фотографий
    func fetchPhotosNextPage() {
        assert(Thread.isMainThread)
        
        // 1. Если уже идёт загрузка — прерываем
        if task != nil {
            print("⚠️ [ImagesListService] Загрузка уже идёт, игнорируем повторный вызов")
            return
        }
        
        // 2. Определяем номер следующей страницы
        let nextPage = (lastLoadedPage ?? 0) + 1
        
        // 3. Создаём запрос
        guard let request = makePhotosRequest(page: nextPage) else {
            print("❌ [ImagesListService] Не удалось создать запрос")
            return
        }
        
        print("📡 [ImagesListService] Загрузка страницы \(nextPage)...")
        
        // 4. Выполняем запрос через objectTask
        let task = urlSession.objectTask(for: request) { [weak self] (result: Result<[PhotoResult], Error>) in
            guard let self = self else { return }
            
            // Очищаем task после завершения
            self.task = nil
            
            switch result {
            case .success(let photoResults):
                // Конвертируем PhotoResult → Photo
                let newPhotos = photoResults.map { self.convertToPhoto(from: $0) }
                
                // Обновляем массив и lastLoadedPage на главном потоке
                DispatchQueue.main.async {
                    self.photos.append(contentsOf: newPhotos)
                    self.lastLoadedPage = nextPage
                    
                    // Публикуем нотификацию
                    NotificationCenter.default.post(
                        name: ImagesListService.didChangeNotification,
                        object: self,
                        userInfo: ["photos": self.photos]
                    )
                    print("✅ [ImagesListService] Загружена страница \(nextPage), всего фото: \(self.photos.count)")
                }
                
            case .failure(let error):
                print("❌ [ImagesListService] Ошибка загрузки страницы \(nextPage): \(error.localizedDescription)")
            }
        }
        
        self.task = task
        task.resume()
    }
    
    // MARK: - Private Methods
    
    private func makePhotosRequest(page: Int) -> URLRequest? {
        guard let token = tokenStorage.token else {
            print("❌ [ImagesListService] Токен не найден")
            return nil
        }
        
        var urlComponents = URLComponents(string: "\(Constants.defaultBaseURLString)/photos")!
        urlComponents.queryItems = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "per_page", value: "10")
        ]
        
        guard let url = urlComponents.url else {
            print("❌ [ImagesListService] Не удалось создать URL")
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return request
    }
    
    private func convertToPhoto(from result: PhotoResult) -> Photo {
        let size = CGSize(width: result.width, height: result.height)
        let createdAt = DateFormatter.iso8601Full.date(from: result.createdAt ?? "")
        
        return Photo(
            id: result.id,
            size: size,
            createdAt: createdAt,
            welcomeDescription: result.description,
            thumbImageURL: result.urls.thumb,
            largeImageURL: result.urls.full,
            isLiked: result.likedByUser
        )
    }
}

// MARK: - DateFormatter Extension
extension DateFormatter {
    static let iso8601Full: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
}
