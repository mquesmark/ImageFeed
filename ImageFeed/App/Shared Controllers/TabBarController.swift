import UIKit

final class TabBarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .ypBlackIOS
        let tabbarAppearance = UITabBarAppearance()
        tabbarAppearance.configureWithOpaqueBackground()
        tabbarAppearance.backgroundColor = .ypBlackIOS
        
        if #available(iOS 15.0, *) {
            tabBar.standardAppearance = tabbarAppearance
            tabBar.scrollEdgeAppearance = tabbarAppearance
        }
        
        tabBar.tintColor = .ypWhiteIOS
        let imagesListViewController = ImagesListViewController()
        imagesListViewController.tabBarItem = UITabBarItem(title: nil, image: UIImage(resource: .tabEditorialActive), selectedImage: nil)
        imagesListViewController.tabBarItem.imageInsets = UIEdgeInsets(top: 10, left: 0, bottom: -10, right: 0)

        let profileViewController = ProfileViewController()
        profileViewController.tabBarItem = UITabBarItem(title: nil, image: UIImage(resource: .tabProfileActive), selectedImage: nil)
        profileViewController.tabBarItem.imageInsets = UIEdgeInsets(top: 10, left: 0, bottom: -10, right: 0)
        viewControllers = [imagesListViewController, profileViewController]
    }
}
