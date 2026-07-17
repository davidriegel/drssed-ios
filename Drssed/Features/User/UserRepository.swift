//
//  UserRepository.swift
//  Drssed
//
//  Created by David Riegel on 11.05.26.
//

import Combine

public final class UserRepository {
    public static let shared = UserRepository()
    private let store: UserStore = UserStore.shared
    
    private let currentUserSubject: CurrentValueSubject<User?, Never>
    
    var currentUser: User? { currentUserSubject.value }
    var currentUserPublisher: AnyPublisher<User?, Never> { currentUserSubject.eraseToAnyPublisher() }
    private var refreshTask: Task<User, Error>?
    
    // MARK: - Initializer
    
    private init() {
        self.currentUserSubject = CurrentValueSubject(store.load())
    }
    
    // MARK: - Public API
    
    public func setCurrentUser(_ user: User) throws {
        try store.save(user)
        currentUserSubject.send(user)
    }
    
    public func clear() {
        store.clear()
        refreshTask?.cancel()
        refreshTask = nil
        currentUserSubject.send(nil)
    }
    
    @discardableResult
    public func refreshCurrentUser() async -> User? {
        if let existing = refreshTask { return try? await existing.value }
        let task = Task<User, Error> {
            defer { refreshTask = nil }
            let userAPI = try await APIClient.shared.userHandler.fetchCurrentUser()
            let user = userAPI.toDomain()
            try store.save(user)
            currentUserSubject.send(user)
            return user
        }
        refreshTask = task
        
        do {
            return try await task.value
        } catch {
            ErrorHandler.handleSilently(error)
            return currentUserSubject.value
        }
    }
    
    // MARK: - Private
    
    private func setCurrentUser(_ user: User?) {
        currentUserSubject.send(user)
    }
}
