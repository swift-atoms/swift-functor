import Type_Algebra_Syntax
public import SwiftSyntax
import SwiftSyntaxBuilder
public enum Derivation {
    public static func members(of declaration: some DeclGroupSyntax) throws -> [DeclSyntax] {
        guard let structure = declaration.as(StructDeclSyntax.self) else { throw AlgebraDiagnostic("@Invariant requires a struct") }
        let shape = try GenericProduct(structure, arity: 1)
        let parameter = shape.parameters[0]
        let arguments = try shape.properties.fields.enumerated().map { index, field in
            field.name + ": " + (try MappingExpression.apply(shape.fields[index], to: "self.\(field.name)",
                forward: [parameter: "forward"], backward: [parameter: "backward"]))
        }.joined(separator: ", ")
        return [DeclSyntax(stringLiteral: """
            \(shape.access)func imap<Mapped>(_ forward: @escaping (\(parameter)) -> Mapped,
                _ backward: @escaping (Mapped) -> \(parameter)) -> \(structure.name.text)<Mapped> {
                \(structure.name.text)<Mapped>(\(arguments))
            }
            """)]
    }
}
