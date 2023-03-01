public struct PrimeModalState {
    public var count: Int
    public var favoritePrimes: [Int]

    public init(count: Int, favoritePrimes: [Int]) {
        self.count = count
        self.favoritePrimes = favoritePrimes
    }
}

public enum PrimeModalAction {
    case saveFavoritePrimeTapped
    case removeFavoritePrimeTapped
}

public func primeModalReducer(state: inout PrimeModalState, action: PrimeModalAction) -> Void {
    switch action {
    case .saveFavoritePrimeTapped:
        state.favoritePrimes.append(state.count)

    case .removeFavoritePrimeTapped:
        state.favoritePrimes.removeAll(where: { $0 == state.count })
    }
}
