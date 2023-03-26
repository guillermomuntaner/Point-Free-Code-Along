import Foundation
import SwiftUI
import ComposableArchitecture

public enum FavoritePrimesAction {
    case removeFavoritePrimes(IndexSet)
}

public func favoritePrimesReducer(state: inout [Int], action: FavoritePrimesAction) -> Void {
    switch action {
    case let .removeFavoritePrimes(indexSet):
        for index in indexSet {
            state.remove(at: index)
        }
    }
}

public struct FavoritePrimes: View {
    @ObservedObject var store: Store<[Int], FavoritePrimesAction>

    public init(store: Store<[Int], FavoritePrimesAction>) {
        self.store = store
    }

    public var body: some View {
        List {
            ForEach(self.store.value) { prime in
                Text("\(prime)")
            }
            .onDelete { indexSet in
                self.store.send(.removeFavoritePrimes(indexSet))
            }
        }
        .navigationBarTitle(Text("Favorite Primes"))
    }
}

extension Int: Identifiable {
    public var id: Int { return self }
}
