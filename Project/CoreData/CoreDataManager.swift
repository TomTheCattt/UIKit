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
    
    func printCount() {
        let fetchRequest = NSFetchRequest<NSNumber>(entityName: "AppMedia")
        fetchRequest.resultType = .countResultType  // Only fetch the count of objects
        
        do {
            let count = try context.count(for: fetchRequest)
            print("Total count of AppMedia entities: \(count)")
        } catch {
            print("Failed to count AppMedia entities: \(error)")
        }
    }
    func printAllAppMedia() {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "AppMedia")
        
        do {
            // Execute fetch request
            let appMediaItems = try context.fetch(fetchRequest)
            
            // Check if there are any items
            guard !appMediaItems.isEmpty else {
                print("No AppMedia items found.")
                return
            }
            
            // Loop through each item and print its properties
            for item in appMediaItems {
                if let title = item.value(forKey: "title") as? String,
                   let createdAt = item.value(forKey: "createdAt") as? Date,
                   let mediaType = item.value(forKey: "mediaType") as? String {
                    print("Title: \(title), Created At: \(createdAt), Media Type: \(mediaType)")
                } else {
                    print("Unable to retrieve all properties for item \(item)")
                }
            }
        } catch {
            print("Failed to fetch AppMedia items: \(error)")
        }
    }
    func deleteAllAppMedia() {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "AppMedia")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            // Execute the batch delete request
            try context.execute(deleteRequest)
            
            // Save the context to persist changes
            try context.save()
            
            print("Successfully deleted all AppMedia items.")
        } catch {
            print("Failed to delete AppMedia items: \(error)")
        }
    }
    func printRecordsWithNilAttribute(attributeName: String) {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "AppMedia")
        
        // Predicate to filter records where the attribute is nil
        fetchRequest.predicate = NSPredicate(format: "%K == nil", attributeName)
        
        do {
            // Fetch the records from Core Data
            let recordsWithNilAttribute = try context.fetch(fetchRequest)
            
            // Check if there are any records with the nil attribute
            if recordsWithNilAttribute.isEmpty {
                print("No records found with \(attributeName) set to nil.")
            } else {
                print("Records with \(attributeName) set to nil:")
                for record in recordsWithNilAttribute {
                    print(record)
                }
            }
        } catch {
            print("Failed to fetch records with \(attributeName) set to nil: \(error)")
        }
    }
}
