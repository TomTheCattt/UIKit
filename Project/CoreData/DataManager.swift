import UIKit
import CoreData
import Photos
import AVFoundation

// MARK: - DataManager
///Handling media storage, retrieval and deletion operations using Core Data. Use caching of thumbnail for efficient access.
final class DataManager {
    // MARK: - Properties
    private let context: NSManagedObjectContext
    private let mediaType: String?
    private let imageCache = NSCache<NSString, UIImage>()
    typealias BatchSaveCompletion = (totalProcessed: Int, totalSkipped: Int)
    
    // Thumbnail configuration
    private let thumbnailSize = CGSize(width: 200, height: 200)
    private let thumbnailCompressionQuality: CGFloat = 0.5
    
    // MARK: - Initialization
    /// Initializes the `DataManager` with a Core Data context and an optional media type filter.
    /// - Parameters:
    ///   - context: The Core Data context used for data operations.
    ///   - mediaType: Optional filter for media type to retrieve specific types of media (e.g., "image" or "video").
    init(context: NSManagedObjectContext, mediaType: String?) {
        self.context = context
        self.mediaType = mediaType
        
        // Configure image cache
        imageCache.countLimit = 100
        imageCache.totalCostLimit = 50 * 1024 * 1024 // 50MB limit
    }
    
    // MARK: - Performance Measurement
    /// Use for calculate performance of a given block of code.
    private func measurePerformance(_ block: () -> Void, operation: String) {
        let start = CFAbsoluteTimeGetCurrent()
        block()
        let diff = CFAbsoluteTimeGetCurrent() - start
        print("⏱️ Time taken for \(operation): \(diff) seconds")
    }
}

// MARK: - Data Fetching
/// Fetch media data from Core Data and filter data by its local identifier to avoid duplicate media when user update media data in application.
/// Use background queue for optimize performance. Also clear old cache to update new ones.
/// - Parameter completion: Completion handler with a result containing either a list of fetched objects or an error.
extension DataManager {
    func fetchData(completion: @escaping (Result<[NSManagedObject], Error>) -> Void) {
        measurePerformance({
            clearCache()
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self else { return }
                
                do {
                    let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "AppMedia")
                    
                    // Configure fetch request for optimal performance
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
        }, operation: "Fetch Data")
    }
}

// MARK: - Media Saving
extension DataManager {
    /// Saves a media item from a `PHAsset` to Core Data and generates a thumbnail.
        /// - Parameters:
        ///   - asset: The `PHAsset` containing the media data.
        ///   - context: The Core Data context for saving the asset.
        ///   - completion: Completion handler with a result containing either a success message or an error.
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
            
