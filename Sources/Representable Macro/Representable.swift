@_exported import Finite_Macro
/// Fixed homogeneous products, isomorphic to functions from their finite field index.
@attached(peer, names: suffixed(Index))
@attached(member, names: named(Index), named(index), named(tabulate))
public macro Representable() = #externalMacro(module: "Representable_Macro_Plugin", type: "Derive")
