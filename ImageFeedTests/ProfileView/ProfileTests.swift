import XCTest
@testable import ImageFeed

@MainActor
final class ProfileTests: XCTestCase {
    
    func testViewControllerCallsPresenterOnLoad() {
        // given
        let viewController = ProfileViewController()
        let presenter = ProfilePresenterSpy()
        viewController.configure(with: presenter)
        
        // when
        _ = viewController.view
        
        // then
        XCTAssertTrue(presenter.viewDidLoadCalled)
    }
    
    func testViewControllerCallsPresenterOnWillAppear() {
        // given
        let viewController = ProfileViewController()
        let presenter = ProfilePresenterSpy()
        viewController.configure(with: presenter)
        
        // when
        viewController.viewWillAppear(false)
        
        // then
        XCTAssertTrue(presenter.viewWillAppearCalled)
    }
    
    func testPresenterDisplaysProfileOnSuccess() {
        // given
        let viewSpy = ProfileViewSpy()
        let presenter = ProfilePresenter()
        presenter.view = viewSpy
        let profileResult = ProfileResult(username: "test", firstName: "Test", lastName: "User", bio: "bio")
        let profile = Profile(from: profileResult)
        
        // when
        viewSpy.displayProfile(profile)
        
        // then
        XCTAssertTrue(viewSpy.displayProfileCalled)
    }
    
    func testPresenterUpdatesAvatarOnNotification() {
        // given
        let viewSpy = ProfileViewSpy()
        let presenter = ProfilePresenter()
        presenter.view = viewSpy
        presenter.observeAvatarChanges()
        let testURLString = "https://example.com/avatar.jpg"
        ProfileImageService.shared.avatarURL = testURLString
        
        // when
        NotificationCenter.default.post(
            name: ProfileImageService.didChangeNotification,
            object: nil,
            userInfo: nil
        )
        
        // then
        XCTAssertTrue(viewSpy.displayAvatarCalled)
    }
    
    func testLogoutConfirmationShown() {
        // given
        let viewSpy = ProfileViewSpy()
        let presenter = ProfilePresenter()
        presenter.view = viewSpy
        
        // when
        presenter.didTapLogout()
        
        // then
        XCTAssertTrue(viewSpy.showLogoutConfirmationCalled)
    }
    
    func testPresenterDoesNotDisplayAvatarWhenAvatarURLIsNil() {
        // given
        let viewSpy = ProfileViewSpy()
        let presenter = ProfilePresenter()
        presenter.view = viewSpy
        
        // Убеждаемся, что avatarURL = nil
        ProfileImageService.shared.avatarURL = nil
        
        // when
        presenter.updateAvatar()
        
        // then
        XCTAssertFalse(viewSpy.displayAvatarCalled)
    }
    
    func testPresenterShowsErrorOnFailure() {
        // given
        let viewSpy = ProfileViewSpy()
        let presenter = ProfilePresenter()
        presenter.view = viewSpy
        // when
        viewSpy.showError("Test error")
        // then
        XCTAssertTrue(viewSpy.showErrorCalled)
    }
}
