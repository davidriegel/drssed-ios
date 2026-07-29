//
//  OutfitRecommendationSession.swift
//  Drssed
//
//  Created by David Riegel on 28.07.26.
//

import Foundation

/// Buffered access to the weather based recommendations of the server.
///
/// The server answers in a random order, so a reroll can simply hand out the next page of an
/// already fetched batch and only has to wait for the network once the buffer runs dry.
@MainActor
final class OutfitRecommendationSession {

    // MARK: - Configuration

    /// How many recommendations one reroll shows.
    private(set) var pageSize: Int
    /// How many are asked for per request, so that a few rerolls are covered by one round trip.
    private(set) var batchSize: Int

    // MARK: - Dependencies

    private let repository = AppRepository.shared.outfitRepository

    // MARK: - State

    private var pendingRecommendations: [Outfit] = []
    private var lastFetchFeelsLike: Double?
    private var prefetchTask: Task<Void, Never>?

    // MARK: - Init

    init(pageSize: Int = 3, batchSize: Int = 9) {
        self.pageSize = pageSize
        self.batchSize = batchSize
    }

    // MARK: - Public API

    /// The next page of recommendations – shorter than `pageSize` when the user does not own
    /// enough outfits, empty when none of them fits.
    func nextPage(feelsLike: Double) async throws -> [Outfit] {
        if feelsLike != lastFetchFeelsLike {
            invalidateBuffer()
        }

        if pendingRecommendations.count < pageSize {
            try await fetchBatch(feelsLike: feelsLike)
        }

        let page = Array(pendingRecommendations.prefix(pageSize))
        pendingRecommendations.removeFirst(page.count)

        if pendingRecommendations.count <= pageSize {
            schedulePrefetch(feelsLike: feelsLike)
        }

        return page
    }

    func invalidateBuffer() {
        pendingRecommendations.removeAll()
        prefetchTask?.cancel()
        prefetchTask = nil
    }

    // MARK: - Private

    private func fetchBatch(feelsLike: Double) async throws {
        let outfits = try await repository.recommendOutfits(feelsLike: feelsLike, limit: batchSize)

        buffer(outfits)
        lastFetchFeelsLike = feelsLike
    }

    private func schedulePrefetch(feelsLike: Double) {
        prefetchTask?.cancel()
        prefetchTask = Task { [weak self] in
            guard let self else { return }

            let outfits = try? await self.repository.recommendOutfits(
                feelsLike: feelsLike,
                limit: self.batchSize
            )

            guard !Task.isCancelled else { return }

            // Only append while the buffer still belongs to the same temperature.
            guard feelsLike == self.lastFetchFeelsLike, let outfits, !outfits.isEmpty else { return }

            self.buffer(outfits)
        }
    }

    /// Two batches can overlap, so an outfit that is already waiting is never queued twice.
    private func buffer(_ outfits: [Outfit]) {
        var known = Set(pendingRecommendations.map(\.id))

        for outfit in outfits where known.insert(outfit.id).inserted {
            pendingRecommendations.append(outfit)
        }
    }
}
