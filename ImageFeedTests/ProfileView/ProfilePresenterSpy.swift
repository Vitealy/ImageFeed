@testable import ImageFeed
import Foundation

final class ProfilePresenterSpy: ProfilePresenterProtocol {
    weak var view: ProfileViewProtocol?
    var viewDidLoadCalled = false
    var viewWillAppearCalled = false
    var didTapLogoutCalled = false
    var updateAvatarCalled = false
    
    func viewDidLoad() { viewDidLoadCalled = true }
    func viewWillAppear() { viewWillAppearCalled = true }
    func didTapLogout() { didTapLogoutCalled = true }
    func updateAvatar() { updateAvatarCalled = true }
}
