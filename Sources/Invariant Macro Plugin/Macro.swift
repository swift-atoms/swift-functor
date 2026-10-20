import Invariant_Macro_Core
import SwiftSyntax
import SwiftSyntaxMacros

struct Derive: MemberMacro {}

extension Derive {
    static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        try Derivation.members(of: declaration)
    }
}
