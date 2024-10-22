//
//  URLInputDialog.swift
//  Project
//
//  Created by Việt Anh Nguyễn on 22/10/2024.
//

import Foundation
import UIKit

class URLInputDialog {
    weak var delegate: URLInputDialogDelegate?
    private weak var presentingViewController: UIViewController?
    
    init(presentingViewController: UIViewController) {
        self.presentingViewController = presentingViewController
    }
    
    func present() {
        let alertController = UIAlertController(
            title: "Enter URL",
            message: nil,
            preferredStyle: .alert
        )
        
        // Add URL text field
        alertController.addTextField { textField in
            textField.placeholder = "https://example.com/media.jpg"
            textField.keyboardType = .URL
            textField.autocapitalizationType = .none
            textField.autocorrectionType = .no
        }
        
        // Add Save action
        let saveAction = UIAlertAction(title: "Get", style: .default) { [weak self] _ in
            guard let self = self,
                  let urlString = alertController.textFields?.first?.text,
                  !urlString.isEmpty else { return }
            
            self.delegate?.urlInputDialog(self, didEnterURL: urlString)
        }
        
        // Add Cancel action
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
            guard let self = self else { return }
            self.delegate?.urlInputDialogDidCancel(self)
        }
        
        alertController.addAction(saveAction)
        alertController.addAction(cancelAction)
        
        presentingViewController?.present(alertController, animated: true)
    }
}
