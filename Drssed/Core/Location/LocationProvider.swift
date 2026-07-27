//
//  LocationProvider.swift
//  Drssed
//
//  Created by David Riegel on 27.07.26.
//

import CoreLocation

/// One-shot access to the current position, used to look up the weather of a wear.
///
/// Every failure – denied permission, no fix in time, location services off – ends up
/// as `nil` instead of an error: prefilling is a convenience, never a blocker.
@MainActor
final class LocationProvider: NSObject {
    static let shared = LocationProvider()

    private let manager = CLLocationManager()
    private var waiters: [CheckedContinuation<CLLocation?, Never>] = []
    private var timeoutTask: Task<Void, Never>?

    /// A fix stays good enough for the weather for a while.
    private var lastFix: (location: CLLocation, at: Date)?

    private static let fixLifetime: TimeInterval = 10 * 60
    /// How long a fix may take once the app is allowed to ask for one.
    private static let fixTimeout: Duration = .seconds(8)
    /// The permission dialog waits for the user, so it gets a far longer leash.
    private static let authorizationTimeout: Duration = .seconds(120)

    private override init() {
        super.init()

        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    var isDenied: Bool {
        return manager.authorizationStatus == .denied || manager.authorizationStatus == .restricted
    }

    func currentLocation() async -> CLLocation? {
        if let lastFix, Date().timeIntervalSince(lastFix.at) < Self.fixLifetime {
            return lastFix.location
        }

        switch manager.authorizationStatus {
        case .notDetermined:
            // The fix is requested once the user answered the permission dialog.
            manager.requestWhenInUseAuthorization()
            startTimeout(after: Self.authorizationTimeout)
        case .authorizedAlways, .authorizedWhenInUse:
            manager.requestLocation()
            startTimeout(after: Self.fixTimeout)
        default:
            return nil
        }

        return await withCheckedContinuation { continuation in
            waiters.append(continuation)
        }
    }

    private func startTimeout(after duration: Duration) {
        timeoutTask?.cancel()
        timeoutTask = Task { [weak self] in
            try? await Task.sleep(for: duration)

            guard !Task.isCancelled else { return }

            self?.finish(with: nil)
        }
    }

    private func finish(with location: CLLocation?) {
        timeoutTask?.cancel()
        timeoutTask = nil

        if let location {
            lastFix = (location, Date())
        }

        let pending = waiters
        waiters.removeAll()

        pending.forEach { $0.resume(returning: location) }
    }
}

// The callbacks arrive on the queue the manager was created on, which is the main queue here.
extension LocationProvider: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        MainActor.assumeIsolated {
            guard !waiters.isEmpty else { return }

            switch manager.authorizationStatus {
            case .authorizedAlways, .authorizedWhenInUse:
                // The user just answered the dialog, from here a fix should be quick.
                manager.requestLocation()
                startTimeout(after: Self.fixTimeout)
            case .notDetermined:
                break
            default:
                finish(with: nil)
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        MainActor.assumeIsolated {
            finish(with: locations.last)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        ErrorHandler.handleSilently(error)

        MainActor.assumeIsolated {
            finish(with: nil)
        }
    }
}
