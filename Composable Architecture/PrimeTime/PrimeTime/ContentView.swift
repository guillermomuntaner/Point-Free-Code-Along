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
import PrimeModal

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

private func ordinal(_ n: Int) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .ordinal
    return formatter.string(for: n) ?? ""
}

private func isPrime (_ p: Int) -> Bool {
    if p <= 1 { return false }
    if p <= 3 { return true }
    for i in 2...Int(sqrtf(Float(p))) {
        if p % i == 0 { return false }
    }
    return true
}

struct AppState {
    var count = 0
    var favoritePrimes: [Int] = []
    var activityFeed: [Activity] = []
    var loggedInUser: User?
}

extension AppState {
    var primeModel: PrimeModalState {
        get {
            PrimeModalState(
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
    case counter(CounterAction)
    case primeModal(PrimeModalAction)
    case favoritePrimes(FavoritePrimesAction)

    var counter: CounterAction? {
        get {
            guard case let .counter(value) = self else { return nil }
            return value
        }
    }

    var primeModal: PrimeModalAction? {
        get {
            guard case let .primeModal(value) = self else { return nil }
            return value
        }
    }

    var favoritePrimes: FavoritePrimesAction? {
        get {
            guard case let .favoritePrimes(value) = self else { return nil }
            return value
        }
    }
}

func activityFeed(
    _ reducer: @escaping (inout AppState, AppAction) -> Void
) -> (inout AppState, AppAction) -> Void {
    return { state, action in
        switch action {
        case .counter:
            break

        case .primeModal(.saveFavoritePrimeTapped):
            state.activityFeed.append(.init(timestamp: Date(), type: .addedFavoritePrime(state.count)))

        case .primeModal(.removeFavoritePrimeTapped):
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
            pullback(counterReducer, value: \.count, action: \.counter),
            pullback(primeModalReducer, value: \.primeModel, action: \.primeModal),
            pullback(favoritePrimesReducer, value: \.favoritePrimes, action: \.favoritePrimes)
        )
    )
)

extension Int: Identifiable {
    public var id: Int { return self }
}

// MARK: - View

struct ContentView: View {
    @ObservedObject var store: Store<AppState, AppAction>

    var body: some View {
        NavigationView {
            List {
                NavigationLink(destination: CounterView(store: self.store)) {
                    Text("Counter demo")
                }
                NavigationLink(destination: FavoritePrimes(store: self.store)) {
                    Text("Favorite primes")
                }
            }
            .navigationTitle("State management")
        }
        // iPhone 14 size
        .frame(width: 390, height: 844)
    }
}

struct CounterView: View {
    @ObservedObject var store: Store<AppState, AppAction>
    @State var isPrimeModalShown: Bool = false
    @State var alertNthPrime: Int?
    @State var isNthPrimeButtonDisabled = false

    var body: some View {
        VStack {
            HStack {
                Button("-") {
                    self.store.send(.counter(.decreaseTapped))
                }
                Text("\(self.store.value.count)")
                Button("+") {
                    self.store.send(.counter(.increaseTapped))
                }
            }
            Button(action: { self.isPrimeModalShown = true }) {
                Text("Is this prime?")
            }
            Button(action: self.nthPrimeButtonAction) {
                Text("What is the \(ordinal(self.store.value.count)) prime?")
            }
            .disabled(self.isNthPrimeButtonDisabled)
        }
        .font(.title)
        .navigationTitle("Counter demo")
        .sheet(isPresented: self.$isPrimeModalShown) {
            IsPrimeModalView(store: store)
        }
        .alert(item: self.$alertNthPrime) { n in
            Alert(
                title: Text("The \(ordinal(self.store.value.count)) prime is \(n)"),
                dismissButton: Alert.Button.default(Text("OK"))
            )
        }
    }

    func nthPrimeButtonAction() {
        self.isNthPrimeButtonDisabled = true
        nthPrime(self.store.value.count) { prime in
            self.alertNthPrime = prime
            self.isNthPrimeButtonDisabled = false
        }
    }
}

struct FavoritePrimes: View {
    @ObservedObject var store: Store<AppState, AppAction>

    var body: some View {
        List {
            ForEach(self.store.value.favoritePrimes) { prime in
                Text("\(prime)")
            }
            .onDelete { indexSet in
                self.store.send(.favoritePrimes(.removeFavoritePrimes(indexSet)))
            }
        }
        .navigationBarTitle(Text("Favorite Primes"))
    }
}

struct IsPrimeModalView: View {
    @ObservedObject var store: Store<AppState, AppAction>

    var body: some View {
        VStack {
            if isPrime(self.store.value.count) {
                Text("\(self.store.value.count) is prime 🎉")
                if self.store.value.favoritePrimes.contains(self.store.value.count) {
                    Button(action: {
                        self.store.send(.primeModal(.removeFavoritePrimeTapped))
                    }) {
                        Text("Remove from favorite primes")
                    }
                } else {
                    Button(action: {
                        self.store.send(.primeModal(.saveFavoritePrimeTapped))
                    }) {
                        Text("Save to favorite primes")
                    }
                }
            } else {
                Text("\(self.store.value.count) is not prime :(")
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(store: Store(initialValue: AppState(), reducer: appReducer))

    }
}
