import Foundation

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
