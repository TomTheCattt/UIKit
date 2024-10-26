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
    
    // MARK: - Private Methods
    private func isAssetExists(_ identifier: String) -> Bool {
        let entityName = category == .video ? "AppVideo" : "AppImage"
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: entityName)
        fetchRequest.predicate = NSPredicate(format: "localIdentifier == %@", identifier)
        
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

        // Bắt đầu yêu cầu hình ảnh từ tài sản
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
            
            // Tìm kiếm và xóa hình ảnh cũ nếu đã tồn tại
            self.deleteExistingAsset(with: asset.localIdentifier)
            
            let newImage = AppImage(context: self.context)
            newImage.id = UUID()
            newImage.createdAt = Date()
            newImage.localIdentifier = asset.localIdentifier

            // Lưu ảnh vào thư mục Documents
            if let imagePath = self.saveImageToDocuments(image: image, withName: newImage.id?.uuidString ?? "unknown") {
                newImage.filepath = imagePath
                
                // Lấy title từ filePath
                let fileURL = URL(fileURLWithPath: imagePath)
                newImage.title = fileURL.lastPathComponent
            }

            if let thumbnailData = image.jpegData(compressionQuality: 0.5) {
                newImage.thumbnail = thumbnailData
            }

            do {
                try self.context.save()
                print("Saved Image:")
                print("ID: \(newImage.id?.uuidString ?? "Unknown")")
                print("Title: \(newImage.title ?? "Unknown")")
                print("Filepath: \(newImage.filepath ?? "None")")
                print("Created At: \(newImage.createdAt ?? Date())")
                
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
            
            // Xóa video cũ nếu đã tồn tại
            self.deleteExistingVideo(with: asset.localIdentifier)

            let newVideo = AppVideo(context: self.context)
            newVideo.id = UUID()
            newVideo.duration = asset.duration
            newVideo.createdAt = Date()
            newVideo.localIdentifier = asset.localIdentifier

            // Lưu video vào thư mục Documents
            if let videoPath = self.saveVideoToDocuments(from: urlAsset.url,
                                                         withName: newVideo.id?.uuidString ?? "unknown") {
                newVideo.filepath = videoPath
                
                // Lấy title từ filePath
                let fileURL = URL(fileURLWithPath: videoPath)
                newVideo.title = fileURL.lastPathComponent
            }

            // Tạo thumbnail cho video
            if let thumbnailImage = self.generateThumbnail(for: urlAsset) {
                newVideo.thumbnail = thumbnailImage.jpegData(compressionQuality: 0.5)
            }

            do {
                try self.context.save()
                print("Saved Video:")
                print("ID: \(newVideo.id?.uuidString ?? "Unknown")")
                print("Title: \(newVideo.title ?? "Unknown")")
                print("Duration: \(newVideo.duration)")
                print("Filepath: \(newVideo.filepath ?? "None")")
                print("Created At: \(newVideo.createdAt ?? Date())")
                
                completion(.success("Video saved successfully"))
            } catch {
                completion(.failure(error))
            }
        }
    }

    private func deleteExistingAsset(with localIdentifier: String) {
        let fetchRequest: NSFetchRequest<AppImage> = AppImage.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "localIdentifier == %@", localIdentifier)

        do {
            let results = try context.fetch(fetchRequest)
            for asset in results {
                context.delete(asset)
            }
            try context.save()  // Lưu lại các thay đổi
        } catch {
            print("Error deleting existing asset: \(error)")
        }
    }

    private func deleteExistingVideo(with localIdentifier: String) {
        let fetchRequest: NSFetchRequest<AppVideo> = AppVideo.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "localIdentifier == %@", localIdentifier)

        do {
            let results = try context.fetch(fetchRequest)
            for video in results {
                context.delete(video)
            }
            try context.save()  // Lưu lại các thay đổi
        } catch {
            print("Error deleting existing video: \(error)")
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

extension ListViewDataManager {
    func deleteItems(_ items: [NSManagedObject], completion: @escaping (Result<Void, Error>) -> Void) {
        let context = self.context
        
        context.perform {
            do {
                for item in items {
                    context.delete(item)
                }
                try context.save()
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }
}
