import SwiftSyntax
import SwiftSyntaxMacros
import Representable_Macro_Core
struct Derive: MemberMacro, PeerMacro {
    static func expansion(of node: AttributeSyntax, providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax], in context: some MacroExpansionContext) throws -> [DeclSyntax] {
        try Derivation.members(of: declaration)
    }
    static func expansion(of node: AttributeSyntax, providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext) throws -> [DeclSyntax] {
        try Derivation.index(of: declaration)
    }
}
