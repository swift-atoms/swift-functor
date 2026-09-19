/// Bidirectional action on supported mixed-variance shapes. Inverse arrows are required when transporting invariants.
@attached(member, names: named(imap))
public macro Invariant() = #externalMacro(module: "Invariant_Macro_Plugin", type: "Derive")
