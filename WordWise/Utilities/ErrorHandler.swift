import Foundation
import Observation

enum AppError: LocalizedError {
    case importFailed(String)
    case databaseSaveFailed(String)
    case invalidFileFormat
    case unauthorized
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .importFailed(let msg): return "Import Failed: \(msg)"
        case .databaseSaveFailed(let msg): return "Database Error: \(msg)"
        case .invalidFileFormat: return "Invalid File Format"
        case .unauthorized: return "Unauthorized Access"
        case .unknown(let msg): return "An unknown error occurred: \(msg)"
        }
    }
}

@Observable class ErrorHandler {
    static let shared = ErrorHandler()
    var currentError: AppError?
    var showErrorMessage = false
    
    func handle(_ error: Error) {
        if let appError = error as? AppError {
            currentError = appError
        } else {
            currentError = .unknown(error.localizedDescription)
        }
        showErrorMessage = true
    }
    
    func clear() {
        currentError = nil
        showErrorMessage = false
    }
}
