import Foundation
@MainActor
protocol ProfilePresenterProtocol {
    var view: ProfileViewControllerProtocol? { get set }
    func viewDidLoad()
    func didTapLogout()
    func userConfirmedLogout()
}

@MainActor
final class ProfilePresenter: ProfilePresenterProtocol {
    weak var view: ProfileViewControllerProtocol?
    private var avatarObserver: NSObjectProtocol?
    
    // MARK: - Lifecycle
    
    func viewDidLoad() {
        updateProfileDetails()
        updateAvatar()
        
        avatarObserver = NotificationCenter.default.addObserver(
            forName: ProfileImageService.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.updateAvatar()
            }
        }
    }
    
// MARK: - Public Methods
    
    func didTapLogout() {
        view?.showLogoutAlert()
    }
    
    func userConfirmedLogout() {
        ProfileLogoutService.shared.logout()
    }
    
    // MARK: - Private Methods
    
    private func updateProfileDetails() {
        if let profile = ProfileService.shared.profile {
            view?.showProfileDetails(
                personName: profile.name,
                username: profile.loginName,
                profileDescription: profile.bio
            )
        }
    }
    
    private func updateAvatar() {
        guard let profileImageURL = ProfileImageService.shared.avatarURL,
              let url = URL(string: profileImageURL)
        else { return }
        view?.showAvatar(url: url)
    }
    
    
    deinit {
        if let observer = avatarObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}
