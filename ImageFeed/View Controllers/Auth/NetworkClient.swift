import Foundation

final class NetworkClient {
    static let shared = NetworkClient()
    
    func fetch(request: URLRequest, completion: @escaping (Result<Data, Error>) -> Void) {
        let task = URLSession.shared.data(for: request, completion: completion)
        task.resume()
    }
}
