//
//  ListViewDataManager.swift
//  Project
//
//  Created by Việt Anh Nguyễn on 22/10/2024.
//

import UIKit
import CoreData
import Photos
import AVFoundation

// MARK: - ListViewDataManager
final class ListViewDataManager {
    // MARK: - Properties
    private let context: NSManagedObjectContext
    private let category: CategoryType?
    
    // MARK: - Initialization
    init(context: NSManagedObjectContext, category: CategoryType?) {
        self.context = context
        self.category = category
    }
    
    // MARK: - Public Methods
    func fetchData(completion: @escaping (Result<[NSManagedObject], Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self,
                  let category = self.category else {
                completion(.success([]))
                return
            }
            
            do {
                let fetchedData = try self.fetchAndSortData(for: category)
                completion(.success(fetchedData))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    func saveMediaFromAsset(_ asset: PHAsset, completion: @escaping (DataUpdateResult) -> Void) {
        switch asset.mediaType {
        case .image:
            saveImageToCoreData(from: asset, completion: completion)
        case .video:
            saveVideoToCoreData(from: asset, completion: completion)
        default:
            let error = NSError(domain: "MediaTypeError",
                                code: -1,
                                userInfo: [NSLocalizedDescriptionKey: "Unsupported media type"])
            completion(.failure(error))
        }
    }
    
    func saveMediaFromAssets(_ assets: [PHAsset], completion: @escaping (Result<DataUpdateInfo, Error>) -> Void) {
        var newItemsCount = 0
        var duplicateItemsCount = 0
        let group = DispatchGroup()
        
        for asset in assets {
            group.enter()
            
            // Kiểm tra xem asset đã tồn tại chưa
            if !isAssetExists(asset.localIdentifier) {
                saveMediaFromAsset(asset) { result in
                    switch result {
                    case .success:
                        newItemsCount += 1
                    case .failure:
                        // Xử lý lỗi nếu cần
                        break
                    }
                    group.leave()
                }
            } else {
                duplicateItemsCount += 1
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            let updateInfo = DataUpdateInfo(
                newItemsCount: newItemsCount,
                duplicateItemsCount: duplicateItemsCount
            )
            completion(.success(updateInfo))
        }
    }
    
    func deleteMedia(_ object: NSManagedObject, completion: @escaping (DataUpdateResult) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            // Delete associated file if exists
            if let filepath = object.value(forKey: "filepath") as? String {
                try? FileManager.default.removeItem(atPath: filepath)
            }
            
            self.context.delete(object)
            
            do {
                try self.context.save()
                completion(.success("Media deleted successfully"))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    func downloadAndSaveMedia(from url: URL, completion: @escaping (DataUpdateResult) -> Void) {
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self,
                  let data = data else {
                let error = error ?? NSError(domain: "DownloadError",
                                             code: -1,
                                             userInfo: [NSLocalizedDescriptionKey: "Download failed"])
                completion(.failure(error))
                return
            }
            
            let isVideo = url.pathExtension.lowercased() == "mp4"
            if isVideo {
                self.saveVideoFromDownloadedData(data, completion: completion)
            } else {
                self.saveImageFromDownloadedData(data, completion: completion)
            }
        }
        task.resume()
    }
    
    // MARK: - Private Methods
    private func isAssetExists(_ identifier: String) -> Bool {
        let entityName = category == .video ? "AppVideo" : "AppImage"
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: entityName)
        fetchRequest.predicate = NSPredicate(format: "title == %@", identifier)
        
        do {
            let count = try context.count(for: fetchRequest)
            return count > 0
        } catch {
            print("Error checking for existing asset: \(error)")
            return false
        }
    }
    
    private func fetchAndSortData(for category: CategoryType) throws -> [NSManagedObject] {
        let fetchRequest: NSFetchRequest<NSManagedObject>
        switch category {
        case .video:
            fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "AppVideo")
        case .image:
            fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "AppImage")
        }
        
        let fetchedData = try context.fetch(fetchRequest)
        return fetchedData.sorted {
            ($0.value(forKey: "title") as? String ?? "") < ($1.value(forKey: "title") as? String ?? "")
        }
    }
    
    private func saveImageToCoreData(from asset: PHAsset, completion: @escaping (DataUpdateResult) -> Void) {
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.isSynchronous = true
        options.deliveryMode = .highQualityFormat
        
        manager.requestImage(for: asset,
                             targetSize: PHImageManagerMaximumSize,
                             contentMode: .aspectFit,
                             options: options) { [weak self] image, info in
            guard let self = self,
                  let image = image else {
                completion(.failure(NSError(domain: "ImageError",
                                            code: -1,
                                            userInfo: [NSLocalizedDescriptionKey: "Failed to load image"])))
                return
            }
            
            let newImage = AppImage(context: self.context)
            newImage.id = UUID()
            newImage.title = asset.localIdentifier
            newImage.createdAt = Date()
            
            if let imagePath = self.saveImageToDocuments(image: image, withName: newImage.id?.uuidString ?? "unknown") {
                newImage.filepath = imagePath
            }
            
            if let thumbnailData = image.jpegData(compressionQuality: 0.5) {
                newImage.thumbnail = thumbnailData
            }
            
            do {
                try self.context.save()
                completion(.success("Image saved successfully"))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    private func saveVideoToCoreData(from asset: PHAsset, completion: @escaping (DataUpdateResult) -> Void) {
        let manager = PHImageManager.default()
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat
        
        manager.requestAVAsset(forVideo: asset, options: options) { [weak self] (avAsset, _, _) in
            guard let self = self,
                  let urlAsset = avAsset as? AVURLAsset else {
                completion(.failure(NSError(domain: "VideoError",
                                            code: -1,
                                            userInfo: [NSLocalizedDescriptionKey: "Failed to load video"])))
                return
            }
            
            let newVideo = AppVideo(context: self.context)
            newVideo.id = UUID()
            newVideo.title = asset.localIdentifier
            newVideo.duration = asset.duration
            newVideo.createdAt = Date()
            
            if let videoPath = self.saveVideoToDocuments(from: urlAsset.url,
                                                         withName: newVideo.id?.uuidString ?? "unknown") {
                newVideo.filepath = videoPath
            }
            
            if let thumbnailImage = self.generateThumbnail(for: urlAsset) {
                newVideo.thumbnail = thumbnailImage.jpegData(compressionQuality: 0.5)
            }
            
            do {
                try self.context.save()
                completion(.success("Video saved successfully"))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    private func saveImageFromDownloadedData(_ data: Data, completion: @escaping (DataUpdateResult) -> Void) {
        guard let image = UIImage(data: data) else {
            completion(.failure(NSError(domain: "ImageError",
                                        code: -1,
                                        userInfo: [NSLocalizedDescriptionKey: "Invalid image data"])))
            return
        }
        
        let newImage = AppImage(context: context)
        newImage.id = UUID()
        newImage.title = newImage.id?.uuidString ?? "downloaded_image"
        newImage.createdAt = Date()
        
        if let imagePath = saveImageToDocuments(image: image, withName: newImage.id?.uuidString ?? "unknown") {
            newImage.filepath = imagePath
        }
        
        if let thumbnailData = image.jpegData(compressionQuality: 0.5) {
            newImage.thumbnail = thumbnailData
        }
        
        do {
            try context.save()
            completion(.success("Image downloaded and saved successfully"))
        } catch {
            completion(.failure(error))
        }
    }
    
    private func saveVideoFromDownloadedData(_ data: Data, completion: @escaping (DataUpdateResult) -> Void) {
        let tempURL = getDocumentsDirectory().appendingPathComponent("temp_video.mp4")
        do {
            try data.write(to: tempURL)
            let asset = AVAsset(url: tempURL)
            
            let newVideo = AppVideo(context: context)
            newVideo.id = UUID()
            newVideo.title = newVideo.id?.uuidString ?? "downloaded_video"
            newVideo.duration = CMTimeGetSeconds(asset.duration)
            newVideo.createdAt = Date()
            
            if let videoPath = saveVideoToDocuments(from: tempURL,
                                                    withName: newVideo.id?.uuidString ?? "unknown") {
                newVideo.filepath = videoPath
            }
            
            if let thumbnailImage = generateThumbnail(for: asset) {
                newVideo.thumbnail = thumbnailImage.jpegData(compressionQuality: 0.5)
            }
            
            try context.save()
            try FileManager.default.removeItem(at: tempURL)
            completion(.success("Video downloaded and saved successfully"))
        } catch {
            completion(.failure(error))
        }
    }
    
    // MARK: - Helper Methods
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
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}

// MARK: - DataUpdateInfo
struct DataUpdateInfo {
    let newItemsCount: Int
    let duplicateItemsCount: Int
    
    var message: String {
        if newItemsCount > 0 {
            return "Đã cập nhật thành công \(newItemsCount) mục mới"
        } else {
            return "Đã cập nhật thành công và không có sự thay đổi mới"
        }
    }
}
