import Foundation

final class ProfileService {
    
    static let shared = ProfileService()
    private init() {}
    
    private(set) var profile: Profile?
    
    private var task : URLSessionTask?
    struct ProfileResult: Codable {
        
        let username: String?
        let firstName: String?
        let lastName: String?
        let bio: String?
        
        enum CodingKeys: String, CodingKey {
            case firstName = "first_name"
            case lastName = "last_name"
            case username
            case bio
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
    
    func fetchProfile(completion: @escaping (Result<Profile, Error>) -> Void) {
        assert(Thread.isMainThread)
        task?.cancel()
        guard
            let request = makeURLRequest() else {
            print("❌ [ProfileService] Failed to create profile URL request")
            return
        }
        
        task = NetworkClient.shared.objectTask(for: request) { [weak self] (result: Result<ProfileResult, Error>) in
            switch result {
            case .success(let profileResult):
                let profile = Profile(profileResult: profileResult)
                self?.profile = profile
                completion(.success(profile))
                
            case .failure(let error):
                print("❌ [ProfileService] Failed to fetch profile: \(error)")
                completion(.failure(error))
            }
            self?.task = nil
        }
    }
    
    func clearCachedProfile() {
        profile = nil
    }
    private func makeURLRequest() -> URLRequest? {
        
        guard
            let token = OAuth2TokenStorage.shared.token,
            let url = URL(string: "https://api.unsplash.com/me")
        else {
            print("❌ [ProfileService] Error in creating URLRequest")
            return nil
        }
        
        
        var request = URLRequest (url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        return request
    }
}
