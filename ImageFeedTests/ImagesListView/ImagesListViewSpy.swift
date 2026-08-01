@testable import ImageFeed
import Foundation

final class ImagesListViewSpy: ImagesListViewProtocol {
    var presenter: ImagesListPresenterProtocol?
    var displayPhotosCalled = false
    var updatePhotoCalled = false
    func displayPhotos(_ photos: [Photo]) { displayPhotosCalled = true }
    func updatePhoto(at index: Int, with photo: Photo) { updatePhotoCalled = true }
}

