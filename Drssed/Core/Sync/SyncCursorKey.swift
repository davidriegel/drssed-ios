//
//  SyncCursorKey.swift
//  Drssed
//
//  Created by David Riegel on 07.05.26.
//

import Foundation
import os

enum SyncCursorKey: String, CaseIterable {
    case clothing = "clothing_last_sync"
    case outfit = "outfit_last_sync"
}

enum SyncCursors {
    static func get(_ key: SyncCursorKey) -> Date? {
        UserDefaults.standard.object(forKey: key.rawValue) as? Date
    }
    
    static func set(_ key: gSyncCursorKey, to date: Date) {
        UserDefaults.standard.set(date, forKey: key.rawValue)
    }
    
    static func resetAll() {
        for key in SyncCursorKey.allCases {
            UserDefaults.standard.removeObject(forKey: key.rawValue)
        }
        
        Logger.sync.notice("All sync cursors reset (\(SyncCursorKey.allCases.count, privacy: .public) keys)")
    }
}
