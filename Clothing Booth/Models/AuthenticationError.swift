public enum AuthenticationError: Error {
    case emailAlreadyInUse
    case usernameAlreadyInUse
    case unknown
}