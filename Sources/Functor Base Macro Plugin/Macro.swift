import Functor_Base_Macro_Core
import SwiftSyntax
import SwiftSyntaxMacros

public struct Macro: MemberMacro {}

extension Macro {
    public static func expansion(
        of _: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo _: [TypeSyntax],
        in _: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let declaration = declaration.as(EnumDeclSyntax.self) else {
            throw MacroExpansionErrorMessage(
                "@FunctorBase applies to an enum declaration only."
            )
        }
        return Derivation.base(of: declaration)
    }
}
