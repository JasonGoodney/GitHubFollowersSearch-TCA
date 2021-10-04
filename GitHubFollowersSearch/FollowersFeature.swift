//
//  FollowersFeature.swift
//  GitHubFollowersSearch
//
//  Created by Jason Goodney on 10/2/21.
//

import ComposableArchitecture
import SwiftUI

enum FetchStatus {
    case initial
    case nextPage
    case done
}

struct FollowersState: Equatable {
    var username = ""
    var followers: [Follower] = []
    var fetchStatus: FetchStatus = .initial
    
    var currentPage = 0
    let batchSize = 30
    var lastBatchSize = 0
}

enum FollowersAction: Equatable {
    case retrieve(String)
    case followersResponse(Result<[Follower], GitHubClient.Failure>)
    case onDisappear
}

struct FollowersEnvironment {
    var client: GitHubClient
    var mainQueue: AnySchedulerOf<DispatchQueue>
}

let followersReducer = Reducer<FollowersState, FollowersAction, FollowersEnvironment> {
    state, action, environment in
    
    switch action {
    case let .retrieve(username):
        struct RequestID: Hashable {}
        
        state.username = username
                
        state.currentPage += 1
        
        if state.currentPage > 1 {
            state.fetchStatus = .nextPage
        }
        
        return environment.client
            .searchUser(username, state.currentPage, state.batchSize)
            .receive(on: environment.mainQueue)
            .catchToEffect(FollowersAction.followersResponse)
            .cancellable(id: RequestID(), cancelInFlight: true)
        
    case let .followersResponse(.success(response)):
        state.lastBatchSize = response.count
        state.followers.append(contentsOf: response)
        state.fetchStatus = .done
        return .none

    case .followersResponse(.failure):
        state.followers = []
        state.fetchStatus = .done
        return .none
        
        
    case .onDisappear:
        state.followers = []
        state.currentPage = 0
        state.fetchStatus = .initial
        return .none
    }
}
.debug()

struct FollowersView: View {
    let store: Store<FollowersState, FollowersAction>
    @ObservedObject var viewStore: ViewStore<ViewState, FollowersAction>
    
    @Environment(\.presentationMode) var presentationMode
    
    init(store: Store<FollowersState, FollowersAction>) {
        self.store = store
        self.viewStore = ViewStore(self.store.scope(state: ViewState.init(state:)))
    }
    
    struct ViewState: Equatable {
        let username: String
        let followers: [Follower]
        let fetchStatus: FetchStatus
        let batchSize: Int
        let lastBatchSize: Int
        
        init(state: FollowersState) {
            self.username = state.username
            self.followers = state.followers
            self.fetchStatus = state.fetchStatus
            self.batchSize = state.batchSize
            self.lastBatchSize = state.lastBatchSize
        }
    }
    
    var body: some View {
        ZStack {
            if viewStore.fetchStatus == .initial {
                VStack(spacing: 10) {
                    ProgressView()
                    Text("Loading...")
                }
            } else if !viewStore.followers.isEmpty {
                List {
                    ForEach(viewStore.followers) { follower in
                        Text(follower.username)
                    }
                      
                    if viewStore.lastBatchSize == viewStore.batchSize {
                        HStack {
                            Spacer()
                            if viewStore.fetchStatus == .nextPage {
                                ProgressView()
                            } else {
                                Button("Next Page") {
                                    viewStore.send(.retrieve(viewStore.username))
                                }
                            }
                            Spacer()
                        }
                    }
                }
            } else {
                emptyStateView {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
        .navigationTitle(viewStore.username.lowercased())
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: { viewStore.send(.retrieve(viewStore.username)) })
        .onDisappear(perform: { viewStore.send(.onDisappear) })
    }
    
    private func emptyStateView(_ action: @escaping () -> Void) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "person.2.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 84)
                .foregroundColor(.gray)

            Text("No followers to show")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(Color(uiColor: .darkGray))
            
            Button("Go Back", action: action)
                .padding(10)
                .border(Color.blue)
        }
    }
}

struct FollowersView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NavigationView {
                FollowersView(store: Store(
                    initialState: FollowersState(
                        username: "JasonGoodney",
                        followers: [
                            Follower(id: 1, username: "Tim Cook"),
                            Follower(id: 2, username: "Steve Jobs")
                        ]),
                    reducer: followersReducer,
                    environment: FollowersEnvironment(
                        client: GitHubClient.live,
                        mainQueue: .main)
                ))
            }
            
            NavigationView {
                FollowersView(store: Store(
                    initialState: FollowersState(
                        username: "JasonGoodney"),
                    reducer: followersReducer,
                    environment: FollowersEnvironment(
                        client: GitHubClient.live,
                        mainQueue: .main)
                ))
            }
        }
    }
}
