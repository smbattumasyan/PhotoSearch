//
//  PhotosViewModel.swift
//  PhotoSearch
//
//  Created by Smbat Tumasyan on 29.05.24.
//

import Foundation
import Combine

class PhotosViewModel: ObservableObject {
    
    // MARK: - Public Properties
    @Published var photos: [Photo] = []
    @Published var error: Error?
    @Published var isLoading = false // To indicate if a fetch operation is ongoing

    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private var currentPage = 1
    private var currentQuery = ""
    private var isLastPage = false

    // MARK: - Public Methods
    func fetchPhotos(query: String, page: Int = 1, perPage: Int = 20) {
        guard !isLoading && !isLastPage else { return }
        
        isLoading = true
        if page == 1 {
            photos = [] // Clear previous results when it's a new query
        }
        
        NetworkManager.shared.request(UnsplashAPI.searchPhotos(query: query, page: page, perPage: perPage))
            .sink { [weak self] completion in
                guard let self = self else { return }
                self.isLoading = false
                switch completion {
                case .failure(let error):
                    DispatchQueue.main.async {
                        self.error = error
                    }
                case .finished:
                    break
                }
            } receiveValue: { [weak self] (photosResponse: PhotoResponse) in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    if photosResponse.results.isEmpty {
                        self.isLastPage = true
                    } else {
                        self.photos.append(contentsOf: photosResponse.results)
                    }
                }
            }
            .store(in: &cancellables)
        
        currentQuery = query
        currentPage = page
    }
    
    func fetchNextPage(perPage: Int = 20) {
        guard !isLoading && !isLastPage else { return }
        fetchPhotos(query: currentQuery, page: currentPage + 1, perPage: perPage)
    }
    
    func photo(at index: Int) -> Photo? {
        guard index >= 0 && index < photos.count else {
            return nil
        }
        return photos[index]
    }
}
