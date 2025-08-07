import Foundation

final class NetworkClient {
    static let shared = NetworkClient()
    private init(){}
    
    private let decoder = JSONDecoder()

    
    func fetch(request: URLRequest, completion: @escaping (Result<Data, Error>) -> Void) -> URLSessionTask {
        let task = URLSession.shared.data(for: request, completion: completion)
        task.resume()
        return task
    }
    
    func objectTask<T: Decodable>(
        for request: URLRequest,
        completion: @escaping (Result<T, Error>) -> Void
    ) -> URLSessionTask {
        print("📡 [NetworkClient] Starting objectTask with request: \(request.url?.absoluteString ?? "nil URL")")
        let task = URLSession.shared.data(for: request) { (result: Result<Data, Error>) in
            switch result {
            case .success(let data):
                do {
                    let decoded = try self.decoder.decode(T.self, from: data)
                    print("✅ [NetworkClient] Decoded object: \(decoded)")
                    completion(.success(decoded))
                } catch {
                    print("❌ [NetworkClient] Decoding failed: \(error.localizedDescription), data: \(String(data: data, encoding: .utf8) ?? "")")
                    print("📦 [NetworkClient] Raw data: \(String(data: data, encoding: .utf8) ?? "nil")")
                    completion(.failure(NetworkError.decodingError(error)))
                }
            case .failure(let error):
                print("❌ [NetworkClient] dataTask failed with error: \(error)")
                completion(.failure(error))
            }
        }
        return task
    }
}
