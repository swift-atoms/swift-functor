@attached(member, names: arbitrary)
public macro Functor() = #externalMacro(
    module: "Functor_Macro_Plugin",
    type: "Macro"
)
