import WebKit
import Kingfisher

@MainActor
final class ProfileLogoutService {
    static let shared = ProfileLogoutService()
    private init() {}
    
    func logout() {
        UIBlockingProgressHUD.show()
        cleanCookiesAndCache { [weak self] in
            UIBlockingProgressHUD.dismiss()
            self?.cleanAppData()
            self?.switchToStartScreen()
        }
    }
    private func switchToStartScreen() {
        let startVC = SplashViewController()
        let window = UIApplication.shared
            .connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
        guard let window else { return }
        
        UIView.transition(with: window, duration: 0.25, options: .transitionCrossDissolve, animations: {
               window.rootViewController = startVC
               window.makeKeyAndVisible()
           }, completion: nil)
    }
    private func cleanCookiesAndCache(completion: @escaping () -> Void) {
        HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)
        WKWebsiteDataStore.default().fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
            records.forEach{ record in
                WKWebsiteDataStore.default().removeData(ofTypes: record.dataTypes, for: [record], completionHandler: {})
                
            }
        }
        URLCache.shared.removeAllCachedResponses()
        KingfisherManager.shared.cache.clearMemoryCache()
        KingfisherManager.shared.cache.clearDiskCache {
            completion()
        }
    }
    
    private func cleanAppData() {
        OAuth2TokenStorage.shared.token = nil
        ProfileService.shared.clearCachedProfile()
        ProfileImageService.shared.clearImageURL()
        ImagesListService.shared.clearFeed()
        
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }
    }
}
