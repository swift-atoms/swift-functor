import Functor_Macro
import Testing

@Functor
private struct Box<Element> {
    var value: Element
}

@Test
func `derived map obeys identity and composition`() {
    let box = Box(value: 21)

    #expect(box.map { $0 } == box)
    #expect(box.map { $0 * 2 }.map(String.init) == box.map { String($0 * 2) })
}

extension Box: Equatable where Element: Equatable {}

@Functor
private struct WithUnstoredMembers<Element> {
    var value: Element
    static var label: String { "box" }
    var projection: Element { value }
}
@Test func mappingIgnoresStaticAndComputedMembers() {
    #expect(WithUnstoredMembers(value: 4).map(String.init).value == "4")
}
