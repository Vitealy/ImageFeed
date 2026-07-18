import Foundation
internal import CoreGraphics

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
    private var likeTask: URLSessionTask?
    
    // MARK: - Notification
    static let didChangeNotification = Notification.Name(rawValue: "ImagesListServiceDidChange")
    
    // MARK: - Public Methods
    
    /// Загружает следующую страницу фотографий
    func fetchPhotosNextPage() {
        assert(Thread.isMainThread)
        
        // ✅ Если уже идёт загрузка — прерываем
        if task != nil {
            print("⚠️ [ImagesListService] Загрузка уже идёт, игнорируем повторный вызов")
            return
        }
        
        // ✅ Определяем номер следующей страницы
        let nextPage = (lastLoadedPage ?? 0) + 1
        
        // ✅ Создаём запрос
        guard let request = makePhotosRequest(page: nextPage) else {
            print("❌ [ImagesListService] Не удалось создать запрос")
            return
        }
        
        print("📡 [ImagesListService] Загрузка страницы \(nextPage)...")
        
        // ✅ Выполняем запрос через objectTask
        let task = urlSession.objectTask(for: request) { [weak self] (result: Result<[PhotoResult], Error>) in
            guard let self = self else { return }
            
            // Очищаем task после завершения (на главном потоке)
            DispatchQueue.main.async {
                self.task = nil
            }
            
            switch result {
            case .success(let photoResults):
                // Конвертируем PhotoResult → Photo
                let newPhotos = photoResults.map { self.convertToPhoto(from: $0) }
                
                // ✅ Обновляем массив и lastLoadedPage на главном потоке
                DispatchQueue.main.async {
                    self.photos.append(contentsOf: newPhotos)
                    self.lastLoadedPage = nextPage
                    
                    // ✅ Публикуем нотификацию
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
    
    // MARK: - Change Like
    func changeLike(photoId: String, isLiked: Bool, completion: @escaping (Result<Bool, Error>) -> Void) {
        assert(Thread.isMainThread)
        
        // ✅ Отменяем предыдущий запрос лайка
        likeTask?.cancel()
        
        // Определяем метод: POST (поставить лайк) или DELETE (убрать)
        let httpMethod = isLiked ? "DELETE" : "POST"
        
        guard let request = makeLikeRequest(photoId: photoId, httpMethod: httpMethod) else {
            print("❌ [ImagesListService] Не удалось создать запрос для изменения лайка")
            completion(.failure(NetworkError.invalidRequest))
            return
        }
        
        print("📡 [ImagesListService] \(httpMethod) лайк для фото \(photoId)")
        
        let task = urlSession.objectTask(for: request) { [weak self] (result: Result<PhotoLikeResult, Error>) in
            guard let self = self else { return }
            
            // ✅ Очищаем likeTask после завершения
            DispatchQueue.main.async {
                self.likeTask = nil
            }
            
            switch result {
            case .success(let likeResult):
                // Обновляем локальный массив
                if let index = self.photos.firstIndex(where: { $0.id == photoId }) {
                    let oldPhoto = self.photos[index]
                    let newPhoto = Photo(
                        id: oldPhoto.id,
                        size: oldPhoto.size,
                        createdAt: oldPhoto.createdAt,
                        welcomeDescription: oldPhoto.welcomeDescription,
                        thumbImageURL: oldPhoto.thumbImageURL,
                        largeImageURL: oldPhoto.largeImageURL,
                        isLiked: likeResult.photo.likedByUser
                    )
                    self.photos[index] = newPhoto
                    
                    // Публикуем нотификацию об обновлении
                    NotificationCenter.default.post(
                        name: ImagesListService.didChangeNotification,
                        object: self,
                        userInfo: ["photoId": photoId]
                    )
                }
                
                completion(.success(likeResult.photo.likedByUser))
                
            case .failure(let error):
                print("❌ [ImagesListService] Ошибка изменения лайка: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
        
        self.task = task
        task.resume()
    }

    // MARK: - Private Helpers
    private func makeLikeRequest(photoId: String, httpMethod: String) -> URLRequest? {
        guard let token = tokenStorage.token else {
            print("❌ [ImagesListService] Токен не найден")
            return nil
        }
        
        guard let url = URL(string: "\(Constants.defaultBaseURLString)/photos/\(photoId)/like") else {
            print("❌ [ImagesListService] Не удалось создать URL")
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return request
    }
    
    // MARK: - Test Helpers
#if DEBUG
    func reset() {
        photos = []
        lastLoadedPage = nil
        task = nil
        // также можно сбросить другие внутренние состояния, если нужно
    }
#endif
    
}
