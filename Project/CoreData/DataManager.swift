import UIKit
import CoreData
import Photos
import AVFoundation

// MARK: - DataManager
/// `DataManager` is responsible for handling media data operations, including fetching, saving, and caching images.
final class DataManager {
    
    // MARK: - Properties
    /// The managed object context for Core Data operations.
    private let context: NSManagedObjectContext
    
    /// The type of media to be processed, if applicable.
    private let mediaType: String?
    
    /// Cache for storing images to optimize performance and reduce memory usage.
    private let imageCache = NSCache<NSString, UIImage>()
    
    /// Type alias for the completion handler used in batch save operations.
    typealias BatchSaveCompletion = (totalProcessed: Int, totalSkipped: Int)
    
    /// The size for thumbnail images.
    private let thumbnailSize = CGSize(width: 400, height: 400)
    
    /// The quality factor for thumbnail image compression (0.0 to 1.0).
    private let thumbnailCompressionQuality: CGFloat = 0.8
    
    // MARK: - Initialization
    /// Initializes a new instance of `DataManager`.
    /// - Parameters:
    ///   - context: The managed object context for Core Data operations.
    ///   - mediaType: The type of media to be processed (optional).
    init(context: NSManagedObjectContext, mediaType: String?) {
        self.context = context
        self.mediaType = mediaType
        
        // Configure the image cache limits.
        imageCache.countLimit = 100
        imageCache.totalCostLimit = 50 * 1024 * 1024 // 50MB limit
    }
}


// MARK: - Data Fetching
/// This extension provides methods for fetching media data from Core Data.
extension DataManager {
    
    /// Fetches media data from the Core Data context.
    /// - Parameter completion: A closure to call upon completion with the result of the fetch operation.
    func fetchData(completion: @escaping (Result<[NSManagedObject], Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            do {
                let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "AppMedia")
                fetchRequest.fetchBatchSize = 20
                fetchRequest.relationshipKeyPathsForPrefetching = ["thumbnail"]
                
                if let mediaType = self.mediaType {
                    fetchRequest.predicate = NSPredicate(format: "mediaType == %@", mediaType)
                }
                
                fetchRequest.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
                fetchRequest.returnsObjectsAsFaults = false
                
                let fetchedData = try self.context.fetch(fetchRequest)
                DispatchQueue.main.async {
                    completion(.success(fetchedData))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(DataManagerError.fetchFailed))
                }
            }
        }
    }
}


// MARK: - Media Saving
/// This extension provides methods for saving media assets from the photo library to the Core Data context.
extension DataManager {
    
