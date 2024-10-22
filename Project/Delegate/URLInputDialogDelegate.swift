//
//  URLInputDialogDelegate.swift
//  Project
//
//  Created by Việt Anh Nguyễn on 22/10/2024.
//

import Foundation

protocol URLInputDialogDelegate: AnyObject {
    func urlInputDialog(_ dialog: URLInputDialog, didEnterURL urlString: String)
    func urlInputDialogDidCancel(_ dialog: URLInputDialog)
}
