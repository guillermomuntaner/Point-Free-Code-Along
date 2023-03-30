import SwiftUI
import ComposableArchitecture
import PrimeModal

public enum CounterAction {
    case decreaseTapped
    case increaseTapped
}

public func counterReducer(state: inout Int, action: CounterAction) {
    switch action {
    case .decreaseTapped:
        state = max(0, state - 1)
    case .increaseTapped:
        state += 1
    }
}

public let counterViewReducer: (inout CounterViewState, CounterViewAction) -> Void = combine(
  pullback(counterReducer, value: \CounterViewState.count, action: \.counter),
  pullback(primeModalReducer, value: \.primeModalState, action: \.primeModal)
)

public struct CounterViewState {
    public var count: Int
    public var favoritePrimes: [Int]

    public init(count: Int, favoritePrimes: [Int]) {
        self.count = count
        self.favoritePrimes = favoritePrimes
    }

    var primeModalState: PrimeModalState {
        get {
            return PrimeModalState(count: count, favoritePrimes: favoritePrimes)
        }
        set {
            self = CounterViewState(count: newValue.count, favoritePrimes: newValue.favoritePrimes)
        }
    }
}

public enum CounterViewAction {
    case counter(CounterAction)
    case primeModal(PrimeModalAction)

    var counter: CounterAction? {
        get {
            guard case let .counter(value) = self else { return nil }
            return value
        }
        set {
            guard case .counter = self, let newValue = newValue else { return }
            self = .counter(newValue)
        }
    }
    
    var primeModal: PrimeModalAction? {
        get {
            guard case let .primeModal(value) = self else { return nil }
            return value
        }
        set {
            guard case .primeModal = self, let newValue = newValue else { return }
            self = .primeModal(newValue)
        }
    }
}

public struct CounterView: View {
    @ObservedObject var store: Store<CounterViewState, CounterViewAction>
    @State var isPrimeModalShown: Bool = false
    @State var alertNthPrime: Int?
    @State var isNthPrimeButtonDisabled = false
    
    public init(store: Store<CounterViewState, CounterViewAction>, isPrimeModalShown: Bool = false, alertNthPrime: Int? = nil, isNthPrimeButtonDisabled: Bool = false) {
        self.store = store
        self.isPrimeModalShown = isPrimeModalShown
        self.alertNthPrime = alertNthPrime
        self.isNthPrimeButtonDisabled = isNthPrimeButtonDisabled
    }
    
    public var body: some View {
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
            IsPrimeModalView(store: store.view(
                value: { PrimeModalState(count: $0.count, favoritePrimes: $0.favoritePrimes) },
                action: { .primeModal($0) }
            ))
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

private func ordinal(_ n: Int) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .ordinal
    return formatter.string(for: n) ?? ""
}

extension Int: Identifiable {
    public var id: Int { return self }
}
