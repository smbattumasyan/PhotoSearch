//
//  FavoritesManager.swift
//  PhotoSearch
//
//  Created by Smbat Tumasyan on 30.05.24.
//

import Foundation
import Combine

class FavoritesManager {
    static let shared = FavoritesManager()
    
    // MARK: - Private Properties
    @Published private(set) var likedPhotos: [Photo] = []
    
    private init() {}
    
    // MARK: - Public Properties
    func addPhoto(_ photo: Photo) {
        likedPhotos.append(photo)
    }
    
    func removePhoto(_ photo: Photo) {
        likedPhotos.removeAll { $0.id == photo.id }
    }
}

