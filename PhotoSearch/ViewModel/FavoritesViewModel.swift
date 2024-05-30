//
//  FavoritesViewModel.swift
//  PhotoSearch
//
//  Created by Smbat Tumasyan on 30.05.24.
//

import Foundation
import Combine

class FavoritesViewModel: ObservableObject {
    
    // MARK: - Public Properties
    @Published var likedPhotos: [Photo] = []
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Privete Methods
    init() {
        FavoritesManager.shared.$likedPhotos
            .receive(on: DispatchQueue.main)
            .assign(to: \.likedPhotos, on: self)
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    func photo(at index: Int) -> Photo? {
        guard index >= 0 && index < likedPhotos.count else {
            return nil
        }
        return likedPhotos[index]
    }
}
