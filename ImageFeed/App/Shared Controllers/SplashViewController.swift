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
    private func switchToTabBarController() {
        DispatchQueue.main.async{
            guard let window = UIApplication.shared.windows.first else {
                assertionFailure("Invalid window configuration")
                return
            }
            let tabBarController = UIStoryboard(name: "Main", bundle: .main)
                .instantiateViewController(withIdentifier: "TabBarViewController")
            window.rootViewController = tabBarController
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
        DispatchQueue.main.async {
        ProfileService.shared.fetchProfile() { [weak self] result in
            guard let self else {
                UIBlockingProgressHUD.dismiss()
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
                UIBlockingProgressHUD.dismiss()
                self.switchToTabBarController()
            case .failure(let error):
                print("❌ [SplashVC] Failed to fetch profile: \(error.localizedDescription)")
                UIBlockingProgressHUD.dismiss()
            }
        }
    }
    }
}
