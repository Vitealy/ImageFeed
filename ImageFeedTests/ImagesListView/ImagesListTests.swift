import XCTest
@testable import ImageFeed

@MainActor
final class ImagesListTests: XCTestCase {
    
    func testViewControllerCallsPresenterOnLoad() {
        // given
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "ImagesListViewController") as! ImagesListViewController
        let presenter = ImagesListPresenterSpy()
        viewController.configure(with: presenter)
        
        // when
        _ = viewController.view
        
        // then
        XCTAssertTrue(presenter.viewDidLoadCalled)
    }
    
    func testPresenterUpdatesSinglePhotoOnNotificationWithPhotoId() {
        // given
        let viewSpy = ImagesListViewSpy()
        let presenter = ImagesListPresenter()
        presenter.view = viewSpy
        presenter.observeChanges()
        
        // Подготавливаем сервис с тестовыми данными
        let testPhoto = Photo(
            id: "123",
            size: CGSize(width: 100, height: 100),
            createdAt: nil,
            welcomeDescription: nil,
            thumbImageURLString: "",
            largeImageURLString: "",
            isLiked: false
        )
        ImagesListService.shared.setPhotosForTesting([testPhoto])
        
        // when
        NotificationCenter.default.post(
            name: ImagesListService.didChangeNotification,
            object: nil,
            userInfo: ["photoId": "123"]
        )
        
        // then
        XCTAssertTrue(viewSpy.updatePhotoCalled)
    }
    
    func testPresenterUpdatesAllPhotosOnNotificationWithoutPhotoId() {
        // given
        let viewSpy = ImagesListViewSpy()
        let presenter = ImagesListPresenter()
        presenter.view = viewSpy
        presenter.observeChanges()
        
        // when
        NotificationCenter.default.post(
            name: ImagesListService.didChangeNotification,
            object: nil,
            userInfo: nil
        )
        
        // then
        XCTAssertTrue(viewSpy.displayPhotosCalled)
    }
    
    func testPresenterFetchesNextPage() {
        // given
        let presenterSpy = ImagesListPresenterSpy()
        
        // when
        presenterSpy.fetchNextPage()
        
        // then
        XCTAssertTrue(presenterSpy.fetchNextPageCalled)
        
    }
}
