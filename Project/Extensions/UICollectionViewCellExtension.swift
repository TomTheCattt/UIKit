import Foundation
import UIKit

// MARK: - UICollectionViewCell Extension
/// An extension for `UICollectionViewCell` that adds selection mode functionality.
extension UICollectionViewCell {
    
    /// Configures the cell's selection mode.
    ///
    /// This method shows or hides a checkbox in the cell's content view based on the `enabled` parameter.
    /// If the checkbox already exists, it updates its visibility and image based on the `isSelected` parameter.
    /// If the checkbox does not exist, it creates one, configures it, and adds it to the content view.
    ///
    /// - Parameters:
    ///   - enabled: A boolean value indicating whether the selection mode is enabled.
    ///              If `true`, the checkbox will be visible; if `false`, it will be hidden.
    ///   - isSelected: A boolean value indicating whether the cell is currently selected.
    ///                 If `true`, a checkmark image will be shown; if `false`, a circle will be displayed.
    func setSelectionMode(_ enabled: Bool, isSelected: Bool) {
        if let existingCheckbox = contentView.viewWithTag(999) {
            // Update existing checkbox visibility and image
            existingCheckbox.isHidden = !enabled
            (existingCheckbox as? UIImageView)?.image = UIImage(systemName: isSelected ? "checkmark.circle.fill" : "circle")
        } else {
            // Create and configure a new checkbox
            let checkbox = UIImageView()
            checkbox.tag = 999
            checkbox.tintColor = .systemBlue
            checkbox.contentMode = .scaleAspectFit
            checkbox.translatesAutoresizingMaskIntoConstraints = false
            checkbox.isHidden = !enabled
            checkbox.image = UIImage(systemName: isSelected ? "checkmark.circle.fill" : "circle")
            
            // Add the checkbox to the cell's content view and set constraints
            contentView.addSubview(checkbox)
            NSLayoutConstraint.activate([
                checkbox.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
                checkbox.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
                checkbox.widthAnchor.constraint(equalToConstant: 24),
                checkbox.heightAnchor.constraint(equalToConstant: 24)
            ])
        }
        
        // Update the dim view visibility for specific cell types if applicable
        if let imageCell = self as? ImageCell {
            imageCell.dimView.isHidden = !isSelected
        } else if let videoCell = self as? VideoCell {
            videoCell.dimView.isHidden = !isSelected
        }
    }
}
