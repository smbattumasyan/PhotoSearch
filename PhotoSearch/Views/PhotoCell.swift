//
//  PhotoCell.swift
//  PhotoSearch
//
//  Created by Smbat Tumasyan on 29.05.24.
//

import UIKit
import SnapKit
import SDWebImage

class PhotoCell: UICollectionViewCell {
    
    // MARK: - Private Properties
    private let imageView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Privete Methods
    private func setupUI() {
        contentView.addSubview(imageView)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    // MARK: - Public Methods
    func configure(with photo: Photo?) {
        if let url = URL(string: photo?.urls.thumb ?? "") {
            imageView.sd_setImage(with: url, placeholderImage: UIImage(named: "placeholder"))
        } else {
            imageView.image = UIImage(named: "placeholder")
        }
    }
}
