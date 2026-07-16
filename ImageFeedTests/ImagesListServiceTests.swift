import XCTest
@testable import ImageFeed

final class ImagesListServiceTests: XCTestCase {
    var service: ImagesListService!

    override func setUp() {
        super.setUp()
        service = ImagesListService.shared
        service.reset() // очищаем состояние перед каждым тестом
    }

    func testFetchPhotos() {
        let expectation = self.expectation(description: "Wait for Notification")
        NotificationCenter.default.addObserver(
            forName: ImagesListService.didChangeNotification,
            object: nil,
            queue: .main
        ) { _ in
            expectation.fulfill()
        }

        service.fetchPhotosNextPage()
        wait(for: [expectation], timeout: 10)

        XCTAssertEqual(service.photos.count, 10)
    }
}
