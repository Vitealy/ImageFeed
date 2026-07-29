import Foundation

// MARK: - Protocol
protocol ImagesListPresenterProtocol: AnyObject {
    var view: ImagesListViewProtocol? { get set }
    func viewDidLoad()
    func fetchNextPage()
    func didTapLike(at index: Int, completion: ((Result<Void, Error>) -> Void)?)
}

final class ImagesListPresenter: ImagesListPresenterProtocol {
    weak var view: ImagesListViewProtocol?
    private let service = ImagesListService.shared
    private var observer: NSObjectProtocol?
    
    func viewDidLoad() {
        print("✅ [Presenter] viewDidLoad вызван")
        service.fetchPhotosNextPage()
        observeChanges()
    }
    
    func fetchNextPage() {
        service.fetchPhotosNextPage()
    }
    
    func didTapLike(at index: Int, completion: ((Result<Void, Error>) -> Void)? = nil) {
        guard index < service.photos.count else { return }
        let photo = service.photos[index]
        service.changeLike(photoId: photo.id, isLiked: photo.isLiked) { [weak self] result in
            switch result {
            case .success:
                completion?(.success(()))
                print("✅ [Presenter] Лайк успешен, вызываем updatePhoto(at: \(index))")
            case .failure(let error):
                completion?(.failure(error))
                print("❌ [Presenter] Ошибка лайка: \(error)")
            }
        }
    }
    
     func observeChanges() {
        observer = NotificationCenter.default.addObserver(
            forName: ImagesListService.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self else { return }
            // если есть photoId – обновляем одну ячейку, иначе всю таблицу
            if let photoId = notification.userInfo?["photoId"] as? String,
               let index = self.service.photos.firstIndex(where: { $0.id == photoId }) {
                let updatedPhoto = self.service.photos[index]
                self.view?.updatePhoto(at: index, with: updatedPhoto)
            } else {
                self.view?.displayPhotos(self.service.photos)
            }
        }
    }
    
    deinit {
        if let observer = observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}
