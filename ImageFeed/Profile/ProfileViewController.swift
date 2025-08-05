import UIKit
import Kingfisher

final class ProfileViewController: UIViewController {
    
    private let userPicImageView = UIImageView()
    private let personNameLabel = UILabel()
    private let usernameLabel = UILabel()
    private let profileDescriptionLabel = UILabel()
    private let exitButton = UIButton()
    
    private var profileImageServiceObserver: NSObjectProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewElements()
        setConstraints()
        updateProfileDetails()
        
        profileImageServiceObserver = NotificationCenter.default.addObserver(
            forName: ProfileImageService.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            self.updateAvatar()
        }
        updateAvatar()
    }
    
    private func setupViewElements() {
        view.backgroundColor = .ypBlackIOS
        
        userPicImageView.translatesAutoresizingMaskIntoConstraints = false
        userPicImageView.image = UIImage(named: "no_profile_pic")
        userPicImageView.clipsToBounds = true
        userPicImageView.isHidden = true
        
        personNameLabel.text = ""
        personNameLabel.font = UIFont.systemFont(ofSize: 23, weight: .bold)
        personNameLabel.textColor = UIColor(named: "YP White (iOS)")
        personNameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        usernameLabel.text = ""
        usernameLabel.font = UIFont.systemFont(ofSize: 13)
        usernameLabel.textColor = UIColor(named: "YP Gray (iOS)")
        usernameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        profileDescriptionLabel.text = ""
        profileDescriptionLabel.font = UIFont.systemFont(ofSize: 13)
        profileDescriptionLabel.textColor = UIColor(named: "YP White (iOS)")
        profileDescriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        profileDescriptionLabel.numberOfLines = 0
        profileDescriptionLabel.lineBreakMode = .byWordWrapping
        
        exitButton.setImage(UIImage(named: "Exit"), for: .normal)
        exitButton.addAction(UIAction { _ in
            OAuth2TokenStorage.shared.clearTokenKey()
            print("Successfully logged out")
            WebViewViewController.clearWebViewData {
                print("Exiting")
                exit(0)
            }
        }, for: .touchUpInside)
        exitButton.translatesAutoresizingMaskIntoConstraints = false
        exitButton.isHidden = true
        view.addSubview(userPicImageView)
        view.addSubview(personNameLabel)
        view.addSubview(usernameLabel)
        view.addSubview(profileDescriptionLabel)
        view.addSubview(exitButton)
        
        
        
    }
    
    private func setConstraints() {
        NSLayoutConstraint.activate([
            userPicImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 32),
            userPicImageView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            userPicImageView.widthAnchor.constraint(equalToConstant: 70),
            userPicImageView.heightAnchor.constraint(equalToConstant: 70),
            
            personNameLabel.topAnchor.constraint(equalTo: userPicImageView.bottomAnchor, constant: 8),
            personNameLabel.leadingAnchor.constraint(equalTo: userPicImageView.leadingAnchor),
            
            usernameLabel.topAnchor.constraint(equalTo: personNameLabel.bottomAnchor, constant: 8),
            usernameLabel.leadingAnchor.constraint(equalTo: userPicImageView.leadingAnchor),
            
            profileDescriptionLabel.topAnchor.constraint(equalTo: usernameLabel.bottomAnchor, constant: 8),
            profileDescriptionLabel.leadingAnchor.constraint(equalTo: usernameLabel.leadingAnchor),
            
            exitButton.centerYAnchor.constraint(equalTo: userPicImageView.centerYAnchor),
            exitButton.widthAnchor.constraint(equalToConstant: 44),
            exitButton.heightAnchor.constraint(equalToConstant: 44),
            exitButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16)
        ])
        
        DispatchQueue.main.async {
            self.userPicImageView.layer.cornerRadius = self.userPicImageView.bounds.height / 2
        }
    }
    
    private func updateProfileDetails() {
        if let profile = ProfileService.shared.profile {
            personNameLabel.text = profile.name
            usernameLabel.text = profile.loginName
            profileDescriptionLabel.text = profile.bio
            exitButton.isHidden = false
            userPicImageView.isHidden = false
        }
    }
    
    private func updateAvatar () {
        guard
            let profileImageURL = ProfileImageService.shared.avatarURL,
            let url = URL(string: profileImageURL)
        else { return }
        let placeholderImage = UIImage(named: "no_profile_pic")
        let processor = RoundCornerImageProcessor(cornerRadius: 35)
        userPicImageView.kf.indicatorType = .activity
        userPicImageView.kf.setImage(
            with: url,
            placeholder: placeholderImage,
            options: [
                .processor(processor),
                .scaleFactor(UIScreen.main.scale),
                .cacheOriginalImage,
                .forceRefresh
            ]
        ) {
            result in
            switch result {
            case .success(let value):
                print(value.image)
                print(value.cacheType)
                print(value.source)
            case .failure(let error):
                print(error)
            }
        }
    }
    
}
