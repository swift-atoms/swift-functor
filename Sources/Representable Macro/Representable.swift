@_exported import Finite_Macro
/// Fixed homogeneous products, isomorphic to functions from their finite field index.
/// Derives `Index`, `index`, `tabulate`, and a lazy `values` collection in declaration order.
/// Supports a single generic element parameter or concrete homogeneous stored fields.
/// Explicit initializers must assign each coordinate directly without validation or transformation.
@attached(peer, names: suffixed(Index))
@attached(member, names: named(Index), named(index), named(tabulate), named(values))
public macro Representable() = #externalMacro(module: "Representable_Macro_Plugin", type: "Derive")
