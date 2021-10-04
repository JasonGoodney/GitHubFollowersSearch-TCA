//
//  GitHubClient.swift
//  GitHubFollowersSearch
//
//  Created by Jason Goodney on 10/2/21.
//

import ComposableArchitecture

struct Follower: Decodable, Equatable, Identifiable {
    let id: Int
    let username: String
}

extension Follower {
    private enum CodingKeys: String, CodingKey {
        case id
        case username = "login"
    }
}

struct GitHubClient {
    var searchUser: (String, Int, Int) -> Effect<[Follower], Failure>
    
    struct Failure: Error, Equatable {}
}

extension GitHubClient {
    static let live = GitHubClient(
        searchUser: { username, page, perPage in
            let url = URL(string: "https://api.github.com/users/\(username)/followers?per_page=\(perPage)&page=\(page)")!
            
            return URLSession.shared.dataTaskPublisher(for: url)
                .map { data, _ in data }
                .decode(type: [Follower].self, decoder: jsonDecoder)
                .mapError { _ in Failure() }
                .eraseToEffect()
        })
}

// MARK: - Private helpers
private let jsonDecoder: JSONDecoder = {
    let d = JSONDecoder()
    return d
}()
