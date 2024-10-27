//
//  CoreDataHandle.swift
//  Project
//
//  Created by Việt Anh Nguyễn on 13/10/2024.
//

import CoreData
import UIKit
import Photos

class CoreDataManager {
    
    static let shared = CoreDataManager()
    
    private init() {}
    
    // MARK: - Core Data Context
    var context: NSManagedObjectContext {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            fatalError("AppDelegate not found")
        }
        return appDelegate.persistentContainer.viewContext
    }
    
    // MARK: - Save Context
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
    
    func fetchAllMedia() -> [AppMedia] {
        let request: NSFetchRequest<AppMedia> = AppMedia.fetchRequest()
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching AppMedia: \(error)")
            return []
        }
    }
    
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
    
    func updateAppMedia(appMedia: AppMedia, title: String? = nil, thumbnail: Data? = nil) {
        if let title = title {
            appMedia.title = title
        }
        if let thumbnail = thumbnail {
            appMedia.thumbnail = thumbnail
        }
        
        saveContext()
    }
    
    func deleteAppMedia(appMedia: AppMedia) {
        context.delete(appMedia)
        saveContext()
    }
    
    // MARK: - Count Operations
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



