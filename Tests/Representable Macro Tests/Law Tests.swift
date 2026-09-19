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
