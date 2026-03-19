//
//  SceneDelegate.swift
//  Outfitter
//
//  Created by David Riegel on 06.05.24.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        let window = UIWindow(windowScene: windowScene)
        
        let _ = PersistenceController.shared
        
        window.rootViewController = LoadingViewController()
        window.makeKeyAndVisible()
        self.window = window
        
        Task {
            await initializeApp()
        }
    }
    
    private func initializeApp() async {
        let authState = await AuthenticationManager.shared.determineCurrentAuthState()
        
        switch authState {
        case .unknown, .unauthenticated:
            await handleUnauthenticatedState()
        case .guest:
            await showMainApp(asGuest: true)
        case .authenticated:
            await showMainApp(asGuest: false)
        }
    }
    
    private func handleUnauthenticatedState() async {
        do {
            try await AuthenticationManager.shared.registerAsGuest()
            await SyncManager.shared.clearSyncState()
            await showMainApp(asGuest: true)
        } catch {
            await MainActor.run {
                self.window?.rootViewController = ErrorViewController(
                    error: error,
                    retryAction: { [weak self] in
                        Task {
                            await self?.initializeApp()
                        }
                    }
                )
            }
        }
    }
    
    private func showMainApp(asGuest: Bool) async {
        await MainActor.run {
            let tabBar = TabBarController()
            // setup specifically for guest or signed in user
            self.window?.rootViewController = tabBar
            
            Task {
                await NetworkManager.shared.checkServerReachable()
                if NetworkManager.shared.isReachable {
                    await SyncManager.shared.syncWithServer()
                }
            }
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }


}

