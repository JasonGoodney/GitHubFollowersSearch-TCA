//
//  SearchFeature.swift
//  GitHubFollowersSearch
//
//  Created by Jason Goodney on 10/2/21.
//

import ComposableArchitecture
import SwiftUI

struct SearchState: Equatable {
    var searchQuery = ""
}

enum SearchAction: Equatable {
    case searchQueryChanged(String)
    case onAppear
}

struct SearchEnvironment {}

let searchReducer = Reducer<SearchState, SearchAction, SearchEnvironment> {
    state, action, environment in
    
    switch action {
    case .onAppear:
        state.searchQuery = ""
        return .none
        
    case let .searchQueryChanged(query):
        state.searchQuery = query
        return .none
    }
}
.debug()

struct SearchView: View {
    let store: Store<SearchState, SearchAction>
    @ObservedObject var viewStore: ViewStore<ViewState, SearchAction>
    
    init(store: Store<SearchState, SearchAction>) {
        self.store = store
        self.viewStore = ViewStore(self.store.scope(state: ViewState.init(state:)))
    }
    
    struct ViewState: Equatable {
        let searchQuery: String
        
        init(state: SearchState) {
            self.searchQuery = state.searchQuery
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {

                TextField(text: viewStore.binding(get: \.searchQuery, send: SearchAction.searchQueryChanged)) {
                    HStack(spacing: 4) {
                        Image(systemName: "magnifyingglass")
                        Text("Search a username... e.g. Octocat")
                    }
                }
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.none)
                .disableAutocorrection(true)
                .padding(.top, 60)
                
                NavigationLink {
                    FollowersView(store: Store(
                        initialState: FollowersState(
                            username: viewStore.searchQuery
                        ),
                        reducer: followersReducer,
                        environment: FollowersEnvironment(
                            client: GitHubClient.live,
                            mainQueue: .main)
                        )
                    )
                } label: {
                    Text("Get Followers")
                        .frame(height: 50)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                        .font(.headline)
                        .background(
                            Color.blue
                                .opacity(viewStore.searchQuery.isEmpty ? 0.5 : 1)
                        )
                        .cornerRadius(16)
                }
                .disabled(viewStore.searchQuery.isEmpty)

                Spacer()
                
            }
            .padding(.horizontal, 40)
            .navigationTitle("Search")
            .onAppear { viewStore.send(.onAppear) }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

// MARK: - SwiftUI previews
struct SearchView_Previews: PreviewProvider {
  static var previews: some View {
    let store = Store(
      initialState: SearchState(),
      reducer: searchReducer,
      environment: SearchEnvironment()
      )

    return SearchView(store: store)
  }
}
