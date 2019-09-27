import XCTest
import SwiftCheck
@testable import functional_swift

func multiplyBy2(_ n: Int) -> Int {
    return n * 2
}

func add1(_ n: Int) -> Int {
    return n + 1
}

func id(_ n: Int) -> Int {
    return n
}

final class PropertyTests: XCTestCase {
    func testFunctorComposition() {
        property("fmap (f . g) == (fmap f . fmap g)") <- forAll { (xs : [Int]) in
            return
                xs.map(multiplyBy2).map(add1) == xs.map({ add1(multiplyBy2($0)) })
        }
    }

    func testPreservesIdentity() {
        property("fmap id = id") <- forAll { (xs : [Int]) in
            return xs.map(id) == xs
        }
    }

    static var allTests = [
        ("testFunctorComposition", testFunctorComposition),
    ]
}
