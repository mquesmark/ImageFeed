import Foundation

final class OAuth2Service {
    static let shared = OAuth2Service()
    private init() {}

    private func makeOAuthTokenRequest(code: String) -> URLRequest? {
        guard var urlComponents = URLComponents(string: "https://unsplash.com/oauth/token") else { print("URLComponents failed"); return nil}
        
        urlComponents.queryItems = [
            URLQueryItem(name: "client_id", value: Constants.accessKey),
            URLQueryItem(name: "client_secret", value: Constants.secretKey),
            URLQueryItem(name: "redirect_uri", value: Constants.redirectURI),
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "grant_type", value: "authorization_code")
            ]
        
        guard let authTokenUrl = urlComponents.url else { print("URL failed"); return nil }
        
        var request = URLRequest(url: authTokenUrl)
        request.httpMethod = "POST"
        return request
    }
    
    func fetchOAuthToken(code: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let request = makeOAuthTokenRequest(code: code) else { print("Request failed"); completion(.failure(OAuthError.invalidRequest)); return}
        NetworkClient.shared.fetch(request: request) { result in
            switch result {
            case .success(let data):
                do {
                    let decoded = try JSONDecoder().decode(OAuthTokenResponseBody.self, from: data)
                    OAuth2TokenStorage().token = decoded.access_token
                    completion(.success(decoded.access_token))
                } catch {
                    print("JSON decoding failed: \(error)")
                    completion(.failure(OAuthError.networkError(error)))
                }
            case .failure(let error):
                print("Network error: \(error)")
                completion(.failure(error))
            }
        }
    }
}

private struct OAuthTokenResponseBody: Decodable {
    let access_token: String
}

enum OAuthError: Error {
    case invalidRequest
    case networkError(Error)
}
