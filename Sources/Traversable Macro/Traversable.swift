@_exported import Traversal_Support
@attached(member, names: named(traverseOptional), named(traverseResult), named(traverseSequential))
public macro Traversable() = #externalMacro(module: "Traversable_Macro_Plugin", type: "Derive")
