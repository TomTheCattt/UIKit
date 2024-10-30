//
//  CellExtension.swift
//  Project
//
//  Created by Việt Anh Nguyễn on 30/10/2024.
//

import Foundation
import UIKit

extension UICollectionViewCell {
    func setSelectionMode(_ enabled: Bool, isSelected: Bool) {
        if let existingCheckbox = contentView.viewWithTag(999) {
            existingCheckbox.isHidden = !enabled
            (existingCheckbox as? UIImageView)?.image = UIImage(systemName: isSelected ? "checkmark.circle.fill" : "circle")
        } else {
            let checkbox = UIImageView()
            checkbox.tag = 999
            checkbox.tintColor = .systemBlue
            checkbox.contentMode = .scaleAspectFit
            checkbox.translatesAutoresizingMaskIntoConstraints = false
            checkbox.isHidden = !enabled
            checkbox.image = UIImage(systemName: isSelected ? "checkmark.circle.fill" : "circle")
            
            contentView.addSubview(checkbox)
            NSLayoutConstraint.activate([
                checkbox.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
                checkbox.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
                checkbox.widthAnchor.constraint(equalToConstant: 24),
                checkbox.heightAnchor.constraint(equalToConstant: 24)
            ])
        }
        
        if let imageCell = self as? ImageCell {
            imageCell.dimView.isHidden = !isSelected
        } else if let videoCell = self as? VideoCell {
            videoCell.dimView.isHidden = !isSelected
        }
    }
}
