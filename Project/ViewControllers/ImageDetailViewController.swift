//
//  ImageDetailViewController.swift
//  Project
//
//  Created by Việt Anh Nguyễn on 23/10/2024.
//

import Foundation
import UIKit

// MARK: - ImageDetailViewController.swift

class ImageDetailViewController: UIViewController {
    // MARK: - Properties
    private let imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        //view.backgroundColor = .black
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private var image: AppImage
    
    // MARK: - Initialization
    init(image: AppImage) {
        self.image = image
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadImage()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Ẩn title của navigation bar
        navigationItem.title = nil
        // Làm cho navigation bar trong suốt
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        // Đặt màu nút close thành trắng để dễ nhìn trên nền đen
        navigationController?.navigationBar.tintColor = .black
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Khôi phục lại navigation bar như cũ khi thoát view
        navigationController?.navigationBar.setBackgroundImage(nil, for: .default)
        navigationController?.navigationBar.shadowImage = nil
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .white
        
        // Thêm nút close
        let closeButton = UIBarButtonItem(
            image: UIImage(systemName: "xmark"),
            style: .plain,
            target: self,
            action: #selector(closeTapped)
        )
        navigationItem.rightBarButtonItem = closeButton
        
        // Setup image view
        view.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Setup pinch gesture for zoom
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch))
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(pinchGesture)
    }
    
    private func loadImage() {
        // Kiểm tra và đảm bảo filepath không rỗng
        guard let filepath = image.filepath, !filepath.isEmpty else {
            print("Invalid image file path")
            return
        }

        // Chạy việc tải ảnh trên một luồng nền
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                // Kiểm tra nếu thumbnail có giá trị hợp lệ
                guard let thumbnailData = self?.image.thumbnail else {
                    print("Thumbnail data is nil")
                    return
                }

                // Cố gắng đọc dữ liệu từ thumbnail
                let imageData = Data(thumbnailData)

                // Khởi tạo UIImage từ dữ liệu
                if let image = UIImage(data: imageData) {
                    // Cập nhật UI trên luồng chính
                    DispatchQueue.main.async {
                        self?.imageView.image = image
                    }
                } else {
                    print("Failed to create UIImage from data")
                }
            }
        }
    }


    
    // MARK: - Actions
    @objc private func closeTapped() {
        dismiss(animated: true)
    }
    
    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        if gesture.state == .began || gesture.state == .changed {
            imageView.transform = imageView.transform.scaledBy(
                x: gesture.scale,
                y: gesture.scale
            )
            gesture.scale = 1.0
        }
    }
}
