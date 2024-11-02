import UIKit
import CoreData
import Photos
import AVFoundation

// MARK: - DataManager
final class DataManager {
    // MARK: - Properties
    private let context: NSManagedObjectContext
    private let mediaType: String?
    private let imageCache = NSCache<NSString, UIImage>()
    typealias BatchSaveCompletion = (totalProcessed: Int, totalSkipped: Int)
    
    // Increased thumbnail size and quality
    private let thumbnailSize = CGSize(width: 400, height: 400)
    private let thumbnailCompressionQuality: CGFloat = 0.8
    
    // MARK: - Initialization
    init(context: NSManagedObjectContext, mediaType: String?) {
        self.context = context
        self.mediaType = mediaType
        
        imageCache.countLimit = 100
        imageCache.totalCostLimit = 50 * 1024 * 1024 // 50MB limit
    }
}

// MARK: - Data Fetching
extension DataManager {
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
extension DataManager {
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
    
    private func configureMediaProperties(media: AppMedia, from asset: PHAsset) {
        media.id = UUID()
        media.createdAt = asset.creationDate
        media.localIdentifier = asset.localIdentifier
        media.title = PHAssetResource.assetResources(for: asset).first?.originalFilename ?? "Untitled"
        media.mediaType = asset.mediaType == .image ? "image" : "video"
        media.duration = asset.mediaType == .video ? asset.duration : 0
    }
    
    private func generateImageThumbnail(for asset: PHAsset, media: AppMedia,
                                      completion: @escaping (Result<String, Error>) -> Void) {
        // Check cache first
        if let cachedImage = imageCache.object(forKey: asset.localIdentifier as NSString),
           let thumbnailData = cachedImage.jpegData(compressionQuality: thumbnailCompressionQuality) {
            media.thumbnail = thumbnailData
            completion(.success("Loaded from cache"))
            return
        }
        
        // Configure options for better quality
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat  // Changed to high quality
        options.resizeMode = .exact
        options.isSynchronous = false
        options.isNetworkAccessAllowed = true      // Allow fetching from iCloud
        options.version = .current                 // Get the latest version
        
        PHImageManager.default().requestImage(
            for: asset,
            targetSize: thumbnailSize,
            contentMode: .aspectFill,              // Changed to aspectFill for better scaling
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
    
    private func generateVideoThumbnail(for asset: PHAsset, media: AppMedia,
                                      completion: @escaping (Result<String, Error>) -> Void) {
        // Configure video options for better quality
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat  // Changed to high quality
        options.version = .current                 // Get the latest version
        
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
    
    private func generateThumbnail(for video: AVAsset) -> UIImage? {
        let generator = AVAssetImageGenerator(asset: video)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = thumbnailSize
        generator.apertureMode = .encodedPixels    // Added for better quality
        
        let duration = video.duration
        let midPoint = CMTimeMultiplyByFloat64(duration, multiplier: 0.5)
        
        do {
            let img = try generator.copyCGImage(at: midPoint, actualTime: nil)
            return UIImage(cgImage: img)
        } catch {
            return nil
        }
    }
    
    private func saveMediaContext(completion: @escaping (Result<String, Error>) -> Void) {
        do {
            try context.save()
            completion(.success("Media saved successfully"))
        } catch {
            completion(.failure(DataManagerError.saveFailed))
        }
    }
    
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
extension DataManager {
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
    
    func clearCache() {
        imageCache.removeAllObjects()
    }
    
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
