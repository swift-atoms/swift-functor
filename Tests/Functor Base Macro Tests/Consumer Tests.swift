import Functor_Base_Macro
import Testing

@FunctorBase
private indirect enum Natural {
    case zero
    case successor(Natural)
}

@Test
func `derived base functor maps recursive positions`() {
    let layer = Natural.Base<Int>.successor(21).map { $0 * 2 }

    guard case .successor(42) = layer else {
        Issue.record("Expected mapped successor")
        return
    }
}
