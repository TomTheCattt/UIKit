import CoreData
import UIKit
import Photos

// MARK: - CoreDataManager
/// A singleton class for managing Core Data operations related to the AppMedia entity.
/// It provides methods for creating, reading, updating, and deleting media assets in Core Data.
final class CoreDataManager {
    
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
}
