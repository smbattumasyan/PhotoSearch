//
//  PhotosViewController.swift
//  PhotoSearch
//
//  Created by Smbat Tumasyan on 29.05.24.
//

import UIKit
import Combine
import SnapKit

class PhotosViewController: UIViewController {
    private var collectionView: UICollectionView!
    private var searchBar: UISearchBar!
    private var viewModel = PhotosViewModel()
    private var cancellables = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
        viewModel.fetchPhotos(query: "green") // Initial fetch
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Set up search bar
        searchBar = UISearchBar()
        searchBar.delegate = self
        view.addSubview(searchBar)
        searchBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
        }
        
        // Set up collection view
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: view.frame.width / 2 - 16, height: view.frame.width / 2 - 16)
        layout.minimumLineSpacing = 8
        layout.minimumInteritemSpacing = 8
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(PhotoCell.self, forCellWithReuseIdentifier: "PhotoCell")
        collectionView.backgroundColor = .systemBackground
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(searchBar.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview().inset(8)
        }
        
        // Set up pull-to-refresh
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshPhotos), for: .valueChanged)
        collectionView.refreshControl = refreshControl
    }
    
    private func bindViewModel() {
        viewModel.$photos
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.collectionView.reloadData()
                self?.collectionView.refreshControl?.endRefreshing()
            }
            .store(in: &cancellables)
        
        viewModel.$error
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { error in
                print("Error fetching photos: \(error)")
                // Handle error (e.g., show an alert)
            }
            .store(in: &cancellables)
    }
    
    @objc private func refreshPhotos() {
        viewModel.fetchPhotos(query: searchBar.text ?? "green")
    }
}

extension PhotosViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.photos.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath) as! PhotoCell
        let photo = viewModel.photos[indexPath.item]
        cell.configure(with: photo)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let photo = viewModel.photos[indexPath.item]
        let detailVC = PhotoDetailViewController(photo: photo)
//        navigationController?.pushViewController(detailVC, animated: true)
        present(detailVC, animated: true)
    }
}

extension PhotosViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let query = searchBar.text else { return }
        viewModel.fetchPhotos(query: query)
    }
}
