import Foundation

final class ProfileService {
    
    struct ProfileResult: Codable {
        
        let username: String?
        let firstName: String?
        let lastName: String?
        let bio: String?
        
        enum CodingKeys: String, CodingKey {
            case username = "username"
            case firstName = "first_name"
            case lastName = "last_name"
            case bio = "bio"
        }
        
    }
    
    struct Profile {
        let username: String
        let name: String
        let loginName: String
        let bio: String
        
        init(profileResult: ProfileResult) {
            username = profileResult.username ?? ""
            name = "\(profileResult.firstName ?? "") \(profileResult.lastName ?? "")"
            loginName = "@\(username)"
            bio = profileResult.bio ?? ""
        }
    }
    
    func makeURLRequest(for username: String) -> URLRequest? {
        guard
            let token = OAuth2TokenStorage.shared.token else {
            return nil
        }
        
        guard let url = URL(string: "https://api.unsplash.com/me") else {
            return nil
        }
        
        var request = URLRequest (url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        return request
    }
}
