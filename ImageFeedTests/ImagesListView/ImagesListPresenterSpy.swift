@testable import ImageFeed
import Foundation

final class ImagesListPresenterSpy: ImagesListPresenterProtocol {
    weak var view: ImagesListViewProtocol?
    var viewDidLoadCalled = false
    var fetchNextPageCalled = false
    var didTapLikeCalled = false
    
    func viewDidLoad() { viewDidLoadCalled = true }
    func fetchNextPage() { fetchNextPageCalled = true }
    func didTapLike(at index: Int, completion: ((Result<Void, Error>) -> Void)?) {
        didTapLikeCalled = true
        completion?(.success(()))
    }
}
