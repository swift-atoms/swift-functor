import Type_Algebra_Syntax
public import SwiftSyntax

public enum Derivation {
    public static func members(of declaration: some DeclGroupSyntax) throws -> [DeclSyntax] {
        guard let structure = declaration.as(StructDeclSyntax.self) else { throw Type.Failure("@Invariant requires a struct") }
        return try Type.Syntax.Mapping.members(of: structure, method: "imap",
            parameters: [.init("Mapped", forward: "forward", backward: "backward")])
    }
}
