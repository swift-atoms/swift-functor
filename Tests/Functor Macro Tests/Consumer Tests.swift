import Functor_Macro
import Testing

@Functor
private struct Box<Element>: Equatable where Element: Equatable {
    var value: Element
}

@Test
func `derived map obeys identity and composition`() {
    let box = Box(value: 21)

    #expect(box.map { $0 } == box)
    #expect(box.map { $0 * 2 }.map(String.init) == box.map { String($0 * 2) })
}
