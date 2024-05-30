//
//  PhotoDetailViewController.swift
//  PhotoSearch
//
//  Created by Smbat Tumasyan on 29.05.24.
//

import UIKit
import SnapKit
import SDWebImage

class PhotoDetailViewController: UIViewController {
    private let photo: Photo
    private let imageView = UIImageView()
    private let likeButton = UIButton(type: .system)
    private let infoLabel = UILabel()
    
    init(photo: Photo) {
        self.photo = photo
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        configureView()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(imageView)
        imageView.contentMode = .scaleAspectFit
        imageView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(view.snp.width)
        }
        
        view.addSubview(likeButton)
        likeButton.setTitle("Like", for: .normal)
        likeButton.addTarget(self, action: #selector(likeButtonTapped), for: .touchUpInside)
        likeButton.snp.makeConstraints { make in
            make.top.equalTo(imageView.snp.bottom).offset(20)
            make.centerX.equalToSuperview()
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
        let descriptionValue = photo.altDescription ?? "No description"
        
        let infoText = NSMutableAttributedString()
        infoText.append(createAttributedString(title: authorTitle, value: authorValue))
        infoText.append(createAttributedString(title: descriptionTitle, value: descriptionValue))
        
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


    @objc private func likeButtonTapped() {
        // Handle the like button action
        FavoritesManager.shared.addPhoto(photo)
        navigationController?.popViewController(animated: true)
    }
}
