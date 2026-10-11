@_exported import Finite_Macro
@attached(peer, names: suffixed(Index))
@attached(member, names: named(Index), named(index), named(tabulate), named(values))
public macro Representable() = #externalMacro(module: "Representable_Macro_Plugin", type: "Derive")

public protocol Representable {
    associatedtype Index: Swift::CaseIterable & Swift::Hashable
    associatedtype Value
    func index(_ coordinate: Index) -> Value
    static func tabulate(_ value: (Index) -> Value) -> Self
}
