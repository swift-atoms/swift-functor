import Traversable_Macro
import Functor_Macro
import Foldable_Macro
import Testing
@Functor @Foldable @Traversable
private struct Batch<A> { let nested: [A?]; let tail: (A, A?); let label: String }
@Traversable private enum Choice<A> { case empty; case values([A?]) }
private enum Failure: Error { case stop }
@Test func optionalTraversalPreservesAbsenceAndStopsOnFailure() {
    let input = Batch(nested: [1, nil, 2], tail: (3, nil), label: "kept")
    var visits: [Int] = []
    let result = input.traverseOptional { value -> String? in visits.append(value); return String(value) }
    #expect(visits.elementsEqual([1, 2, 3]))
    #expect(result?.nested.elementsEqual(["1", nil, "2"]) == true)
    #expect(result?.tail.0 == "3")
    #expect(result?.tail.1 == nil)
    #expect(result?.label == "kept")
    visits = []
    #expect(input.traverseOptional { value -> Int? in visits.append(value); return value == 2 ? nil : value } == nil)
    #expect(visits.elementsEqual([1, 2]))
    let empty: Choice<String>? = Choice<Int>.empty.traverseOptional(String.init)
    if case .some(.empty) = empty {} else { Issue.record("Empty shape must succeed without a visit") }
}
@Test func resultTraversalAgreesWithMapAndFold() throws {
    let input = Batch(nested: [1, nil, 2], tail: (3, 4), label: "kept")
    let traversed = try input.traverseResult { Result<String, Failure>.success(String($0)) }.get()
    let mapped = input.map(String.init)
    #expect(traversed.nested.elementsEqual(mapped.nested))
    #expect(traversed.tail.0 == mapped.tail.0 && traversed.tail.1 == mapped.tail.1)
    #expect(input.fold([], { $0 + [$1] }).elementsEqual([1, 2, 3, 4]))
    let sum = Algebra.Monoid<Int>(identity: 0, combining: +)
    #expect(input.foldMap(sum, { $0 }) == 10)
    var visits: [Int] = []
    let failure = input.traverseResult { value -> Result<Int, Failure> in
        visits.append(value); return value == 2 ? .failure(.stop) : .success(value)
    }
    if case .failure(.stop) = failure {} else { Issue.record("Expected selected failure") }
    #expect(visits.elementsEqual([1, 2]))
}
@Test func optionalTraversalIdentityAndComposition() {
    let input = Batch(nested: [1, nil, 2], tail: (3, nil), label: "x")
    let identity = input.traverseOptional { Optional.some($0) }
    #expect(identity?.nested.elementsEqual(input.nested) == true)
    let twice = input.traverseOptional { Optional.some($0 + 1) }?.traverseOptional { Optional.some(String($0)) }
    let once = input.traverseOptional { Optional.some(String($0 + 1)) }
    #expect(twice?.nested.elementsEqual(once!.nested) == true)
    #expect(twice?.tail.0 == once?.tail.0)
}
@Test func sequentialTraversalRetainsOrderAndStopsOnThrow() async {
    let input = Batch(nested: [1, nil, 2], tail: (3, nil), label: "x")
    var visits: [Int] = []
    do {
        _ = try await input.traverseSequential { value in
            visits.append(value)
            if value == 2 { throw Failure.stop }
            return String(value)
        }
        Issue.record("Expected failure")
    } catch { #expect(visits.elementsEqual([1, 2])) }
}
