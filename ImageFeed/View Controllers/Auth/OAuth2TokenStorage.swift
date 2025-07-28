import Foundation

final class OAuth2TokenStorage {
    private let tokenKey = "OAuth2Token"
    
    var token: String? {
        get {
            UserDefaults.standard.string(forKey: tokenKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: tokenKey)
        }
    }
    
    func clearTokenKey() {
        UserDefaults.standard.removeObject(forKey: tokenKey)
    }
}
