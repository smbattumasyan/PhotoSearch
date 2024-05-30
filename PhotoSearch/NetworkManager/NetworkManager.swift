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
    private init() {}
    
    func request<T: Decodable>(_ target: UnsplashAPI) -> AnyPublisher<T, Error> {
        URLSession.shared.dataTaskPublisher(for: target.urlRequest)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    throw NetworkError.invalidResponse
                }
                return data
            }
            .decode(type: T.self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
    }
}

enum NetworkError: Error {
    case invalidURL
    case invalidResponse
    case noData
}
