//
//  SceneDelegate.swift
//  Outfitter
//
//  Created by David Riegel on 06.05.24.
//

import Combine
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    private var authStateCancellable: AnyCancellable?

    /// Set as soon as the app has had an account of any kind. It separates a fresh install,
    /// which is let straight in as a guest, from a user who signed out or deleted theirs and
    /// should get the choice instead of a silent new guest account.
    private static let hasHadAccountKey = "hasHadAccount"
    private static let lastSyncedVersionKey = "lastFullSyncAppVersion"

        private var currentAppVersion: String {
            let short = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
            let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
            return "\(short) (\(build))"
        }

    private var hasHadAccount: Bool {
        get { UserDefaults.standard.bool(forKey: Self.hasHadAccountKey) }
        set { UserDefaults.standard.set(newValue, forKey: Self.hasHadAccountKey) }
    }

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
        await AppRepository.shared.userRepository.refreshCurrentUser()
        
        switch authState {
        case .unknown, .unauthenticated:
            await handleUnauthenticatedState()
        case .guest:
            hasHadAccount = true
            await showMainApp()
        case .authenticated:
            hasHadAccount = true
            await showMainApp()
        }

        await observeAuthState()
    }

    /// A fresh install is let straight in as a guest. Anything later means the user signed
    /// out or deleted their account, and gets to choose what happens next instead of
    /// silently receiving a new guest account.
    private func handleUnauthenticatedState() async {
        guard hasHadAccount else {
            await registerGuestAndEnterApp()
            return
        }

        await showAuthLanding()
    }

    /// Routes on its own rather than leaving it to the auth-state observer: this runs during
    /// start-up, before that observer exists.
    private func registerGuestAndEnterApp() async {
        do {
            await SyncManager.shared.clearSyncState()
            try await AuthenticationManager.shared.registerAsGuest()

            hasHadAccount = true
            await showMainApp()
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

    private func showAuthLanding() async {
        await MainActor.run {
            self.window?.rootViewController = AuthLandingController()
        }
    }

    /// Signing out and deleting happen deep inside the app, so the swap back to the choice
    /// screen – and forward again once an account exists – is handled here for all of them.
    private func observeAuthState() async {
        await MainActor.run {
            self.authStateCancellable = AuthenticationManager.shared.authStatePublisher
                .removeDuplicates()
                .sink { [weak self] state in
                    guard let self else { return }

                    // Only the two runtime transitions belong here. Start-up routes itself,
                    // and matching on the exact screen keeps the two from colliding.
                    let root = self.window?.rootViewController
                    let isShowingApp = root is TabBarController
                    let isShowingLanding = root is AuthLandingController

                    switch state {
                    case .unauthenticated where isShowingApp:
                        Task { await self.showAuthLanding() }
                    case .guest where isShowingLanding:
                        self.hasHadAccount = true
                        Task { await self.showMainApp() }
                    case .authenticated where isShowingLanding:
                        self.hasHadAccount = true
                        Task { await self.showMainApp() }
                    default:
                        break
                    }
                }
        }
    }
    
    private func showMainApp() async {
        await MainActor.run {
            let tabBar = TabBarController()
            self.window?.rootViewController = tabBar
            
            Task {
                await NetworkManager.shared.checkServerReachable()
                guard NetworkManager.shared.isReachable else { return }
                
                let version = self.currentAppVersion
                let isFirstRunOfVersion = UserDefaults.standard.string(forKey: Self.lastSyncedVersionKey) != version

                let didSync = await SyncManager.shared.syncWithServer(forceFull: isFirstRunOfVersion)

                if isFirstRunOfVersion, didSync {
                    UserDefaults.standard.set(version, forKey: Self.lastSyncedVersionKey)
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
        guard window?.rootViewController is TabBarController else { return }

        Task {
            await NetworkManager.shared.checkServerReachable()
            await SyncManager.shared.syncIfStale()
        }
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }


}

