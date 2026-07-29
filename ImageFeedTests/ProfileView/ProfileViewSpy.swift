@testable import ImageFeed
import Foundation

final class ProfileViewSpy: ProfileViewProtocol {
    var presenter: ProfilePresenterProtocol?
    var displayProfileCalled = false
    var displayAvatarCalled = false
    var showErrorCalled = false
    var showLogoutConfirmationCalled = false
    
    func displayProfile(_ profile: Profile) { displayProfileCalled = true }
    func displayAvatar(with url: URL) { displayAvatarCalled = true }
    func showError(_ message: String) { showErrorCalled = true }
    func showLogoutConfirmation() { showLogoutConfirmationCalled = true }
}
