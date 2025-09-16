//
//  ErrorHandler.swift
//  Clothing Booth
//
//  Created by David Riegel on 23.04.25.
//

import UIKit

public enum ErrorHandler {
    // MARK: -- Handle error
    
    public static func handle(_ error: Error, suppressed: [APIError] = [], _ file: String = #file, _ function: String = #function, _ line: Int = #line) {
        logError(error, file, function, line)
        
        if let apiError = error as? APIError {
            guard !suppressed.contains(apiError) else { return }
            
            return handleAPIError(apiError)
        }
        
        if let customError = error as? CustomError {
            return handleCustomError(customError)
        }
        
        showAlert("An unknown error occurred.")
    }
    
    private static func handleAPIError(_ error: APIError) {
        var message = ""
        var solution: String?
        switch error {
        case .internalServerError, .methodNotAllowed, .badRequest:
            message = "There was an issue processing your request."
            solution = "Please try again or contact support if the problem persists."
        case .tooManyRequests:
            message = "You're going too fast. Please try again later."
        case .unprocessableContent:
            message = "The content of your request is invalid."
            solution = "Please ensure the data you're sending is correct and try again."
        case .unprocessableContentWithMessage(let msg, suggestion: let suggestion):
            message = msg
            solution = suggestion
        case .payloadTooLarge:
            message = "The data you're trying to send is too large."
            solution = "Please reduce the size of your request and try again."
        case .payloadTooLargeWithMessage(let msg, suggestion: let suggestion):
            message = msg
            solution = suggestion
        case .conflict:
            message = "There was a conflict with the request."
            solution = "Please ensure no conflicting actions are being made and try again."
        case .notFound:
            message = "The requested resource was not found."
            solution = "Please check if the resource exists and try again."
        case .forbidden:
            message = "You don't have permission to access this resource."
            solution = "Ensure you have the correct permissions and try again."
        case .unauthorized:
            message = "You are not authorized to make this request."
            solution = "Please log in or provide the necessary credentials."
        case .offline:
            message = "There's a problem with your internet connection."
            solution = "Please ensure a stable internet connection to connect to online services."
        case .custom(let string):
            message = "An unknown API error occurred."
            solution = string
        case .unknown:
            message = "An unknown API error occurred."
            solution = "Please try again later."
        }
        
        showAlert(message, solution: solution)
    }
    
    private static func handleCustomError(_ error: CustomError) {
        var message = ""
        var solution: String?
        
        switch error {
        case .formInvalid(let field, let suggestion):
            message = "\(field) is invalid."
            solution = suggestion
        case .valueTooLong(let field, let maxLength):
            message = "\(field) can only be \(maxLength) characters long."
        case .valueTooShort(let field, let minLength):
            message = "\(field) must be at least \(minLength) characters long."
        case .missingValue(let field, let suggestion):
            message = "\(field) is missing before you can continue."
            solution = suggestion
        case .custom(let string, let suggestion):
            message = string
            solution = suggestion
        }
        
        showAlert(message, solution: solution)
    }
    
    // MARK: -- Show alerts
    
    private static func showAlert(_ msg: String, solution: String? = nil) {
        var alertMsg = msg
        if let solution = solution {
            alertMsg += "\n\n\(solution)"
        }
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Error", message: alertMsg, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default))
            
            UIApplication.shared.topMostViewController()?.present(alert, animated: true)
        }
    }
    
    // MARK: -- Log error
    
    private static func logError(_ error: Error, _ file: String = #file, _ function: String = #function, _ line: Int = #line) {
        #if DEBUG
        print(error)
        let fileName = (file as NSString).lastPathComponent
        print("Error: \(error.localizedDescription)\nFile: \(fileName) \nFunction: \(function) \nLine: \(line)")
        #endif
    }
}
