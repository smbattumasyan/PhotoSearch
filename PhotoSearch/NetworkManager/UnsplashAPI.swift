//
//  UnsplashAPI.swift
//  PhotoSearch
//
//  Created by Smbat Tumasyan on 30.05.24.
//

import Foundation

enum UnsplashAPI {
    case searchPhotos(query: String, page: Int, perPage: Int)
}

extension UnsplashAPI {
    var baseURL: URL {
        return URL(string: "https://api.unsplash.com")!
    }
    
    var path: String {
        switch self {
        case .searchPhotos:
            return "/search/photos"
        }
    }
    
    var method: String {
        switch self {
        case .searchPhotos:
            return "GET"
        }
    }
    
    var parameters: [String: String] {
        switch self {
        case .searchPhotos(let query, let page, let perPage):
            return [
                "query": query,
                "page": "\(page)",
                "per_page": "\(perPage)",
                "client_id": "UbU4uh5CWpPXyLO9cv7M0rJaRnMuPx52NLRLVuQdD44"
            ]
        }
    }
    
    var urlRequest: URLRequest {
        var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
        components.queryItems = parameters.map { URLQueryItem(name: $0.key, value: $0.value) }
        
        var request = URLRequest(url: components.url!)
        request.httpMethod = method
        return request
    }
}
