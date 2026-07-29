import Foundation

// MARK: - Protocol

protocol ProfilePresenterProtocol: AnyObject {
    var view: ProfileViewProtocol? { get set }
    func viewDidLoad()
    func viewWillAppear()
    func didTapLogout()
    func updateAvatar()
}

final class ProfilePresenter: ProfilePresenterProtocol {
    weak var view: ProfileViewProtocol?
    private let profileService = ProfileService.shared
    private let imageService = ProfileImageService.shared
    private let logoutService = ProfileLogoutService.shared
    
    private var profileObserver: NSObjectProtocol?
    
    func viewDidLoad() {
        if let profile = profileService.profile {
            view?.displayProfile(profile)
            updateAvatar()
        }
        observeAvatarChanges()
    }
    
    func viewWillAppear() {
        if let profile = profileService.profile {
            view?.displayProfile(profile)
        }
    }
    
    func didTapLogout() {
        view?.showLogoutConfirmation()
    }
    
    func updateAvatar() {
        print("🔄 [ProfilePresenter] updateAvatar вызван, avatarURL = \(imageService.avatarURL ?? "nil")")
        guard let avatarURL = imageService.avatarURL else {
            print("ℹ️ [Presenter] avatarURL отсутствует")
            return
        }
        guard let url = URL(string: avatarURL) else {
                print("❌ [Presenter] Невалидный URL аватарки: \(avatarURL)")
                return
            }
            print("✅ [Presenter] Вызываем displayAvatar с URL: \(url)")
        view?.displayAvatar(with: url)
    }
    
     func observeAvatarChanges() {
        profileObserver = NotificationCenter.default.addObserver(
            forName: ProfileImageService.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            print("📢 [ProfilePresenter] Получена нотификация об изменении аватарки")
            self?.updateAvatar()
        }
    }
    
    deinit {
        if let observer = profileObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}
