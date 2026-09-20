import Type_Algebra_Syntax
public import SwiftSyntax
import SwiftSyntaxBuilder
public enum Derivation {
    public static func members(of declaration: some DeclGroupSyntax) throws -> [DeclSyntax] {
        guard let structure = declaration.as(StructDeclSyntax.self) else { throw Type.Failure("@Representable requires a fixed homogeneous product") }
        let shape = try Type.Syntax.Product(structure, arity: 1)
        let parameter = shape.parameters[0]
        guard shape.properties.fields.allSatisfy({ $0.type.trimmedDescription == parameter }) else {
            throw Type.Failure("@Representable requires every stored coordinate to be the parameter itself; metadata and variable shapes are not representable by this derivation")
        }
        let fields = shape.properties.fields
        let arms = fields.map { "case .\($0.name): return self.\($0.name)" }.joined(separator: "\n")
        let arguments = fields.map { "\($0.name): value(.\($0.name))" }.joined(separator: ", ")
        return [DeclSyntax(stringLiteral: """
            \(shape.access)typealias Index = \(structure.name.text)Index
            """), DeclSyntax(stringLiteral: """
            \(shape.access)func index(_ coordinate: Index) -> \(parameter) {
                \(fields.isEmpty ? "" : "switch coordinate { \(arms) }")
            }
            """), DeclSyntax(stringLiteral: """
            \(shape.access)static func tabulate(_ value: (Index) -> \(parameter)) -> Self {
                Self(\(arguments))
            }
            """)]
    }
    public static func index(of declaration: some DeclSyntaxProtocol) throws -> [DeclSyntax] {
        guard let structure = declaration.as(StructDeclSyntax.self) else { throw Type.Failure("@Representable requires a struct") }
        let shape = try Type.Syntax.Product(structure, arity: 1)
        guard shape.properties.fields.allSatisfy({ $0.type.trimmedDescription == shape.parameters[0] }) else {
            throw Type.Failure("@Representable requires a fixed homogeneous product")
        }
        let cases = shape.properties.fields.map { "case \($0.name)" }.joined(separator: "\n")
        return [DeclSyntax(stringLiteral: "@Finite\n\(shape.access)enum \(structure.name.text)Index { \(cases) }")]
    }
}
