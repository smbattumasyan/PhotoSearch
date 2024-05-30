//
//  Photo.swift
//  PhotoSearch
//
//  Created by Smbat Tumasyan on 29.05.24.
//

import Foundation

struct Photo: Decodable, Identifiable, Hashable {
    let id: String
    let description: String?
    let altDescription: String?
    let urls: PhotoURLs
    let createdAt: String // Assuming the date is a string in ISO8601 format

    enum CodingKeys: String, CodingKey {
        case id
        case description
        case altDescription = "alt_description"
        case urls
        case createdAt = "created_at"
    }
}


struct PhotoURLs: Decodable, Hashable {
    let raw: String
    let full: String
    let regular: String
    let small: String
    let thumb: String
}

struct PhotoResponse: Decodable, Hashable {
    let total: Int
    let totalPages: Int
    let results: [Photo]

    enum CodingKeys: String, CodingKey {
        case total
        case totalPages = "total_pages"
        case results
    }
}

private func decodePhotoResponse(data: Data) -> PhotoResponse? {
    let decoder = JSONDecoder()
    do {
        let response = try decoder.decode(PhotoResponse.self, from: data)
        return response
    } catch let DecodingError.dataCorrupted(context) {
        print(context)
    } catch let DecodingError.keyNotFound(key, context) {
        print("Key '\(key)' not found:", context.debugDescription)
        print("codingPath:", context.codingPath)
    } catch let DecodingError.valueNotFound(value, context) {
        print("Value '\(value)' not found:", context.debugDescription)
        print("codingPath:", context.codingPath)
    } catch let DecodingError.typeMismatch(type, context)  {
        print("Type '\(type)' mismatch:", context.debugDescription)
        print("codingPath:", context.codingPath)
    } catch {
        print("error: ", error)
    }

    return nil
}
