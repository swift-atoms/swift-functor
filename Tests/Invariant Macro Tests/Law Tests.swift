import Invariant_Macro
import Algebra_Test_Support
import Testing
@Invariant private struct Endomorphism<A> { let run: (A) -> A }
@Test func invariantIdentityAndCompositionHoldObservationally() {
    let value = Endomorphism<Int>(run: { $0 * 2 })
    let identity = value.imap({ $0 }, { $0 })
    #expect(Algebra.Law.Equation.check("imap identity", over: [-2, 0, 3], lhs: identity.run, rhs: value.run) == nil)
    let successive = value.imap({ $0 + 1 }, { $0 - 1 }).imap({ $0 * 3 }, { $0 / 3 })
    let composed = value.imap({ ($0 + 1) * 3 }, { $0 / 3 - 1 })
    #expect(Algebra.Law.Equation.check("imap composition", over: [-6, 0, 9], lhs: successive.run, rhs: composed.run) == nil)
    let strings = value.imap(String.init, { Int($0)! })
    #expect(strings.run("21") == "42")
}
