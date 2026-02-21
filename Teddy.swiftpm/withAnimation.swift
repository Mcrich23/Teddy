//
//  withAnimation.swift
//  Teddy
//
//  Created by Morris Richman on 12/28/25.
//


import SwiftUI

public func withAnimation<Result>(
    _ animation: Animation? = .default,
    _ body: @MainActor @escaping () throws -> Result
) async rethrows {
    await withCheckedContinuation { continuation in
        // Ensure the work runs on the MainActor
        Task { @MainActor in
            do {
                // SwiftUI's withAnimation is synchronous and runs on main thread
                let _ = try SwiftUI.withAnimation(animation) {
                    try body()
                } completion: {
                    continuation.resume()
                }
            } catch {
                print("Animation Error: \(error)")
                continuation.resume()
            }
        }
    }
}
