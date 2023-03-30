//
//  ContentView.swift
//  PrimeTime
//
//  Created by Guillermo Muntaner on 01.03.23.
//
import SwiftUI
import ComposableArchitecture
import FavoritePrimes
import Counter

// MARK: - Model

struct User {
    let id: Int
    let name: String
    let bio: String
}

struct Activity {
    let timestamp: Date
    let type: ActivityType

    enum ActivityType {
        case addedFavoritePrime(Int)
        case removedFavoritePrime(Int)
    }
}

struct AppState {
    var count = 0
    var favoritePrimes: [Int] = []
    var activityFeed: [Activity] = []
    var loggedInUser: User?
}


extension AppState {
    var counterView: CounterViewState {
        get {
            CounterViewState(
                count: self.count,
                favoritePrimes: self.favoritePrimes
            )
        }
        set {
            self.count = newValue.count
            self.favoritePrimes = newValue.favoritePrimes
        }
    }
}

enum AppAction {
    case counterView(CounterViewAction)
    case favoritePrimes(FavoritePrimesAction)

    var favoritePrimes: FavoritePrimesAction? {
        get {
            guard case let .favoritePrimes(value) = self else { return nil }
            return value
        }
        set {
            guard case .favoritePrimes = self, let newValue = newValue else { return }
            self = .favoritePrimes(newValue)
        }
    }

    var counterView: CounterViewAction? {
        get {
            guard case let .counterView(value) = self else { return nil }
            return value
        }
        set {
            guard case .counterView = self, let newValue = newValue else { return }
            self = .counterView(newValue)
        }
    }
}

func activityFeed(
    _ reducer: @escaping (inout AppState, AppAction) -> Void
) -> (inout AppState, AppAction) -> Void {
    return { state, action in
        switch action {
        case .counterView(.counter):
            break

        case .counterView(.primeModal(.saveFavoritePrimeTapped)):
            state.activityFeed.append(.init(timestamp: Date(), type: .addedFavoritePrime(state.count)))

        case .counterView(.primeModal(.removeFavoritePrimeTapped)):
            state.activityFeed.append(.init(timestamp: Date(), type: .removedFavoritePrime(state.count)))

        case let .favoritePrimes(.removeFavoritePrimes(indexSet)):
            for index in indexSet {
                state.activityFeed.append(.init(timestamp: Date(), type: .removedFavoritePrime(state.favoritePrimes[index])))
            }
        }

        reducer(&state, action)
    }
}

let appReducer: (inout AppState, AppAction) -> Void = logging(
    activityFeed(
        combine(
            pullback(counterViewReducer, value: \.counterView, action: \.counterView),
            pullback(favoritePrimesReducer, value: \.favoritePrimes, action: \.favoritePrimes)
        )
    )
)

// MARK: - View

struct ContentView: View {
    @ObservedObject var store: Store<AppState, AppAction>

    var body: some View {
        NavigationView {
            List {
                NavigationLink(
                    destination: CounterView(store: self.store.view(
                        value: { $0.counterView },
                        action: { .counterView($0) }
                    ))
                ) {
                    Text("Counter demo")
                }
                NavigationLink(
                    destination: FavoritePrimes(store: self.store.view(
                        value: { $0.favoritePrimes },
                        action: { .favoritePrimes($0) }
                    ))
                ) {
                    Text("Favorite primes")
                }
            }
            .navigationTitle("State management")
        }
        // iPhone 14 size
        .frame(width: 390, height: 844)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(store: Store(initialValue: AppState(), reducer: appReducer))

    }
}
