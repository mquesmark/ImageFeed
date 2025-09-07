import Kingfisher
import UIKit

@MainActor
protocol ProfileViewControllerProtocol: AnyObject {
    func showProfileDetails(
        personName: String,
        username: String,
        profileDescription: String
    )
    func showAvatar(url: URL)
    func showLogoutAlert()
}

@MainActor
final class ProfileViewController: UIViewController,
    ProfileViewControllerProtocol
{
    private let userPicImageView = UIImageView()
    private let personNameLabel = UILabel()
    private let usernameLabel = UILabel()
    private let profileDescriptionLabel = UILabel()
    private let exitButton = UIButton()
    private let debugSkeletonButton = UIButton(type: .system)

    var presenter: ProfilePresenterProtocol?
    private var animationLayers = [CALayer]()
    private var infoDidLoaded: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewElements()
        setConstraints()
        if presenter == nil {
            presenter = ProfilePresenter()
        }
        presenter?.view = self
        presenter?.viewDidLoad()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        userPicImageView.layer.cornerRadius = userPicImageView.bounds.height / 2
        updateGradientFramesIfNeeded()
    }
    
    private func updateGradientFramesIfNeeded() {
        for layer in animationLayers {
            guard let bounds = layer.superlayer?.bounds else { continue }
            layer.frame = bounds
            layer.cornerRadius = (layer.superlayer?.cornerRadius ?? 0) > 0 ? (layer.superlayer?.cornerRadius ?? 0) : 9
        }
    }
    
    private func setupViewElements() {
        view.backgroundColor = .ypBlackIOS

        userPicImageView.translatesAutoresizingMaskIntoConstraints = false
        userPicImageView.image = UIImage(named: "no_profile_pic")
        userPicImageView.clipsToBounds = true
        userPicImageView.isHidden = false

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
        profileDescriptionLabel.translatesAutoresizingMaskIntoConstraints =
            false
        profileDescriptionLabel.numberOfLines = 0
        profileDescriptionLabel.lineBreakMode = .byWordWrapping

        exitButton.setImage(UIImage(named: "Exit"), for: .normal)
        exitButton.addAction(
            UIAction { [weak self] _ in
                self?.presenter?.didTapLogout()
            },
            for: .touchUpInside
        )
        exitButton.translatesAutoresizingMaskIntoConstraints = false
        exitButton.isHidden = true
        exitButton.accessibilityIdentifier = "exitButton"
        view.addSubview(userPicImageView)
        view.addSubview(personNameLabel)
        view.addSubview(usernameLabel)
        view.addSubview(profileDescriptionLabel)
        view.addSubview(exitButton)

        // DEBUG: toggle skeleton animations
        let iconName = "stop.circle" // will be updated after setSkeletonActive in viewDidLoad
        debugSkeletonButton.setImage(UIImage(systemName: iconName), for: .normal)
        debugSkeletonButton.imageView?.contentMode = .scaleAspectFit
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
        debugSkeletonButton.setPreferredSymbolConfiguration(symbolConfig, forImageIn: .normal)
        debugSkeletonButton.adjustsImageWhenHighlighted = false
        debugSkeletonButton.tintColor = .white
        debugSkeletonButton.backgroundColor = UIColor.white.withAlphaComponent(0.12)
        debugSkeletonButton.layer.cornerRadius = 18
        debugSkeletonButton.layer.masksToBounds = true
        debugSkeletonButton.layer.borderWidth = 1
        debugSkeletonButton.layer.borderColor = UIColor.white.withAlphaComponent(0.18).cgColor
        debugSkeletonButton.translatesAutoresizingMaskIntoConstraints = false
        debugSkeletonButton.accessibilityIdentifier = "debugSkeletonButton"
        debugSkeletonButton.addAction(UIAction { [weak self] _ in
            self?.didTapDebugSkeleton()
        }, for: .touchUpInside)
        view.addSubview(debugSkeletonButton)
    }

    private func setConstraints() {
        NSLayoutConstraint.activate([
            userPicImageView.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor,
                constant: 32
            ),
            userPicImageView.leadingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.leadingAnchor,
                constant: 16
            ),
            userPicImageView.widthAnchor.constraint(equalToConstant: 70),
            userPicImageView.heightAnchor.constraint(equalToConstant: 70),

            personNameLabel.topAnchor.constraint(
                equalTo: userPicImageView.bottomAnchor,
                constant: 8
            ),
            personNameLabel.leadingAnchor.constraint(
                equalTo: userPicImageView.leadingAnchor
            ),

            usernameLabel.topAnchor.constraint(
                equalTo: personNameLabel.bottomAnchor,
                constant: 8
            ),
            usernameLabel.leadingAnchor.constraint(
                equalTo: userPicImageView.leadingAnchor
            ),

            profileDescriptionLabel.topAnchor.constraint(
                equalTo: usernameLabel.bottomAnchor,
                constant: 8
            ),
            profileDescriptionLabel.leadingAnchor.constraint(
                equalTo: usernameLabel.leadingAnchor
            ),

            exitButton.centerYAnchor.constraint(
                equalTo: userPicImageView.centerYAnchor
            ),
            exitButton.widthAnchor.constraint(equalToConstant: 44),
            exitButton.heightAnchor.constraint(equalToConstant: 44),
            exitButton.trailingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.trailingAnchor,
                constant: -16
            ),

            debugSkeletonButton.topAnchor.constraint(equalTo: exitButton.bottomAnchor, constant: 8),
            debugSkeletonButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            debugSkeletonButton.heightAnchor.constraint(equalToConstant: 36),
            debugSkeletonButton.widthAnchor.constraint(equalToConstant: 36),
        ])
    }

    func showProfileDetails(
        personName: String,
        username: String,
        profileDescription: String

    ) {
        personNameLabel.text = personName
        usernameLabel.text = username
        profileDescriptionLabel.text = profileDescription
        exitButton.isHidden = false
        setSkeletonActive(false)
    }

    func showAvatar(url: URL) {
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
                .forceRefresh,
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

    func showLogoutAlert() {

        let yesAction = UIAlertAction(title: "Да", style: .default) {
            [weak self] _ in
            self?.presenter?.userConfirmedLogout()
        }
        let noAction = UIAlertAction(title: "Нет", style: .cancel) { _ in
            return
        }
        AlertService.shared.showAlert(
            withTitle: "Пока, пока!",
            andMessage: "Уверены, что хотите выйти?",
            withActions: [
                yesAction,
                noAction,

            ],
            withAccessibilityIdentifier: "confirmLogoutAlert",
            on: self
        )

    }
    
    @objc private func didTapDebugSkeleton() {
        if infoDidLoaded { // currently content shown, skeleton OFF -> turn ON
            setSkeletonActive(true)
        } else { // skeleton ON -> turn OFF
            setSkeletonActive(false)
        }
    }
    
    func addGradientLayer (to views: [UIView]) {
        for view in views {
            if (view.layer.sublayers?.contains(where: { $0.name == "shimmer" })) == true {
                continue
            }
            let gradient = CAGradientLayer()
            gradient.name = "shimmer"
            // Fit gradient exactly to the view bounds; we'll move the highlight via locations
            gradient.frame = view.bounds

            // Colors for shimmer: dark – light – dark
            gradient.colors = [
                UIColor(white: 0.45, alpha: 1).cgColor,
                UIColor(white: 0.60, alpha: 1).cgColor,
                UIColor(white: 0.45, alpha: 1).cgColor
            ]
            gradient.locations = [-1, -0.5, 0] as [NSNumber]
            gradient.startPoint = CGPoint(x: 0, y: 0.5)
            gradient.endPoint = CGPoint(x: 1, y: 0.5)
            gradient.cornerRadius = view.layer.cornerRadius > 0 ? view.layer.cornerRadius : 9
            gradient.masksToBounds = true
            view.layer.addSublayer(gradient)
            animationLayers.append(gradient)

            let animation = CABasicAnimation(keyPath: "locations")
            animation.fromValue = [-0.6, -0.3, 0.0]
            animation.toValue   = [1.0, 1.3, 1.6]
            animation.duration = 1.4
            animation.timingFunction = CAMediaTimingFunction(name: .linear)
            animation.repeatCount = .infinity
            animation.isRemovedOnCompletion = false
            gradient.add(animation, forKey: "shimmerLocations")
        }
    }
    
    private func removeGradients() {
        animationLayers.forEach { $0.removeFromSuperlayer() }
        animationLayers.removeAll()
    }

    private func setSkeletonActive(_ on: Bool) {
        if on {
            addGradientLayer(to: [userPicImageView, personNameLabel, usernameLabel, profileDescriptionLabel])
        } else {
            removeGradients()
        }
        infoDidLoaded = !on
//        userPicImageView.alpha = on ? 0 : 1
//        personNameLabel.alpha = on ? 0 : 1
//        usernameLabel.alpha = on ? 0 : 1
//        profileDescriptionLabel.alpha = on ? 0 : 1
        if on {
            personNameLabel.textColor = view.backgroundColor
            usernameLabel.textColor = view.backgroundColor
            profileDescriptionLabel.textColor = view.backgroundColor
        } else {
            personNameLabel.textColor = UIColor(named: "YP White (iOS)")
            usernameLabel.textColor = UIColor(named: "YP Gray (iOS)")
            profileDescriptionLabel.textColor = UIColor(named: "YP White (iOS)")
        }
        let icon = on ? "stop.circle" : "sparkles"
        debugSkeletonButton.setImage(UIImage(systemName: icon), for: .normal)
    }
}
