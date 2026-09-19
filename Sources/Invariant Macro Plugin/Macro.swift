import SwiftSyntax
import SwiftSyntaxMacros
import Invariant_Macro_Core
struct Derive: MemberMacro {
    static func expansion(of node: AttributeSyntax, providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax], in context: some MacroExpansionContext) throws -> [DeclSyntax] {
        try Derivation.members(of: declaration)
    }
}