            // Generate thumbnail asynchronously
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.generateAndSaveThumbnail(for: asset, media: media, completion: completion)
            }
        }
    }
    
    /// Configures the properties of a Core Data `AppMedia` entity from a `PHAsset`.
    /// - Parameters:
    ///   - media: The `AppMedia` entity to configure.
    ///   - asset: The `PHAsset` providing data to populate the entity.
    private func configureMediaProperties(media: AppMedia, from asset: PHAsset) {
        media.id = UUID()
        media.createdAt = asset.creationDate
        media.localIdentifier = asset.localIdentifier
        
        let assetResources = PHAssetResource.assetResources(for: asset)
        media.title = assetResources.first?.originalFilename ?? "Untitled"
        media.mediaType = asset.mediaType == .image ? "image" : "video"
        media.duration = asset.mediaType == .video ? asset.duration : 0
    }
    
    /// Generates and saves a thumbnail for the given asset and assigns it to the `AppMedia` entity.
    /// - Parameters:
    ///   - asset: The `PHAsset` to generate a thumbnail for.
    ///   - media: The `AppMedia` entity to save the thumbnail to.
    ///   - completion: Completion handler with a success message or error.
    private func generateAndSaveThumbnail(for asset: PHAsset, media: AppMedia,
                                        completion: @escaping (Result<String, Error>) -> Void) {
        // Check cache first
        if let cachedImage = imageCache.object(forKey: asset.localIdentifier as NSString),
           let thumbnailData = cachedImage.jpegData(compressionQuality: thumbnailCompressionQuality) {
            media.thumbnail = thumbnailData
            saveContextAndComplete(completion: completion, successMessage: "Loaded from cache")
            return
        }
        
        switch asset.mediaType {
        case .image:
            generateImageThumbnail(for: asset, media: media, completion: completion)
        case .video:
            generateVideoThumbnail(for: asset, media: media, completion: completion)
        default:
            completion(.failure(DataManagerError.invalidMediaType))
        }
    }
    
    private func generateImageThumbnail(for asset: PHAsset, media: AppMedia,
                                      completion: @escaping (Result<String, Error>) -> Void) {
        let imageOptions = PHImageRequestOptions()
        imageOptions.deliveryMode = .fastFormat
        imageOptions.resizeMode = .exact
        imageOptions.isSynchronous = false
        
        PHImageManager.default().requestImage(
            for: asset,
            targetSize: thumbnailSize,
            contentMode: .aspectFit,
            options: imageOptions
        ) { [weak self] image, info in
            guard let self = self,
                  let image = image,
                  let thumbnailData = image.jpegData(compressionQuality: self.thumbnailCompressionQuality) else {
                completion(.failure(DataManagerError.thumbnailGenerationFailed))
                return
            }
            
            self.imageCache.setObject(image, forKey: asset.localIdentifier as NSString)
            media.thumbnail = thumbnailData
            self.saveContextAndComplete(completion: completion, successMessage: "Image saved")
        }
    }
    
    private func generateVideoThumbnail(for asset: PHAsset, media: AppMedia,
                                      completion: @escaping (Result<String, Error>) -> Void) {
        let videoOptions = PHVideoRequestOptions()
        videoOptions.isNetworkAccessAllowed = true
        videoOptions.deliveryMode = .fastFormat
        
        PHImageManager.default().requestAVAsset(
            forVideo: asset,
            options: videoOptions
        ) { [weak self] avAsset, _, _ in
            guard let self = self,
                  let urlAsset = avAsset as? AVURLAsset else {
                completion(.failure(DataManagerError.thumbnailGenerationFailed))
                return
            }
            
            if let thumbnailImage = self.generateThumbnail(for: urlAsset),
               let thumbnailData = thumbnailImage.jpegData(compressionQuality: self.thumbnailCompressionQuality) {
                self.imageCache.setObject(thumbnailImage, forKey: asset.localIdentifier as NSString)
                media.thumbnail = thumbnailData
                self.saveContextAndComplete(completion: completion, successMessage: "Video saved")
            } else {
                completion(.failure(DataManagerError.thumbnailGenerationFailed))
            }
        }
    }
    
    /// Saves media from a list of assets in batches and provides progress updates with a measure performance.
    /// - Parameters:
    ///   - assets: List of assets to save.
    ///   - batchSize: Number of assets processed per batch.
    ///   - progressHandler: Handler providing progress information.
    ///   - completion: Completion handler with the total processed and skipped counts, or an error.
    func saveMediaFromAssets(_ assets: [PHAsset],
                           batchSize: Int = 20,
                           progressHandler: @escaping (Int, Int) -> Void,
                           completion: @escaping (Result<BatchSaveCompletion, Error>) -> Void) {
        measurePerformance({
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
                                        case .failure(let error) where error is DataManagerError:
                                            skippedCount += 1
                                        default:
                                            break
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
        }, operation: "Batch Save")
    }
    
    /// Saves the Core Data context and completes with a success message.
    /// - Parameters:
    ///   - completion: Completion handler with a success message or error.
    ///   - successMessage: Message to indicate successful save.
    private func saveContextAndComplete(completion: @escaping (Result<String, Error>) -> Void,
                                      successMessage: String) {
        do {
            try context.save()
            completion(.success(successMessage))
        } catch {
            completion(.failure(DataManagerError.saveFailed))
        }
    }
}

// MARK: - Asset Management
extension DataManager {
    /// Check for asset duplicate
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
}

// MARK: - Deletion
extension DataManager {
    /// Delete media item(s) in Core Data with a measure performance
    /// - Parameters:
    ///  - items: An array of items need to delete in Core Data
    ///  - completion: Completion handler with a success message or error.
    func deleteItems(_ items: [NSManagedObject], completion: @escaping (Result<Void, Error>) -> Void) {
        measurePerformance({
            context.perform { [weak self] in
                guard let self = self else { return }
                
                for item in items {
                    // Clear cache if exists
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
        }, operation: "Delete Items")
    }
}

// MARK: - Utilities
extension DataManager {
    /// Generate thumbnail if media data type is video.
    private func generateThumbnail(for video: AVAsset) -> UIImage? {
        let assetImgGenerate = AVAssetImageGenerator(asset: video)
        assetImgGenerate.appliesPreferredTrackTransform = true
        assetImgGenerate.maximumSize = thumbnailSize
        
        let duration = video.duration
        let midPoint = CMTimeMultiplyByFloat64(duration, multiplier: 0.5)
        
        do {
            let img = try assetImgGenerate.copyCGImage(at: midPoint, actualTime: nil)
            return UIImage(cgImage: img)
        } catch {
            print("Error generating thumbnail: \(error)")
            return nil
        }
    }
    
    func clearCache() {
        imageCache.removeAllObjects()
    }
}
