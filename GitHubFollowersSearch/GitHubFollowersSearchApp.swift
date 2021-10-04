//
//  GitHubFollowersSearchApp.swift
//  GitHubFollowersSearch
//
//  Created by Jason Goodney on 10/2/21.
//

import ComposableArchitecture
import SwiftUI

@main
struct GitHubFollowersSearchApp: App {
    var body: some Scene {
        WindowGroup {
            SearchView(
                store: Store(
                    initialState: SearchState(),
                    reducer: searchReducer.debug(),
                    environment: SearchEnvironment()
                )
            )
        }
    }
}
