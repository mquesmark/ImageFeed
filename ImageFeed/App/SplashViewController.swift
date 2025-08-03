import UIKit

final class SplashViewController: UIViewController {
    private let showAuthenticationScreenSegueIdentifier = "showAuthenticationScreen"
    private let storage = OAuth2TokenStorage.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let token = storage.token {
            fetchProfile(token: token)
        } else {
            performSegue(withIdentifier: showAuthenticationScreenSegueIdentifier, sender: nil)
        }
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
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == showAuthenticationScreenSegueIdentifier {
            guard let navigationController = segue.destination as? UINavigationController,
                  let viewController = navigationController.viewControllers.first as? AuthViewController
            else {
                assertionFailure("Failed to prepare for \(showAuthenticationScreenSegueIdentifier)")
                return
            }
            viewController.delegate = self
        } else {
            super.prepare(for: segue, sender: sender)
        }
    }
    
    func didAuthenticate(_ vc: AuthViewController) {
        DispatchQueue.main.async {
            vc.dismiss(animated: true) }
        if let token = storage.token {
            fetchProfile(token: token)
           // switchToTabBarController()
        }
    }
}


extension SplashViewController {
    private func fetchProfile(token: String) {
        UIBlockingProgressHUD.changeColor(to: .ypBlackIOS)
        UIBlockingProgressHUD.changeAnimationStyle(to: .sfSymbolBounce, symbol: "network")
        UIBlockingProgressHUD.show("Загрузка профиля")
        DispatchQueue.main.async {
        ProfileService.shared.fetchProfile() { [weak self] result in
            guard let self else { return }
            
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
