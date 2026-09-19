import Cardinal
import Algebra_Consumer_Fixtures
import Testing
@Test func derivedAPIsCrossThePublicBoundary() async throws {
    let value = Coordinates<Int>.tabulate { $0 == .x ? 2 : 3 }
    let coordinate: Coordinates<String>.Index = Coordinates<Int>.Index.x
    #expect(value.map(String.init).index(coordinate) == "2")
    #expect(CoordinatesIndex.count.rawValue == 2)
    #expect(value.traverseOptional { $0 > 0 ? String($0) : nil }?.index(.y) == "3")
    let sequential = await value.traverseSequential { String($0) }
    #expect(sequential.index(.x) == "2")
}