    /// Saves a single media asset from the photo library to the Core Data context.
    /// - Parameters:
    ///   - asset: The `PHAsset` to save.
    ///   - context: The managed object context in which to save the asset.
    ///   - completion: A closure to call upon completion with the result of the operation.
    func saveMediaFromAsset(_ asset: PHAsset, in context: NSManagedObjectContext,
                           completion: @escaping (Result<String, Error>) -> Void) {
        autoreleasepool {
            guard !asset.localIdentifier.isEmpty else {
                completion(.failure(DataManagerError.invalidMediaType))
                return
            }
            
            guard !isAssetExists(asset.localIdentifier, in: context) else {
                completion(.failure(DataManagerError.duplicateAsset))
                return
            }
            
            let media = AppMedia(context: context)
            configureMediaProperties(media: media, from: asset)
            
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self else { return }
                
                switch asset.mediaType {
                case .image:
                    self.generateImageThumbnail(for: asset, media: media) { result in
                        switch result {
                        case .success:
                            self.saveMediaContext(completion: completion)
                        case .failure(let error):
                            completion(.failure(error))
                        }
                    }
                case .video:
                    self.generateVideoThumbnail(for: asset, media: media) { result in
                        switch result {
                        case .success:
                            self.saveMediaContext(completion: completion)
                        case .failure(let error):
                            completion(.failure(error))
                        }
                    }
                default:
                    completion(.failure(DataManagerError.invalidMediaType))
                }
            }
        }
    }
    
    /// Configures the properties of the `AppMedia` object based on the provided `PHAsset`.
    /// - Parameters:
    ///   - media: The `AppMedia` object to configure.
    ///   - asset: The `PHAsset` from which to extract properties.
    private func configureMediaProperties(media: AppMedia, from asset: PHAsset) {
        media.id = UUID()
        media.createdAt = asset.creationDate
        media.localIdentifier = asset.localIdentifier
        media.title = PHAssetResource.assetResources(for: asset).first?.originalFilename ?? "Untitled"
        media.mediaType = asset.mediaType == .image ? "image" : "video"
        media.duration = asset.mediaType == .video ? asset.duration : 0
    }
    
    /// Generates a thumbnail for an image asset and saves it to the provided `AppMedia` object.
    /// - Parameters:
    ///   - asset: The `PHAsset` representing the image.
    ///   - media: The `AppMedia` object to store the thumbnail.
    ///   - completion: A closure to call upon completion with the result of the thumbnail generation.
    private func generateImageThumbnail(for asset: PHAsset, media: AppMedia,
                                      completion: @escaping (Result<String, Error>) -> Void) {
        
        if let cachedImage = imageCache.object(forKey: asset.localIdentifier as NSString),
           let thumbnailData = cachedImage.jpegData(compressionQuality: thumbnailCompressionQuality) {
            media.thumbnail = thumbnailData
            completion(.success("Loaded from cache"))
            return
        }
        
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .exact
        options.isSynchronous = false
        options.isNetworkAccessAllowed = true
        options.version = .current
        
        PHImageManager.default().requestImage(
            for: asset,
            targetSize: thumbnailSize,
            contentMode: .aspectFill,
            options: options
        ) { [weak self] image, info in
            guard let self = self,
                  let image = image,
                  let thumbnailData = image.jpegData(compressionQuality: self.thumbnailCompressionQuality) else {
                completion(.failure(DataManagerError.thumbnailGenerationFailed))
                return
            }
            
            // Cache the generated thumbnail
            self.imageCache.setObject(image, forKey: asset.localIdentifier as NSString)
            media.thumbnail = thumbnailData
            completion(.success("Image saved"))
        }
    }
    
    /// Generates a thumbnail for a video asset and saves it to the provided `AppMedia` object.
    /// - Parameters:
    ///   - asset: The `PHAsset` representing the video.
    ///   - media: The `AppMedia` object to store the thumbnail.
    ///   - completion: A closure to call upon completion with the result of the thumbnail generation.
    private func generateVideoThumbnail(for asset: PHAsset, media: AppMedia,
                                      completion: @escaping (Result<String, Error>) -> Void) {
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat
        options.version = .current
        
        PHImageManager.default().requestAVAsset(
            forVideo: asset,
            options: options
        ) { [weak self] avAsset, _, _ in
            guard let self = self,
                  let urlAsset = avAsset as? AVURLAsset else {
                DispatchQueue.main.async {
                    completion(.failure(DataManagerError.thumbnailGenerationFailed))
                }
                return
            }
            
            if let thumbnailImage = self.generateThumbnail(for: urlAsset),
               let thumbnailData = thumbnailImage.jpegData(compressionQuality: self.thumbnailCompressionQuality) {
                self.imageCache.setObject(thumbnailImage, forKey: asset.localIdentifier as NSString)
                
                DispatchQueue.main.async {
                    media.thumbnail = thumbnailData
                    completion(.success("Video saved"))
                }
            } else {
                DispatchQueue.main.async {
                    completion(.failure(DataManagerError.thumbnailGenerationFailed))
                }
            }
        }
    }
    
    /// Generates a thumbnail image for a video asset.
    /// - Parameter video: The `AVAsset` representing the video.
    /// - Returns: A `UIImage` representing the generated thumbnail, or `nil` if generation failed.
    private func generateThumbnail(for video: AVAsset) -> UIImage? {
        let generator = AVAssetImageGenerator(asset: video)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = thumbnailSize
        generator.apertureMode = .encodedPixels
        
        let duration = video.duration
        let midPoint = CMTimeMultiplyByFloat64(duration, multiplier: 0.5)
        
        do {
            let img = try generator.copyCGImage(at: midPoint, actualTime: nil)
            return UIImage(cgImage: img)
        } catch {
            return nil
        }
    }
    
    /// Saves the current context, completing the media save operation.
    /// - Parameter completion: A closure to call upon completion with the result of the save operation.
    private func saveMediaContext(completion: @escaping (Result<String, Error>) -> Void) {
        do {
            try context.save()
            completion(.success("Media saved successfully"))
        } catch {
            completion(.failure(DataManagerError.saveFailed))
        }
    }
    
    /// Saves multiple media assets from the photo library to the Core Data context in batches.
    /// - Parameters:
    ///   - assets: An array of `PHAsset` objects to save.
    ///   - batchSize: The number of assets to process in each batch (default is 20).
    ///   - progressHandler: A closure to report progress of the save operation.
    ///   - completion: A closure to call upon completion with the result of the batch save operation.
    func saveMediaFromAssets(_ assets: [PHAsset],
                           batchSize: Int = 20,
                           progressHandler: @escaping (Int, Int) -> Void,
                           completion: @escaping (Result<BatchSaveCompletion, Error>) -> Void) {
        let taskContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        taskContext.parent = context
        
        let progressQueue = DispatchQueue(label: "com.app.progress")
        var processedCount = 0
        var skippedCount = 0
        let totalCount = assets.count
        
        DispatchQueue.global(qos: .userInitiated).async {
            let chunkedAssets = stride(from: 0, to: assets.count, by: batchSize).map {
                Array(assets[$0..<min($0 + batchSize, assets.count)])
            }
            
            for chunk in chunkedAssets {
                autoreleasepool {
                    let group = DispatchGroup()
                    
                    for asset in chunk {
                        group.enter()
                        
                        if !self.isAssetExists(asset.localIdentifier, in: taskContext) {
                            self.saveMediaFromAsset(asset, in: taskContext) { result in
                                progressQueue.async {
                                    switch result {
                                    case .success:
                                        processedCount += 1
                                    case .failure:
                                        skippedCount += 1
                                    }
                                    progressHandler(processedCount, totalCount)
                                    group.leave()
                                }
                            }
                        } else {
                            progressQueue.async {
                                skippedCount += 1
                                progressHandler(processedCount, totalCount)
                                group.leave()
                            }
                        }
                    }
                    
                    group.wait()
                    
                    do {
                        try taskContext.save()
                        try self.context.save()
                        taskContext.reset()
                    } catch {
                        completion(.failure(DataManagerError.saveFailed))
                        return
                    }
                }
            }
            
            DispatchQueue.main.async {
                completion(.success((processedCount, skippedCount)))
            }
        }
    }
}


