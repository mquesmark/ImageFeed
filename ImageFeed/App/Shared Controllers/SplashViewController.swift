import UIKit

final class SplashViewController: UIViewController {
    private let storage = OAuth2TokenStorage.shared
    
    private let imageView = UIImageView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewElementsAndConstraints()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let token = storage.token {
            fetchProfile(token: token)
        } else {
            let authVC = AuthViewController()
            authVC.delegate = self
            
            let navVC = UINavigationController(rootViewController: authVC)
            navVC.modalPresentationStyle = .fullScreen
            present(navVC, animated: true)
        }
    }
    
    // MARK: Private methods
    
    private func setupViewElementsAndConstraints() {
        view.backgroundColor = .ypBlackIOS
        view.addSubview(imageView)
        
        imageView.image = UIImage(resource: .splashScreenLogo)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
    }
    @MainActor private func switchToTabBarController() {
        DispatchQueue.main.async{
            guard let window = UIApplication.shared.windows.first else {
                assertionFailure("Invalid window configuration")
                return
            }
            let tabBarController = TabBarController()
            window.rootViewController = tabBarController
            window.makeKeyAndVisible()
        }
    }
}

extension SplashViewController: AuthViewControllerDelegate {
    
    func didAuthenticate(_ vc: AuthViewController) {
        DispatchQueue.main.async {
            vc.dismiss(animated: true)
            print("Dismissed: AuthViewController")
        }
        if let token = storage.token {
            fetchProfile(token: token)
        }
    }
}


extension SplashViewController {
    private func fetchProfile(token: String) {
        UIBlockingProgressHUD.show()
        ProfileService.shared.fetchProfile { [weak self] result in
            guard let self else {
                Task { @MainActor in UIBlockingProgressHUD.dismiss() }
                return
            }

            switch result {
            case .success(let profile):
                ProfileImageService.shared.fetchProfileImage(username: profile.username) { result in
                    switch result {
                    case .success(let url):
                        print("Аватарка: \(url)")
                    case .failure(let error):
                        print("Ошибка при загрузке аватарки: \(error)")
                    }
                }
                Task { @MainActor in
                    UIBlockingProgressHUD.dismiss()
                    self.switchToTabBarController()
                }

            case .failure(let error):
                print("❌ [SplashVC] Failed to fetch profile: \(error.localizedDescription) [type=\(type(of: error))]")
                Task { @MainActor in
                    UIBlockingProgressHUD.dismiss()
                    if self.isRateLimitError(error) {
                        self.presentRateLimitScreen()
                    } else {
                        self.showErrorAlert(error)
                    }
                }
            }
        }
    }
    
    private func presentRateLimitScreen() {
        Task { @MainActor in
            guard self.presentedViewController == nil else { return }
            let fallbackVC = CatGameViewController()
            fallbackVC.modalPresentationStyle = .fullScreen
            self.present(fallbackVC, animated: true)
        }
    }
    private func showErrorAlert(_ error: Error) {
        print("called showErrorAlert function with error: \(error)")
        
    }
    private func isRateLimitError(_ error: Error) -> Bool {
        // 1) Проверим рекурсивно на вложенные ошибки типа Cocoa 3840 (invalid JSON)
        if containsCocoa3840(error) { return true }

        // 2) Эвристика по тексту ошибки (иногда enum-ошибка не пробрасывает underlying)
        let combined = (String(describing: error) + " " + error.localizedDescription)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        if combined.contains("rate limit exceeded") { return true }
        if combined.contains("not valid json") && combined.contains("unexpected character") { return true }
        if combined.contains("nscocoaerrordomain") && combined.contains("3840") { return true }
        return false
    }

    /// Рекурсивная проверка: содержит ли ошибка (или её underlying) Cocoa 3840
    private func containsCocoa3840(_ error: Error) -> Bool {
        let ns = error as NSError
        if ns.domain == NSCocoaErrorDomain && ns.code == 3840 { return true }
        if let underlying = ns.userInfo[NSUnderlyingErrorKey] as? Error {
            return containsCocoa3840(underlying)
        }
        return false
    }
}
