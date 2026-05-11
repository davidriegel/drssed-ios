//
//  UserStore.swift
//  Drssed
//
//  Created by David Riegel on 11.05.26.
//

import Foundation

public final class UserStore {
    public static let shared = UserStore()
    
    private let url: URL = {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("user.json")
    }()
    
    func load() -> User? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(User.self, from: data)
    }
    
    func save(_ user: User) throws {
        let data = try JSONEncoder().encode(user)
        try data.write(to: url, options: [.atomic, .completeFileProtection])
    }
    
    func clear() {
        try? FileManager.default.removeItem(at: url)
    }
}
