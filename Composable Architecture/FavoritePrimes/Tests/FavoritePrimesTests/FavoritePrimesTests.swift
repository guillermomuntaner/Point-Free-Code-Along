import XCTest
@testable import FavoritePrimes

final class FavoritePrimesTests: XCTestCase {
    func testRemoveFavoritePrimes() throws {
        var favoritePrimes = [0, 1, 2]
        favoritePrimesReducer(state: &favoritePrimes, action: .removeFavoritePrimes([1]))
        XCTAssertEqual(favoritePrimes, [0, 2])
    }
}
