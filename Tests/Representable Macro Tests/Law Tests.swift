import Representable_Macro
import Functor_Macro
import Testing
@Representable @Functor private struct Triple<A> { let first: A; let second: A; let third: A }
@Representable private struct Empty<A> {}
@Test func representableRoundTripsBothDirectionsWithOneIndexType() {
    let source = Triple(first: 2, second: 3, third: 5)
    let reconstructed = Triple<Int>.tabulate(source.index)
    for index in TripleIndex.allCases { #expect(reconstructed.index(index) == source.index(index)) }
    let function: (TripleIndex) -> String = { String($0.ordinal.rawValue) }
    let table = Triple<String>.tabulate(function)
    for index in TripleIndex.allCases { #expect(table.index(index) == function(index)) }
    let index: Triple<String>.Index = Triple<Int>.Index.first
    #expect(source.map(String.init).index(index) == "2")
    let _: Empty<Int> = .tabulate(Empty<Int>().index)
    #expect(EmptyIndex.count.rawValue == 0)
}

@Representable private struct Answers {
    let first: Bool?
    let second: Bool?

    init(_ first: Bool?, answer second: Bool?) {
        self.first = first
        self.second = second
    }
}

@Test func concreteRepresentationPreservesCoordinatesAndConstructionLabels() {
    let input = Answers(nil, answer: true)
    #expect(Array(input.values) == [nil, true])
    #expect(input.values.contains(true))
    #expect(!input.values.allSatisfy { $0 == false })
    #expect(Array(Answers.tabulate(input.index).values) == Array(input.values))
    #expect(Array(Triple(first: 2, second: 3, third: 5).values) == [2, 3, 5])
    #expect(Empty<Int>().values.isEmpty)
}
