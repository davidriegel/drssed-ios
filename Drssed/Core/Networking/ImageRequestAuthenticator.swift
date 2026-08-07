//
//  ImageRequestAuthenticator.swift
//  Drssed
//
//  Created by David Riegel on 07.08.26.
//

import Foundation
import SDWebImage
import os

/// Attaches the bearer token to image downloads.
///
/// SDWebImage rewrites requests synchronously, so the token cannot be awaited from
/// `TokenManager` at that point. The actor mirrors it here whenever it changes instead.
enum ImageRequestAuthenticator {
    private static let accessToken = OSAllocatedUnfairLock<String?>(initialState: nil)

    static func update(accessToken newValue: String?) {
        accessToken.withLock { $0 = newValue }
    }

    static func install() {
        SDWebImageDownloader.shared.requestModifier = SDWebImageDownloaderRequestModifier { request in
            guard let url = request.url,
                  url.host() == APIClient.baseURL?.host(),
                  let token = accessToken.withLock({ $0 })
            else {
                return request
            }

            var authenticated = request
            authenticated.setValue("Bearer " + token, forHTTPHeaderField: "Authorization")

            return authenticated
        }
    }
}
