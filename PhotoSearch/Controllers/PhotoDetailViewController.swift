//
//  PhotoDetailViewController.swift
//  PhotoSearch
//
//  Created by Smbat Tumasyan on 29.05.24.
//

import UIKit
import SnapKit
import SDWebImage
import Combine

class PhotoDetailViewController: UIViewController {
    
    // MARK: - Private Properties
    private let photo: Photo
    private let imageView = UIImageView()
    private let likeButton = UIButton(type: .system)
    private let infoLabel = UILabel()
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initializers
    init(photo: Photo) {
        self.photo = photo
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        configureView()
        observeFavorites()
    }
    
    // MARK: - Private Methods
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(imageView)
        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = 8
        imageView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(view.snp.width)
        }
        
        view.addSubview(likeButton)
        updateLikeButtonImage()
        likeButton.tintColor = .systemRed
        likeButton.addTarget(self, action: #selector(likeButtonTapped), for: .touchUpInside)
        likeButton.snp.makeConstraints { make in
            make.top.equalTo(imageView.snp.bottom).offset(20)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(40)
        }
        
        view.addSubview(infoLabel)
        infoLabel.numberOfLines = 0
        infoLabel.textAlignment = .center
        infoLabel.snp.makeConstraints { make in
            make.top.equalTo(likeButton.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(20)
        }
    }
    
    private func configureView() {
        if let url = URL(string: photo.urls.thumb) {
            imageView.sd_setImage(with: url, placeholderImage: UIImage(named: "placeholder"))
        } else {
            imageView.image = UIImage(named: "placeholder")
        }
        
        let authorTitle = "Description: "
        let authorValue = (photo.description ?? "") + "\n"
        let descriptionTitle = "AltDescription: "
        let descriptionValue = (photo.altDescription ?? "No description") + "\n"
        
        let dateTitle = "Created At: "
        let dateValue = formattedDate(from: photo.createdAt) + "\n"
        
        let infoText = NSMutableAttributedString()
        infoText.append(createAttributedString(title: authorTitle, value: authorValue))
        infoText.append(createAttributedString(title: descriptionTitle, value: descriptionValue))
        infoText.append(createAttributedString(title: dateTitle, value: dateValue))
        
        infoLabel.attributedText = infoText
        infoLabel.numberOfLines = 0
    }
    
    private func createAttributedString(title: String, value: String) -> NSAttributedString {
        let boldAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 16)
        ]
        let normalAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16)
        ]
        
        let titleAttributedString = NSAttributedString(string: title, attributes: boldAttributes)
        let valueAttributedString = NSAttributedString(string: value, attributes: normalAttributes)
        
        let combinedString = NSMutableAttributedString()
        combinedString.append(titleAttributedString)
        combinedString.append(valueAttributedString)
        
        return combinedString
    }

    private func formattedDate(from isoDateString: String) -> String {
        let isoFormatter = ISO8601DateFormatter()
        if let date = isoFormatter.date(from: isoDateString) {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return formatter.string(from: date)
        }
        return "Unknown date"
    }

    private func updateLikeButtonImage() {
        let isFavorite = FavoritesManager.shared.likedPhotos.contains { $0.id == photo.id }
        let imageName = isFavorite ? "heart.fill" : "heart"
        likeButton.setImage(UIImage(systemName: imageName), for: .normal)
    }
    
    @objc private func likeButtonTapped() {
        if let index = FavoritesManager.shared.likedPhotos.firstIndex(where: { $0.id == photo.id }) {
            FavoritesManager.shared.removePhoto(FavoritesManager.shared.likedPhotos[index])
        } else {
            FavoritesManager.shared.addPhoto(photo)
        }
    }
    
    private func observeFavorites() {
        FavoritesManager.shared.$likedPhotos
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateLikeButtonImage()
            }
            .store(in: &cancellables)
    }
}
