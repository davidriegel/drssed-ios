//
//  ErrorHandler.swift
//  Drssed
//
//  Created by David Riegel on 23.04.25.
//

import UIKit
import Foundation

public enum ErrorHandler {
    
    // MARK: - Public Interface
    
    public static func handle(
        _ error: Error,
        file: String = #file,
        function: String = #function,
        line: Int = #line,
        presentingViewController: UIViewController? = nil
    ) {
        logError(error, file, function, line)
        
        let appError = mapToAppError(error)
        presentError(appError, from: presentingViewController)
    }
    
    public static func handleSilently(
        _ error: Error,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        logError(error, file, function, line)
    }
    
    // MARK: - Error Mapping
    
    private static func mapToAppError(_ error: Error) -> AppError {
        if let apiError = error as? APIError {
            return .api(apiError)
        } else if let coreDataError = error as? CoreDataError {
            return .coreData(coreDataError)
        } else if let authError = error as? AuthenticationError {
            return .authentication(authError)
        } else if let customError = error as? CustomError {
            return .custom(customError)
        } else {
            return .system(error)
        }
    }
    
    // MARK: - Error Presentation
    
    private static func presentError(_ error: AppError, from viewController: UIViewController?) {
        let (title, message, actions) = errorDetails(for: error)
        
        DispatchQueue.main.async {
            showAlert(
                title: title,
                message: message,
                actions: actions,
                from: viewController
            )
        }
    }
    
    private static func errorDetails(for error: AppError) -> (title: String, message: String, actions: [AlertAction]) {
        switch error {
        case .api(let apiError):
            return apiErrorDetails(apiError)
        case .coreData(let coreDataError):
            return coreDataErrorDetails(coreDataError)
        case .authentication(let authError):
            return authenticationErrorDetails(authError)
        case .custom(let customError):
            return customErrorDetails(customError)
        case .system(let systemError):
            return systemErrorDetails(systemError)
        }
    }
    
    // MARK: - API Error Details
    
    private static func apiErrorDetails(_ error: APIError) -> (String, String, [AlertAction]) {
        let title = String(localized: "error.title.api")
        
        var message = error.localizedDescription
        if let suggestion = error.recoverySuggestion {
            message += "\n\n\(suggestion)"
        }
        
        return (title, message, [.dismiss])
    }
    
    // MARK: - CoreData Error Details
    
    private static func coreDataErrorDetails(_ error: CoreDataError) -> (String, String, [AlertAction]) {
        let title = String(localized: "error.title.coreData")
        
        var message = error.localizedDescription
        if let suggestion = error.recoverySuggestion {
            message += "\n\n\(suggestion)"
        }
                
        return (title, message, [.dismiss])
    }
    
    // MARK: - Authentication Error Details
    
    private static func authenticationErrorDetails(_ error: AuthenticationError) -> (String, String, [AlertAction]) {
        let title = String(localized: "error.title.authentication")
        
        var message = error.localizedDescription
        if let suggestion = error.recoverySuggestion {
            message += "\n\n\(suggestion)"
        }
        
        return (title, message, [.dismiss])
    }
    
    // MARK: - Custom Error Details
    
    private static func customErrorDetails(_ error: CustomError) -> (String, String, [AlertAction]) {
        let title = String(localized: "error.title.validation")
        
        var message = error.localizedDescription
        if let suggestion = error.recoverySuggestion {
            message += "\n\n\(suggestion)"
        }
        
        return (title, message, [.dismiss])
    }
    
    // MARK: - System Error Details
    
    private static func systemErrorDetails(_ error: Error) -> (String, String, [AlertAction]) {
        let title = String(localized: "error.title.system")
        
        let message = error.localizedDescription
        
        return (title, message, [.dismiss])
    }
    
    // MARK: - Alert Presentation
    
    private static func showAlert(
        title: String,
        message: String,
        actions: [AlertAction],
        from viewController: UIViewController?
    ) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        
        for action in actions {
            alert.addAction(action.uiAlertAction)
        }
        
        // Präsentiere den Alert
        presentAlert(alert, from: viewController)
    }
    
    private static func presentAlert(
        _ alert: UIAlertController,
        from viewController: UIViewController?,
        retryCount: Int = 0
    ) {
        let presenter = viewController ?? UIApplication.shared.topMostViewController()
        
        guard let presenter = presenter else {
            #if DEBUG
            print("⚠️ No view controller available to present alert")
            #endif
            return
        }
        
        // Prüfe ob der ViewController präsentieren kann
        if presenter.isBeingDismissed || presenter.isBeingPresented || presenter.presentedViewController != nil {
            // ViewController ist gerade busy, versuche es gleich nochmal
            if retryCount < 3 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    presentAlert(alert, from: viewController, retryCount: retryCount + 1)
                }
            } else {
                #if DEBUG
                print("⚠️ Failed to present alert after 3 retries")
                #endif
            }
            return
        }
        
        // Prüfe ob der View im Window ist
        if presenter.view.window == nil {
            // View ist nicht im Window, versuche es gleich nochmal
            if retryCount < 3 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    presentAlert(alert, from: viewController, retryCount: retryCount + 1)
                }
            } else {
                #if DEBUG
                print("⚠️ Presenter view is not in window hierarchy after 3 retries")
                #endif
            }
            return
        }
        
        // Alles OK, präsentiere den Alert
        presenter.present(alert, animated: true)
    }
    
    // MARK: - Logging
    
    private static func logError(
        _ error: Error,
        _ file: String,
        _ function: String,
        _ line: Int
    ) {
        #if DEBUG
        let fileName = (file as NSString).lastPathComponent
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("🔴 ERROR OCCURRED")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📄 File:     \(fileName)")
        print("⚙️  Function: \(function)")
        print("📍 Line:     \(line)")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("💬 Description: \(error.localizedDescription)")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("🔍 Full Error:")
        dump(error)
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
        #endif
    }
}

// Alertaction for better consistency

private enum AlertAction {
    case dismiss
    case retry
    case login
    
    var uiAlertAction: UIAlertAction {
        switch self {
        case .dismiss:
            return UIAlertAction(
                title: String(localized: "common.ok"),
                style: .default
            )
            
        case .retry:
            return UIAlertAction(
                title: String(localized: "error.action.retry"),
                style: .default
            ) { _ in
                // TODO: Implement retry logic
            }
            
        case .login:
            return UIAlertAction(
                title: String(localized: "error.action.login"),
                style: .default
            ) { _ in
                // TODO: Navigate to login screen
            }
        }
    }
}
