@_exported import Traversal_Support
/// Finite polynomial traversal specialized to Optional, Result, and sequential async effects.
/// This is not quantification over arbitrary higher-kinded applicatives.
@attached(member, names: named(traverseOptional), named(traverseResult), named(traverseSequential))
public macro Traversable() = #externalMacro(module: "Traversable_Macro_Plugin", type: "Derive")
