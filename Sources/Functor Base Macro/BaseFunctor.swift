@_exported import Functor_Macro

@attached(member, names: arbitrary)
public macro FunctorBase() = #externalMacro(
    module: "Functor_Base_Macro_Plugin",
    type: "Macro"
)
