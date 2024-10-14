//
//  CoreDataHandle.swift
//  Project
//
//  Created by Việt Anh Nguyễn on 13/10/2024.
//

import CoreData
import UIKit

// MARK: - CoreDataManager

class CoreDataManager {
    
    // Singleton instance
    static let shared = CoreDataManager()
    
    private init() {}
    
    // MARK: - Persistent Container
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Project")
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        return container
    }()
    
    // Context for Core Data operations
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
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
    
    // MARK: - AppImage CRUD Operations
    
    func createAppImage(title: String, filepath: String, thumbnail: Data) -> AppImage {
        let appImage = AppImage(context: context)
        appImage.title = title
        appImage.filepath = filepath
        appImage.thumbnail = thumbnail
        // id is automatically set as UUID when the object is created
        
        saveContext()
        return appImage
    }
    
    func fetchAllAppImages() -> [AppImage] {
        let request: NSFetchRequest<AppImage> = AppImage.fetchRequest()
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching AppImages: \(error)")
            return []
        }
    }
    
    func updateAppImage(appImage: AppImage, title: String? = nil, filepath: String? = nil, thumbnail: Data? = nil) {
        if let title = title {
            appImage.title = title
        }
        if let filepath = filepath {
            appImage.filepath = filepath
        }
        if let thumbnail = thumbnail {
            appImage.thumbnail = thumbnail
        }
        
        saveContext()
    }
    
    func deleteAppImage(appImage: AppImage) {
        context.delete(appImage)
        saveContext()
    }
    
    // MARK: - AppVideo CRUD Operations
    
    func createAppVideo(title: String, filepath: String, thumbnail: Data, duration: Double) -> AppVideo {
        let appVideo = AppVideo(context: context)
        appVideo.title = title
        appVideo.filepath = filepath
        appVideo.thumbnail = thumbnail
        appVideo.duration = duration
        // id is automatically set as UUID when the object is created
        
        saveContext()
        return appVideo
    }
    
    func fetchAllAppVideos() -> [AppVideo] {
        let request: NSFetchRequest<AppVideo> = AppVideo.fetchRequest()
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching AppVideos: \(error)")
            return []
        }
    }
    
    func updateAppVideo(appVideo: AppVideo, title: String? = nil, filepath: String? = nil, thumbnail: Data? = nil, duration: Double? = nil) {
        if let title = title {
            appVideo.title = title
        }
        if let filepath = filepath {
            appVideo.filepath = filepath
        }
        if let thumbnail = thumbnail {
            appVideo.thumbnail = thumbnail
        }
        if let duration = duration {
            appVideo.duration = duration
        }
        
        saveContext()
    }
    
    func deleteAppVideo(appVideo: AppVideo) {
        context.delete(appVideo)
        saveContext()
    }
    
    // MARK: - Fetch by ID
    
    func fetchAppImage(byId id: UUID) -> AppImage? {
        let request: NSFetchRequest<AppImage> = AppImage.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        do {
            let results = try context.fetch(request)
            return results.first
        } catch {
            print("Error fetching AppImage by ID: \(error)")
            return nil
        }
    }
    
    func fetchAppVideo(byId id: UUID) -> AppVideo? {
        let request: NSFetchRequest<AppVideo> = AppVideo.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        do {
            let results = try context.fetch(request)
            return results.first
        } catch {
            print("Error fetching AppVideo by ID: \(error)")
            return nil
        }
    }
}

// MARK: - CoreDataManager Extension for Count Operations

extension CoreDataManager {
    
    func fetchAppImagesCount() -> Int {
        let fetchRequest: NSFetchRequest<AppImage> = AppImage.fetchRequest()
        do {
            let count = try context.count(for: fetchRequest)
            return count
        } catch {
            print("Failed to fetch AppImage count: \(error)")
            return 0
        }
    }
    
    func fetchAppVideosCount() -> Int {
        let fetchRequest: NSFetchRequest<AppVideo> = AppVideo.fetchRequest()
        do {
            let count = try context.count(for: fetchRequest)
            return count
        } catch {
            print("Failed to fetch AppVideo count: \(error)")
            return 0
        }
    }
}

// MARK: - UIImage Extension

extension UIImage {
    
    // Converts UIImage to Data
    var toData: Data? {
        return pngData()
    }
}



