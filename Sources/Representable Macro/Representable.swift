@_exported import Finite_Macro
/// Fixed homogeneous products, isomorphic to functions from their finite field index.
/// Derives `Index`, `index`, `tabulate`, and a lazy `values` collection in declaration order.
/// Supports a single generic element parameter or concrete homogeneous stored fields.
/// Explicit initializers must assign each coordinate directly without validation or transformation.
@attached(peer, names: suffixed(Index))
@attached(member, names: named(Index), named(index), named(tabulate), named(values))
public macro Representable() = #externalMacro(module: "Representable_Macro_Plugin", type: "Derive")

/// What the macro derives, as a protocol: a product read and built through its finite field index.
/// A derived product conforms by declaring it; nothing beyond the derived members is required.
public protocol Representable {
    associatedtype Index: Swift.CaseIterable & Swift.Hashable
    associatedtype Value
    func index(_ coordinate: Index) -> Value
    static func tabulate(_ value: (Index) -> Value) -> Self
}
