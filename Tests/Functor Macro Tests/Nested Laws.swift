import Functor_Macro
import Algebra_Test_Support
import Testing
@Functor private struct Nested<A> { let values: [A?]; let metadata: Int }
extension Nested: Equatable where A: Equatable {}
@Functor private enum Choice<A> { case empty; case values([A?]) }
extension Choice: Equatable where A: Equatable {}
@Functor private struct Reader<A> { let read: (Int) -> A }
@Test func nestedFunctorIdentityAndComposition() {
    let samples = [Nested<Int>(values: [], metadata: 0), Nested(values: [nil, 1, 2], metadata: 7)]
    #expect(Algebra.Law.Equation.check("map identity", over: samples, lhs: { $0.map { $0 } }, rhs: { $0 }) == nil)
    #expect(Algebra.Law.Equation.check("map composition", over: samples, lhs: { $0.map { $0 + 1 }.map(String.init) }, rhs: { $0.map { String($0 + 1) } }) == nil)
    #expect(Choice<Int>.values([nil, 1]).map(String.init) == .values([nil, "1"]))
    let reader = Reader<Int>(read: { $0 + 1 }).map(String.init)
    #expect(reader.read(2) == "3")
}
