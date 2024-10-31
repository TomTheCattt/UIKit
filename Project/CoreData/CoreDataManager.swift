import CoreData
import UIKit
import Photos

// MARK: - CoreDataManager
/// A singleton class for managing Core Data operations related to the AppMedia entity.
/// It provides methods for creating, reading, updating, and deleting media assets in Core Data.
class CoreDataManager {
    
    // MARK: - Singleton Instance
    static let shared = CoreDataManager()
    
    private init() {}
    
    // MARK: - Core Data Context
    /// The managed object context for Core Data operations.
    /// - Returns: The NSManagedObjectContext for the application.
    var context: NSManagedObjectContext {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            fatalError("AppDelegate not found")
        }
        return appDelegate.persistentContainer.viewContext
    }
    
    // MARK: - Save Context
    /// Saves changes in the context to the persistent store.
    /// If there are no changes, the method does nothing.
    func saveContext() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    // MARK: - AppMedia CRUD Operations
    /// Creates a new AppMedia instance from a given PHAsset.
    /// - Parameter asset: The PHAsset from which to create the AppMedia instance.
    /// - Returns: The newly created AppMedia instance.
    func createAppMedia(from asset: PHAsset) -> AppMedia {
        let appMedia = AppMedia(context: context)
        appMedia.id = UUID()
        appMedia.localIdentifier = asset.localIdentifier
        appMedia.createdAt = asset.creationDate
        
        let assetResources = PHAssetResource.assetResources(for: asset)
        appMedia.title = assetResources.first?.originalFilename
        
        switch asset.mediaType {
        case .image:
            appMedia.mediaType = "image"
            appMedia.duration = 0
        case .video:
            appMedia.mediaType = "video"
            appMedia.duration = asset.duration
        default:
            appMedia.mediaType = "unknown"
            appMedia.duration = 0
        }
        
        saveContext()
        return appMedia
    }
    
    /// Fetches all AppMedia instances from Core Data.
    /// - Returns: An array of AppMedia objects.
    func fetchAllMedia() -> [AppMedia] {
        let request: NSFetchRequest<AppMedia> = AppMedia.fetchRequest()
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching AppMedia: \(error)")
            return []
        }
    }
    
    /// Fetches AppMedia instances filtered by media type.
    /// - Parameter mediaType: The type of media to filter (e.g., "image" or "video").
    /// - Returns: An array of AppMedia objects matching the specified media type.
    func fetchMedia(byType mediaType: String) -> [AppMedia] {
        let request: NSFetchRequest<AppMedia> = AppMedia.fetchRequest()
        request.predicate = NSPredicate(format: "mediaType == %@", mediaType)
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching AppMedia by type: \(error)")
            return []
        }
    }
    
    /// Fetches a single AppMedia instance by its unique identifier.
    /// - Parameter id: The UUID of the AppMedia instance to fetch.
    /// - Returns: An optional AppMedia object if found, otherwise nil.
    func fetchMedia(byId id: UUID) -> AppMedia? {
        let request: NSFetchRequest<AppMedia> = AppMedia.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        do {
            let results = try context.fetch(request)
            return results.first
        } catch {
            print("Error fetching AppMedia by ID: \(error)")
            return nil
        }
    }
    
    /// Updates the specified AppMedia instance with new values for title and/or thumbnail.
    /// - Parameters:
    ///   - appMedia: The AppMedia instance to update.
    ///   - title: An optional new title for the media.
    ///   - thumbnail: An optional new thumbnail data for the media.
    func updateAppMedia(appMedia: AppMedia, title: String? = nil, thumbnail: Data? = nil) {
        if let title = title {
            appMedia.title = title
        }
        if let thumbnail = thumbnail {
            appMedia.thumbnail = thumbnail
        }
        
        saveContext()
    }
    
    /// Deletes the specified AppMedia instance from Core Data.
    /// - Parameter appMedia: The AppMedia instance to delete.
    func deleteAppMedia(appMedia: AppMedia) {
        context.delete(appMedia)
        saveContext()
    }
    
    // MARK: - Count Operations
    /// Fetches the count of AppMedia instances filtered by media type.
    /// - Parameter mediaType: The type of media to count (e.g., "image" or "video").
    /// - Returns: The count of AppMedia instances of the specified type.
    func fetchMediaCount(ofType mediaType: String) -> Int {
        let fetchRequest: NSFetchRequest<AppMedia> = AppMedia.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "mediaType == %@", mediaType)
        
        do {
            let count = try context.count(for: fetchRequest)
            return count
        } catch {
            print("Failed to fetch AppMedia count: \(error)")
            return 0
        }
    }
}
