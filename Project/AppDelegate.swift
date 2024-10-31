import UIKit
import CoreData

@main
/// The AppDelegate class serves as the main entry point for the application and manages application lifecycle events and Core Data setup.
class AppDelegate: UIResponder, UIApplicationDelegate {

    // MARK: - Application Lifecycle

    /// Called when the application has finished launching.
    /// - Parameters:
    ///   - application: The application instance.
    ///   - launchOptions: A dictionary containing launch options.
    /// - Returns: A Boolean value indicating whether the application launched successfully.
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        return true
    }
    
    /// The orientation lock setting for the application.
    var orientationLock: UIInterfaceOrientationMask = .all
    
    /// Specifies the supported interface orientations for the application.
    /// - Parameters:
    ///   - application: The application instance.
    ///   - window: The window that is being displayed.
    /// - Returns: A bitmask that identifies the supported interface orientations for the window.
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return orientationLock
    }

    // MARK: - UISceneSession Lifecycle

    /// Called when a new scene session is being created.
    /// - Parameters:
    ///   - application: The application instance.
    ///   - connectingSceneSession: The session that is being connected.
    ///   - options: Options to configure the new scene session.
    /// - Returns: A UISceneConfiguration object that defines the behavior of the new scene session.
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    // MARK: - Core Data stack

    /// The persistent container for the application, encapsulating the Core Data stack.
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Project")
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        return container
    }()

    // MARK: - Core Data Saving support

    /// Saves the context if there are any changes.
    /// This method checks for unsaved changes and attempts to save them to the persistent store.
    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
}
