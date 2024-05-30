//
//  NetworkManager.swift
//  PhotoSearch
//
//  Created by Smbat Tumasyan on 29.05.24.
//

import Foundation
import Combine

class NetworkManager {
    static let shared = NetworkManager()
    
    // MARK: - Private Properties
    private let baseURL = "https://api.unsplash.com/search/photos"
    private let clientID = "UbU4uh5CWpPXyLO9cv7M0rJaRnMuPx52NLRLVuQdD44"
    
    private init() {}
    
    // MARK: - Public Methods
    func fetchPhotos(query: String, page: Int = 1, perPage: Int = 20) -> AnyPublisher<[Photo], Error> {
        let urlString = "\(baseURL)?client_id=\(clientID)&query=\(query)&page=\(page)&per_page=\(perPage)"
        guard let url = URL(string: urlString) else {
            return Fail(error: NetworkError.invalidURL).eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: url)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    throw NetworkError.invalidResponse
                }
                return data
            }
            .decode(type: PhotoResponse.self, decoder: JSONDecoder())
            .map { $0.results }
            .eraseToAnyPublisher()
    }
}

enum NetworkError: Error {
    case invalidURL
    case invalidResponse
    case noData
}
