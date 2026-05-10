//
//  OutfitSuggestionSession.swift
//  Drssed
//
//  Created by David Riegel on 10.05.26.
//

import Foundation

@MainActor
final class OutfitSuggestionSession {

    // MARK: - Configuration

    private(set) var batchSize: Int
    private(set) var prefetchThreshold: Int

    // MARK: - Dependencies

    private let repository = AppRepository.shared.outfitRepository

    // MARK: - State

    private var pendingSuggestions: [Outfit] = []
    private var lastFetchAnchor: Set<String> = []
    private var prefetchTask: Task<Void, Never>?

    // MARK: - Init

    init(batchSize: Int = 3, prefetchThreshold: Int = 1) {
        self.batchSize = batchSize
        self.prefetchThreshold = prefetchThreshold
    }

    // MARK: - Public API

    func next(currentAnchor: Set<String>) async throws -> Outfit {
        if currentAnchor != lastFetchAnchor {
            invalidateBuffer()
        }

        if pendingSuggestions.isEmpty {
            try await fetchBatch(anchor: currentAnchor)
        }

        let next = pendingSuggestions.removeFirst()

        if pendingSuggestions.count <= prefetchThreshold {
            schedulePrefetch(anchor: currentAnchor)
        }

        return next
    }

    func invalidateBuffer() {
        pendingSuggestions.removeAll()
        prefetchTask?.cancel()
        prefetchTask = nil
    }

    // MARK: - Private

    private func fetchBatch(anchor: Set<String>) async throws {
        let anchorIDs = anchor.isEmpty ? nil : Array(anchor)
        let outfits = try await repository.generateOutfits(
            amount: batchSize,
            anchorIDs: anchorIDs
        )
        pendingSuggestions = outfits
        lastFetchAnchor = anchor
    }

    private func schedulePrefetch(anchor: Set<String>) {
        prefetchTask?.cancel()
        prefetchTask = Task { [weak self] in
            guard let self else { return }
            let anchorIDs = anchor.isEmpty ? nil : Array(anchor)
            let outfits = try? await self.repository.generateOutfits(
                amount: self.batchSize,
                anchorIDs: anchorIDs
            )
            guard !Task.isCancelled else { return }
            
            // Only append if anchor hasn't changed
            guard anchor == self.lastFetchAnchor, let outfits, !outfits.isEmpty else { return }
            self.pendingSuggestions.append(contentsOf: outfits)
        }
    }
}
