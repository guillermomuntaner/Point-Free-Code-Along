import SwiftUI
import PlaygroundSupport

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

struct WolframAlphaResult: Decodable {
    let queryresult: QueryResult

    struct QueryResult: Decodable {
        let pods: [Pod]

        struct Pod: Decodable {
            let primary: Bool?
            let subpods: [SubPod]

            struct SubPod: Decodable {
                let plaintext: String
            }
        }
    }
}

func wolframAlpha(query: String, callback: @escaping (WolframAlphaResult?) -> Void) -> Void {
    var components = URLComponents(string: "https://api.wolframalpha.com/v2/query")!
    components.queryItems = [
        URLQueryItem(name: "input", value: query),
        URLQueryItem(name: "format", value: "plaintext"),
        URLQueryItem(name: "output", value: "JSON"),
        URLQueryItem(name: "appid", value: wolframAlphaApiKey),
    ]

    URLSession.shared.dataTask(with: components.url(relativeTo: nil)!) { data, response, error in
        callback(
            data
                .flatMap { try? JSONDecoder().decode(WolframAlphaResult.self, from: $0) }
        )
    }
    .resume()
}

func nthPrime(_ n: Int, callback: @escaping (Int?) -> Void) -> Void {
    wolframAlpha(query: "prime \(n)") { result in
        callback(
            result
                .flatMap {
                    $0.queryresult
                        .pods
                        .first(where: { $0.primary == .some(true) })?
                        .subpods
                        .first?
                        .plaintext
                }
                .flatMap(Int.init)
        )
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

class AppState: ObservableObject {
    @Published var count = 0
    @Published var favoritePrimes: [Int] = []
    @Published var activityFeed: [Activity] = []
    @Published var loggedInUser: User?
}

extension AppState {
    func addFavoritePrime() {
        self.favoritePrimes.append(self.count)
        self.activityFeed.append(Activity(timestamp: Date(), type: .addedFavoritePrime(self.count)))
    }

    func removeFavoritePrime(_ prime: Int) {
        self.favoritePrimes.removeAll(where: { $0 == prime })
        self.activityFeed.append(Activity(timestamp: Date(), type: .removedFavoritePrime(prime)))
    }

    func removeFavoritePrime() {
        self.removeFavoritePrime(self.count)
    }

    func removeFavoritePrimes(at indexSet: IndexSet) {
        for index in indexSet {
            self.removeFavoritePrime(self.favoritePrimes[index])
        }
    }
}

class FavoritePrimesState: ObservableObject {

  private var state: AppState

  init(state: AppState) {
    self.state = state
  }

  var favoritePrimes: [Int] {
    get { self.state.favoritePrimes }
    set {
        objectWillChange.send()
        self.state.favoritePrimes = newValue
    }
  }

  var activityFeed: [Activity] {
    get { self.state.activityFeed }
    set {
        objectWillChange.send()
        self.state.activityFeed = newValue
    }
  }
}

extension Int: Identifiable {
    public var id: Int { return self }
}

// MARK: - View

struct ContentView: View {
    @ObservedObject var state: AppState

    var body: some View {
        NavigationView {
            List {
                NavigationLink(destination: CounterView(state: self.state)) {
                    Text("Counter demo")
                }
                NavigationLink(destination: FavoritePrimes(state: FavoritePrimesState(state: self.state))) {
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
    @ObservedObject var state: AppState
    @State var isPrimeModalShown: Bool = false
    @State var alertNthPrime: Int?
    @State var isNthPrimeButtonDisabled = false

    var body: some View {
        VStack {
            HStack {
                Button(action: { self.state.count = max(0, self.state.count - 1) }) {
                    Text("-")
                }
                Text("\(self.state.count)")
                Button(action: { self.state.count += 1 }) {
                    Text("+")
                }
            }
            Button(action: { self.isPrimeModalShown = true }) {
                Text("Is this prime?")
            }
            Button(action: self.nthPrimeButtonAction) {
                Text("What is the \(ordinal(self.state.count)) prime?")
            }
            .disabled(self.isNthPrimeButtonDisabled)
        }
        .font(.title)
        .navigationTitle("Counter demo")
        .sheet(isPresented: self.$isPrimeModalShown) {
            IsPrimeModalView(state: state)
        }
        .alert(item: self.$alertNthPrime) { n in
            Alert(
                title: Text("The \(ordinal(self.state.count)) prime is \(n)"),
                dismissButton: Alert.Button.default(Text("OK"))
            )
        }
    }

    func nthPrimeButtonAction() {
        self.isNthPrimeButtonDisabled = true
        nthPrime(self.state.count) { prime in
            self.alertNthPrime = prime
            self.isNthPrimeButtonDisabled = false
        }
    }
}

struct FavoritePrimes: View {
    @ObservedObject var state: FavoritePrimesState

    var body: some View {
        List {
            ForEach(self.state.favoritePrimes) { prime in
                Text("\(prime)")
            }
            .onDelete { indexSet in
                for index in indexSet {
                    self.state.favoritePrimes.remove(at: index)
                    let prime = self.state.favoritePrimes[index]
                    self.state.activityFeed.append(Activity(timestamp: Date(), type: .removedFavoritePrime(prime)))
                }
            }
        }
        .navigationBarTitle(Text("Favorite Primes"))
    }
}

struct IsPrimeModalView: View {
    @ObservedObject var state: AppState

    var body: some View {
        VStack {
            if isPrime(self.state.count) {
                Text("\(self.state.count) is prime 🎉")
                if self.state.favoritePrimes.contains(self.state.count) {
                    Button(action: {
                        self.state.favoritePrimes.removeAll(where: { $0 == self.state.count })
                        self.state.activityFeed.append(.init(timestamp: Date(), type: .removedFavoritePrime(self.state.count)))

                    }) {
                        Text("Remove from favorite primes")
                    }
                } else {
                    Button(action: {
                        self.state.favoritePrimes.append(self.state.count)
                        self.state.activityFeed.append(.init(timestamp: Date(), type: .addedFavoritePrime(self.state.count)))
                    }) {
                        Text("Save to favorite primes")
                    }
                }
            } else {
                Text("\(self.state.count) is not prime :(")
            }
        }
    }
}

let view = ContentView(state: AppState())

PlaygroundPage.current.setLiveView(view)
