//
//  OAuthBrowserPresenter.swift
//  OneLoop
//
//  Reliable ASWebAuthenticationSession host for Supabase OAuth.
//  Completes when either:
//  - the session hits oneloop://…, or
//  - the app receives the same deep link via onOpenURL (belt and suspenders).
//

import AuthenticationServices
import UIKit

@MainActor
final class OAuthBrowserPresenter: NSObject, ASWebAuthenticationPresentationContextProviding {
    static let shared = OAuthBrowserPresenter()

    private var authSession: ASWebAuthenticationSession?
    private var continuation: CheckedContinuation<URL, Error>?
    private var didFinish = false

    private override init() {
        super.init()
    }

    /// Starts an auth session and returns the callback URL (scheme must match).
    func authenticate(
        url: URL,
        callbackScheme: String = "oneloop"
    ) async throws -> URL {
        // Cancel any in-flight session.
        cancelInFlight(with: CancellationError())

        return try await withCheckedThrowingContinuation { continuation in
            self.didFinish = false
            self.continuation = continuation

            let session = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: callbackScheme
            ) { [weak self] callbackURL, error in
                guard let self else { return }
                Task { @MainActor in
                    if let error {
                        self.finish(.failure(error))
                    } else if let callbackURL {
                        self.finish(.success(callbackURL))
                    } else {
                        self.finish(
                            .failure(
                                NSError(
                                    domain: "OneLoop.OAuth",
                                    code: -1,
                                    userInfo: [
                                        NSLocalizedDescriptionKey:
                                            "Sign-in finished without a callback URL."
                                    ]
                                )
                            )
                        )
                    }
                }
            }

            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = true
            self.authSession = session

            if !session.start() {
                self.finish(
                    .failure(
                        NSError(
                            domain: "OneLoop.OAuth",
                            code: -2,
                            userInfo: [
                                NSLocalizedDescriptionKey:
                                    "Could not start the sign-in browser session."
                            ]
                        )
                    )
                )
            }
        }
    }

    /// Call from `onOpenURL` if the deep link arrives while a session is open.
    func handleIncomingURL(_ url: URL) -> Bool {
        guard url.scheme?.lowercased() == "oneloop" else {
            return false
        }
        guard continuation != nil else {
            return false
        }
        finish(.success(url))
        return true
    }

    func presentationAnchor(
        for session: ASWebAuthenticationSession
    ) -> ASPresentationAnchor {
        let scenes = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }

        if let window = scenes
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)
        {
            return window
        }

        if let window = scenes.flatMap(\.windows).first {
            return window
        }

        return ASPresentationAnchor()
    }

    private func finish(_ result: Result<URL, Error>) {
        guard !didFinish else { return }
        didFinish = true

        let cont = continuation
        continuation = nil

        let session = authSession
        authSession = nil

        // Dismiss the browser if it's still up.
        session?.cancel()

        cont?.resume(with: result)
    }

    private func cancelInFlight(with error: Error) {
        guard continuation != nil else {
            authSession?.cancel()
            authSession = nil
            return
        }
        finish(.failure(error))
    }
}
