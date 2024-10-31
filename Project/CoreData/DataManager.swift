import UIKit
import CoreData
import Photos
import AVFoundation

// MARK: - DataManager
/// A manager class for handling media data operations, including fetching, saving, and deleting media assets using Core Data and the Photos framework.
final class DataManager {
    // MARK: - Properties
    private let context: NSManagedObjectContext
    private let mediaType: String?
    typealias BatchSaveCompletion = (totalProcessed: Int, totalSkipped: Int)
    
    // MARK: - Initialization
    /// Initializes a new instance of `DataManager`.
    /// - Parameters:
    ///   - context: The Core Data context used for saving and fetching data.
    ///   - mediaType: The type of media to filter during fetching (e.g., image, video).
    init(context: NSManagedObjectContext, mediaType: String?) {
        self.context = context
        self.mediaType = mediaType
    }
}

// MARK: - Data Fetching
extension DataManager {
    /// Fetches media data from Core Data.
    /// - Parameter completion: A closure that returns the result of the fetch operation, containing an array of `NSManagedObject` or an error.
    func fetchData(completion: @escaping (Result<[NSManagedObject], Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            do {
                let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "AppMedia")
                if let mediaType = self.mediaType {
                    fetchRequest.predicate = NSPredicate(format: "mediaType == %@", mediaType)
                }
                
                let sortDescriptor = NSSortDescriptor(key: "title", ascending: true)
                fetchRequest.sortDescriptors = [sortDescriptor]
                
                let fetchedData = try self.context.fetch(fetchRequest)
                completion(.success(fetchedData))
            } catch {
                completion(.failure(error))
            }
        }
    }
}

// MARK: - Media Saving
extension DataManager {
    /// Saves a media asset to Core Data.
    /// - Parameters:
    ///   - asset: The `PHAsset` to save.
    ///   - completion: A closure that returns the result of the save operation, indicating success or failure.
    func saveMediaFromAsset(_ asset: PHAsset, completion: @escaping (DataUpdateResult) -> Void) {
        guard asset.localIdentifier.isEmpty == false else {
            completion(.failure(NSError(domain: "AssetError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid asset identifier"])))
            return
        }
        
