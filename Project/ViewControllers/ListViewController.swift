//
//  ListViewController.swift
//  Project
//
//  Created by Việt Anh Nguyễn on 14/10/2024.
//

import UIKit
import CoreData
import Photos

class ListViewController: UIViewController {
    
    // MARK: - Properties
    
    weak var delegate: ListViewControllerDelegate?
    var selectedCategory: CategoryType?
    private var collectionView: UICollectionView!
    private var dataSource: [NSManagedObject] = []
    private var noDataLabel: UILabel!
    private var updateFromAlbumButton: UIButton!
    private var updateFromLinkButton: UIButton!
    private var urlInputView: URLInputView?
    
    private let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        setupNavigationTitle()
        setupCollectionView()
        setupNavigationBar()
        setupNoDataLabel()
        setupUpdateButtons()
        loadData()
    }
    
    // MARK: - UI Setup
    
    private func setupNavigationTitle() {
        if let selectedCategory = selectedCategory {
            switch selectedCategory {
            case .image:
                title = "All Images"
            case .video:
                title = "All Videos"
            }
        }
    }
    
    private func setupNavigationBar() {
        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addButtonTapped))
        navigationItem.rightBarButtonItem = addButton
    }
    
    private func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 10
        layout.minimumLineSpacing = 10
        
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.backgroundColor = .systemBackground
        collectionView.delegate = self
        collectionView.dataSource = self
        
        collectionView.register(VideoCell.self, forCellWithReuseIdentifier: "VideoCell")
        collectionView.register(ImageCell.self, forCellWithReuseIdentifier: "ImageCell")
        
        view.addSubview(collectionView)
    }
    
    private func setupNoDataLabel() {
        noDataLabel = UILabel()
        noDataLabel.text = "No data available for this category."
        noDataLabel.textAlignment = .center
        noDataLabel.textColor = .gray
        noDataLabel.isHidden = true
        view.addSubview(noDataLabel)
        
        noDataLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            noDataLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            noDataLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func setupUpdateButtons() {
        updateFromAlbumButton = UIButton(type: .system)
        updateFromAlbumButton.setTitle("Update from Album", for: .normal)
        updateFromAlbumButton.addTarget(self, action: #selector(updateFromAlbumTapped), for: .touchUpInside)
        
        updateFromLinkButton = UIButton(type: .system)
        updateFromLinkButton.setTitle("Update from Link", for: .normal)
        updateFromLinkButton.addTarget(self, action: #selector(updateFromLinkTapped), for: .touchUpInside)
        
        let stackView = UIStackView(arrangedSubviews: [updateFromAlbumButton, updateFromLinkButton])
        stackView.axis = .vertical
        stackView.spacing = 10
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.topAnchor.constraint(equalTo: noDataLabel.bottomAnchor, constant: 20),
            stackView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8)
        ])
    }
    
    // MARK: - Data Loading
    
    private func loadData() {
        guard let category = selectedCategory else { return }
        
        let fetchRequest: NSFetchRequest<NSManagedObject>
        switch category {
        case .video:
            fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "AppVideo")
        case .image:
            fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "AppImage")
        }
        
        do {
            dataSource = try context.fetch(fetchRequest)
            dataSource.sort {
                ($0.value(forKey: "title") as? String ?? "") < ($1.value(forKey: "title") as? String ?? "")
            }
        } catch {
            print("Error fetching data: \(error)")
        }
        
        updateUI()
    }
    
    // MARK: - UI Update
    
    private func updateUI() {
        let isEmpty = dataSource.isEmpty
        collectionView.isHidden = isEmpty
        noDataLabel.isHidden = !isEmpty
        updateFromAlbumButton.isHidden = !isEmpty
        updateFromLinkButton.isHidden = !isEmpty
        
        if !isEmpty {
            collectionView.reloadData()
        }
    }
    
    // MARK: - Update Actions
    
    @objc private func updateFromAlbumTapped() {
        requestPhotoLibraryAccess { [weak self] granted in
            guard granted else {
                self?.showPhotoLibraryAccessDeniedAlert()
                return
            }
            self?.selectedCategory == .image ? self?.fetchImagesFromAlbum() : self?.fetchVideosFromAlbum()
        }
    }
    
    @objc private func updateFromLinkTapped() {
        // Placeholder for URL input and download logic
        showURLInputView()
    }
    
    // MARK: - Media Handling
    
    // MARK: - Download and Save to Album
        
        func downloadAndSaveMedia(from url: URL, isVideo: Bool, completion: @escaping (Bool) -> Void) {
            let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
                guard let self = self, let data = data, error == nil else {
                    DispatchQueue.main.async { completion(false) }
                    return
                }
                
                if isVideo {
                    self.saveVideoToAlbum(data: data, completion: completion)
                } else {
                    self.saveImageToAlbum(data: data, completion: completion)
                }
            }
            task.resume()
        }
        
        private func saveImageToAlbum(data: Data, completion: @escaping (Bool) -> Void) {
            guard let image = UIImage(data: data) else {
                DispatchQueue.main.async { completion(false) }
                return
            }
            
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }) { success, error in
                if success {
                    self.fetchImagesFromAlbum()
                }
                DispatchQueue.main.async { completion(success) }
            }
        }
        
        private func saveVideoToAlbum(data: Data, completion: @escaping (Bool) -> Void) {
            let tempUrl = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("tempVideo.mp4")
            do {
                try data.write(to: tempUrl)
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: tempUrl)
                }) { success, error in
                    if success {
                        self.fetchVideosFromAlbum()
                    }
                    DispatchQueue.main.async { completion(success) }
                    try? FileManager.default.removeItem(at: tempUrl)
                }
            } catch {
                DispatchQueue.main.async { completion(false) }
            }
        }
    
    private func fetchImagesFromAlbum() {
        let fetchResult = PHAsset.fetchAssets(with: .image, options: PHFetchOptions())
        fetchResult.enumerateObjects { [weak self] asset, _, _ in
            self?.saveImageToCoreData(from: asset)
        }
        loadData()
    }
    
    private func fetchVideosFromAlbum() {
        let fetchResult = PHAsset.fetchAssets(with: .video, options: PHFetchOptions())
        fetchResult.enumerateObjects { [weak self] asset, _, _ in
            self?.saveVideoToCoreData(from: asset)
        }
        loadData()
    }
    
    private func saveImageToCoreData(from asset: PHAsset) {
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.isSynchronous = true
        options.deliveryMode = .highQualityFormat
        
        manager.requestImage(for: asset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFit, options: options) { [weak self] image, info in
            guard let self = self, let image = image else { return }
            
            let newImage = AppImage(context: self.context)
            newImage.id = UUID()
            newImage.title = asset.localIdentifier
            
            // Save image to documents directory and get file path
            if let imagePath = self.saveImageToDocuments(image: image, withName: newImage.id?.uuidString ?? "unknown") {
                newImage.filepath = imagePath
            }
            
            if let thumbnailData = image.jpegData(compressionQuality: 0.5) {
                newImage.thumbnail = thumbnailData
            }
            
            do {
                try self.context.save()
            } catch {
                print("Error saving image to CoreData: \(error)")
            }
        }
    }
    
    private func saveVideoToCoreData(from asset: PHAsset) {
        let manager = PHImageManager.default()
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat
        
        manager.requestAVAsset(forVideo: asset, options: options) { [weak self] (avAsset, _, _) in
            guard let self = self, let urlAsset = avAsset as? AVURLAsset else { return }
            
            let newVideo = AppVideo(context: self.context)
            newVideo.id = UUID()
            newVideo.title = asset.localIdentifier
            newVideo.duration = asset.duration
            
            // Save video to documents directory and get file path
            if let videoPath = self.saveVideoToDocuments(from: urlAsset.url, withName: newVideo.id?.uuidString ?? "unknown") {
                newVideo.filepath = videoPath
            }
            
            // Generate thumbnail
            if let thumbnailImage = self.generateThumbnail(for: urlAsset) {
                newVideo.thumbnail = thumbnailImage.jpegData(compressionQuality: 0.5)
            }
            
            do {
                try self.context.save()
            } catch {
                print("Error saving video to CoreData: \(error)")
            }
        }
    }
    
    private func saveImageToDocuments(image: UIImage, withName name: String) -> String? {
        guard let data = image.jpegData(compressionQuality: 1.0) else { return nil }
        let filename = name + ".jpg"
        let filepath = getDocumentsDirectory().appendingPathComponent(filename)
        
        do {
            try data.write(to: filepath)
            return filepath.path
        } catch {
            print("Error saving image to documents: \(error)")
            return nil
        }
    }
    
    private func saveVideoToDocuments(from sourceURL: URL, withName name: String) -> String? {
        let filename = name + ".mp4"
        let destinationURL = getDocumentsDirectory().appendingPathComponent(filename)
        
        do {
            try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
            return destinationURL.path
        } catch {
            print("Error saving video to documents: \(error)")
            return nil
        }
    }
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private func generateThumbnail(for video: AVAsset) -> UIImage? {
        let assetImgGenerate = AVAssetImageGenerator(asset: video)
        assetImgGenerate.appliesPreferredTrackTransform = true
        
        let time = CMTimeMakeWithSeconds(1.0, preferredTimescale: 600)
        do {
            let img = try assetImgGenerate.copyCGImage(at: time, actualTime: nil)
            return UIImage(cgImage: img)
        } catch {
            print("Error generating thumbnail: \(error)")
            return nil
        }
    }
    
    private func downloadAndSaveMedia(from urlString: String) {
        guard let url = URL(string: urlString) else {
            showAlert(title: "Invalid URL", message: "Please enter a valid URL.")
            return
        }
        
        // Determine if it's a video or image based on the file extension
        let isVideo = url.pathExtension.lowercased() == "mp4"
        
        downloadAndSaveMedia(from: url, isVideo: isVideo) { [weak self] success in
            DispatchQueue.main.async {
                if success {
                    self?.showAlert(title: "Success", message: "Media saved successfully.")
                    self?.loadData()
                    self?.updateUI()
                } else {
                    self?.showAlert(title: "Error", message: "Failed to download or save media.")
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func requestPhotoLibraryAccess(completion: @escaping (Bool) -> Void) {
        PHPhotoLibrary.requestAuthorization { status in
            DispatchQueue.main.async {
                completion(status == .authorized)
            }
        }
    }
    
    private func showPhotoLibraryAccessDeniedAlert() {
        showAlert(title: "Access Denied", message: "Please allow access to your photo library in Settings.")
    }
    
    private func showURLInputView() {
        urlInputView = URLInputView(frame: view.bounds)
        urlInputView?.delegate = self
        view.addSubview(urlInputView!)
    }
    
    // MARK: - Alert Handling
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - Button Actions
    
    @objc private func addButtonTapped() {
        let actionSheet = UIAlertController(title: "Add New", message: nil, preferredStyle: .actionSheet)
        let fromAlbumAction = UIAlertAction(title: "Add from Album", style: .default) { [weak self] _ in
            self?.updateFromAlbumTapped()
        }
        let fromLinkAction = UIAlertAction(title: "Add from Link", style: .default) { [weak self] _ in
            self?.updateFromLinkTapped()
        }
        
        actionSheet.addAction(fromAlbumAction)
        actionSheet.addAction(fromLinkAction)
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(actionSheet, animated: true)
    }
}

// MARK: - URLInputViewDelegate

extension ListViewController: URLInputViewDelegate {
    func urlInputViewDidCancel(_ inputView: URLInputView) {
        UIView.animate(withDuration: 0.3, animations: {
            inputView.alpha = 0
        }) { _ in
            inputView.removeFromSuperview()
            self.urlInputView = nil
        }
    }
    
    func urlInputView(_ inputView: URLInputView, didEnterURL urlString: String) {
        urlInputViewDidCancel(inputView)
        downloadAndSaveMedia(from: urlString)
    }
}

// MARK: - UICollectionViewDelegate & DataSource

extension ListViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let item = dataSource[indexPath.item]
        
        if item is AppVideo {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "VideoCell", for: indexPath) as! VideoCell
            cell.configure(with: item as! AppVideo)
            return cell
        } else if item is AppImage {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCell", for: indexPath) as! ImageCell
            cell.configure(with: item as! AppImage)
            return cell
        }
        
        fatalError("Unknown cell type")
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension ListViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: (view.frame.width - 30) / 2, height: 200)
    }
}

