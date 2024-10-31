import UIKit

/// The SceneDelegate class manages the life cycle of a single scene in the application.
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    /// The window associated with the scene.
    var window: UIWindow?
    
    /// Called when the scene is being created and is about to connect to a session.
    /// - Parameters:
    ///   - scene: The scene that is being connected.
    ///   - session: The session associated with the scene.
    ///   - connectionOptions: Options for configuring the new scene.
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        // Create a new window with the provided window scene
        window = UIWindow(windowScene: windowScene)
        
        // Set the root view controller for the window
        let containerViewController = ContainerViewController()
        window?.rootViewController = containerViewController
        
        // Make the window key and visible
        window?.makeKeyAndVisible()
    }
    
    /// Called as the scene is being released by the system.
    /// This can occur when the user closes the app or the system reclaims resources.
    func sceneDidDisconnect(_ scene: UIScene) {
        // Handle any cleanup necessary when the scene disconnects
    }
    
    /// Called when the scene has moved from an inactive state to an active state.
    /// This is a good place to restart any tasks that were paused when the scene was inactive.
    func sceneDidBecomeActive(_ scene: UIScene) {
        // Restart tasks that were paused (or not yet started) while the scene was inactive
    }
    
    /// Called when the scene will move from an active state to an inactive state.
    /// This can occur for certain types of temporary interruptions (e.g., incoming phone call).
    func sceneWillResignActive(_ scene: UIScene) {
        // Pause ongoing tasks, disable timers, etc.
    }
    
    /// Called as the scene transitions from the background to the foreground.
    /// This is the appropriate place to undo changes made on entering the background.
    func sceneWillEnterForeground(_ scene: UIScene) {
        // Undo changes made when entering the background
    }
    
    /// Called as the scene transitions from the foreground to the background.
    /// Use this method to save data, release shared resources, and store enough scene-specific state information
    /// to restore the scene back to its current state.
    func sceneDidEnterBackground(_ scene: UIScene) {
        // Save data and release shared resources
        (UIApplication.shared.delegate as? AppDelegate)?.saveContext()
    }
}