        if !isAssetExists(asset.localIdentifier) {
            saveMediaToCoreData(from: asset, completion: completion)
        } else {
            completion(.failure(NSError(domain: "DuplicateError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Asset already exists"])))
        }
    }
    
    /// Saves a media asset to Core Data from a given `PHAsset`.
    /// - Parameters:
    ///   - asset: The `PHAsset` to save.
    ///   - completion: A closure that returns the result of the save operation.
    private func saveMediaToCoreData(from asset: PHAsset, completion: @escaping (DataUpdateResult) -> Void) {
        let media = AppMedia(context: context)
        media.id = UUID()
        media.createdAt = asset.creationDate
        media.localIdentifier = asset.localIdentifier

        let assetResources = PHAssetResource.assetResources(for: asset)
        media.title = assetResources.first?.originalFilename ?? "Untitled"

        media.mediaType = asset.mediaType == .image ? "image" : "video"
        media.duration = asset.mediaType == .video ? asset.duration : 0

        generateAndSaveThumbnail(for: asset, media: media, completion: completion)
    }

    /// Generates and saves a thumbnail for the specified asset.
    /// - Parameters:
    ///   - asset: The `PHAsset` for which to generate the thumbnail.
    ///   - media: The `AppMedia` object to which the thumbnail will be assigned.
    ///   - completion: A closure that returns the result of the save operation.
    private func generateAndSaveThumbnail(for asset: PHAsset, media: AppMedia, completion: @escaping (DataUpdateResult) -> Void) {
        if asset.mediaType == .image {
            let imageOptions = PHImageRequestOptions()
            imageOptions.isSynchronous = true
            imageOptions.deliveryMode = .highQualityFormat
            
            PHImageManager.default().requestImage(
                for: asset,
                targetSize: PHImageManagerMaximumSize,
                contentMode: .aspectFit,
                options: imageOptions
            ) { [weak self] image, info in
                guard let self = self,
                      let image = image,
                      let thumbnailData = image.jpegData(compressionQuality: 0.5) else {
                    completion(.failure(NSError(domain: "ThumbnailError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create image thumbnail"])))
                    return
                }
                
                media.thumbnail = thumbnailData
                self.saveContextAndComplete(completion: completion, successMessage: "Image saved successfully")
            }
        } else if asset.mediaType == .video {
            let videoOptions = PHVideoRequestOptions()
            videoOptions.isNetworkAccessAllowed = true
            videoOptions.deliveryMode = .highQualityFormat
            
            PHImageManager.default().requestAVAsset(
                forVideo: asset,
                options: videoOptions
            ) { [weak self] avAsset, _, _ in
                guard let self = self,
                      let urlAsset = avAsset as? AVURLAsset else {
                    completion(.failure(NSError(domain: "VideoError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to load video"])))
                    return
                }
                
                if let thumbnailImage = self.generateThumbnail(for: urlAsset),
                   let thumbnailData = thumbnailImage.jpegData(compressionQuality: 0.5) {
                    media.thumbnail = thumbnailData
                    self.saveContextAndComplete(completion: completion, successMessage: "Video saved successfully")
                } else {
                    completion(.failure(NSError(domain: "ThumbnailError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create video thumbnail"])))
                }
            }
        } else {
            completion(.failure(NSError(domain: "MediaTypeError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unsupported media type"])))
        }
    }

    /// Saves the current context and calls the completion handler.
    /// - Parameters:
    ///   - completion: A closure that returns the result of the save operation.
    ///   - successMessage: A message indicating success.
    private func saveContextAndComplete(completion: @escaping (DataUpdateResult) -> Void, successMessage: String) {
        do {
            try context.save()
            completion(.success(successMessage))
        } catch {
            completion(.failure(error))
        }
    }
    
    /// Saves multiple media assets from the specified array.
    /// - Parameters:
    ///   - assets: An array of `PHAsset` objects to save.
    ///   - batchSize: The number of assets to process in each batch (default is 20).
    ///   - progressHandler: A closure that reports progress updates.
    ///   - completion: A closure that returns the result of the batch save operation.
    func saveMediaFromAssets(_ assets: [PHAsset], batchSize: Int = 20,
                            progressHandler: @escaping (Int, Int) -> Void,
                            completion: @escaping (Result<BatchSaveCompletion, Error>) -> Void) {
        var processedCount = 0
        var skippedCount = 0
        let totalCount = assets.count
        
        let group = DispatchGroup()
        let queue = DispatchQueue(label: "com.app.batchProcessing", qos: .userInitiated)
        
        for i in stride(from: 0, to: assets.count, by: batchSize) {
            let end = min(i + batchSize, assets.count)
            let batch = Array(assets[i..<end])
            
            batch.forEach { asset in
                group.enter()
                saveMediaFromAsset(asset) { result in
                    queue.async {
                        switch result {
                        case .success:
                            processedCount += 1
                        case .failure(let error):
                            if (error as NSError).domain == "DuplicateError" {
                                skippedCount += 1
                            }
                        }
                        progressHandler(processedCount, totalCount)
                        group.leave()
                    }
                }
            }
        }
        
        group.notify(queue: .main) {
            completion(.success((processedCount, skippedCount)))
        }
    }
}

// MARK: - Asset Management
extension DataManager {
    /// Checks if an asset with the specified identifier already exists in Core Data.
    /// - Parameter identifier: The local identifier of the asset to check.
    /// - Returns: A boolean indicating whether the asset exists.
    private func isAssetExists(_ identifier: String) -> Bool {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "AppMedia")
        fetchRequest.predicate = NSPredicate(format: "localIdentifier == %@", identifier)
        
        do {
            let count = try context.count(for: fetchRequest)
            return count > 0
        } catch {
            print("Error checking for existing asset: \(error)")
            return false
        }
    }
}

// MARK: - Deletion
extension DataManager {
    /// Deletes the specified items from Core Data.
    /// - Parameters:
    ///   - items: An array of `NSManagedObject` items to delete.
    ///   - completion: A closure that returns the result of the delete operation.
    func deleteItems(_ items: [NSManagedObject], completion: @escaping (Result<Void, Error>) -> Void) {
        context.perform {
            for item in items {
                self.context.delete(item)
            }
            
            do {
                try self.context.save()
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }
}

// MARK: - Utilities
extension DataManager {
    /// Generates a thumbnail image for the specified video asset.
    /// - Parameter video: The video asset for which to generate a thumbnail.
    /// - Returns: A `UIImage` representing the generated thumbnail, or `nil` if the generation failed.
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
}