// MARK: - Asset Management & Utilities
/// This extension provides utility functions for managing media assets and their associated cache.
extension DataManager {
    
    /// Checks if an asset with the given identifier exists in the specified context.
    /// - Parameters:
    ///   - identifier: The unique identifier of the asset to check.
    ///   - context: The managed object context to search within.
    /// - Returns: A Boolean value indicating whether the asset exists.
    private func isAssetExists(_ identifier: String, in context: NSManagedObjectContext) -> Bool {
        let fetchRequest = NSFetchRequest<NSNumber>(entityName: "AppMedia")
        fetchRequest.resultType = .countResultType
        fetchRequest.predicate = NSPredicate(format: "localIdentifier == %@", identifier)
        
        do {
            let count = try context.count(for: fetchRequest)
            return count > 0
        } catch {
            return false
        }
    }
    
    /// Clears all objects from the image cache to free up memory.
    func clearCache() {
        imageCache.removeAllObjects()
    }
    
    /// Deletes specified managed objects from the context and removes their associated cache entries.
    /// - Parameters:
    ///   - items: An array of `NSManagedObject` items to be deleted.
    ///   - completion: A closure to call upon completion with the result of the operation.
    func deleteItems(_ items: [NSManagedObject], completion: @escaping (Result<Void, Error>) -> Void) {
        context.perform { [weak self] in
            guard let self = self else { return }
            
            for item in items {
                if let media = item as? AppMedia {
                    self.imageCache.removeObject(forKey: media.localIdentifier! as NSString)
                }
                self.context.delete(item)
            }
            
            do {
                try self.context.save()
                completion(.success(()))
            } catch {
                completion(.failure(DataManagerError.saveFailed))
            }
        }
    }
}

