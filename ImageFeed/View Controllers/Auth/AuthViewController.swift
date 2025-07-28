import UIKit

protocol AuthViewControllerDelegate: AnyObject {
    func didAuthenticate(_ vc: AuthViewController)
}

final class AuthViewController: UIViewController {
    
    weak var delegate: AuthViewControllerDelegate?
    
    private let loginButton = UIButton()
    private let unsplashLogo = UIImageView()
    private let showWebViewSegueIdentifier = "ShowWebView"
    
    private let oauth2Service = OAuth2Service.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewElements()
        setConstraints()
        configureBackButton()
    }
    
    private func setupViewElements() {
        view.backgroundColor = .ypBlackIOS
        
        view.addSubview(unsplashLogo)
        view.addSubview(loginButton)

        unsplashLogo.image = UIImage(named: "auth_screen_logo")
    
        loginButton.setTitleColor(.ypBlackIOS, for: .normal)
        loginButton.backgroundColor = .ypWhiteIOS
        loginButton.setTitle("Войти", for: .normal)
        loginButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        loginButton.layer.cornerRadius = 16
        loginButton.clipsToBounds = true
        
        let action = UIAction { [weak self] _ in
            self?.performSegue(withIdentifier: self?.showWebViewSegueIdentifier ?? "", sender: nil)
        }
        loginButton.addAction(action, for: .touchUpInside)
    }
    
    private func setConstraints() {
        loginButton.translatesAutoresizingMaskIntoConstraints = false
        unsplashLogo.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            unsplashLogo.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            unsplashLogo.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            unsplashLogo.widthAnchor.constraint(equalToConstant: 60),
            unsplashLogo.heightAnchor.constraint(equalToConstant: 60),
            
            loginButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -90),
            loginButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            loginButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            loginButton.heightAnchor.constraint(equalToConstant: 48)
        ])
    }
    
    private func configureBackButton() {
        navigationController?.navigationBar.backIndicatorImage = UIImage(named: "nav_back_button")
        navigationController?.navigationBar.backIndicatorTransitionMaskImage = UIImage(named: "nav_back_button")
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem?.tintColor = .ypBlackIOS
    }
    
}

extension AuthViewController: WebViewViewControllerDelegate {
    func webViewViewController(_ vc: WebViewViewController, didAuthenticateWithCode code: String) {
        navigationController?.popViewController(animated: true)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self else { return }

            self.oauth2Service.fetchOAuthToken(code: code) { result in
                switch result {
                case .success(let token):
                    print("Токен успешно получен: \(token)")
                    self.delegate?.didAuthenticate(self)
                case .failure(let error):
                    print("Ошибка при получении токена: \(error)")
                }
            }
        }
    }
    
    func webViewViewControllerDidCancel(_ vc: WebViewViewController) {
        dismiss(animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == showWebViewSegueIdentifier,
           let webVC = segue.destination as? WebViewViewController {
            webVC.delegate = self
        }
    }
}
