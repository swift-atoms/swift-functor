import Type_Algebra_Syntax
public import SwiftSyntax
import SwiftSyntaxBuilder
public enum Derivation {
    private static func shape(of structure: StructDeclSyntax) throws -> (properties: Type.Syntax.Properties, element: String, access: String, labels: [String?]) {
        let properties = Type.Syntax.Properties(structure)
        guard properties.diagnostics.isEmpty else {
            throw Type.Failure(properties.diagnostics.joined(separator: "; "))
        }
        let element: String
        if structure.genericParameterClause != nil {
            element = try Type.Syntax.Product(structure, arity: 1, reconstructing: false).parameters[0]
        } else {
            guard let first = properties.fields.first else {
                throw Type.Failure("@Representable requires an element type; use a generic parameter for an empty product")
            }
            element = first.type.trimmedDescription
        }
        guard properties.fields.allSatisfy({ $0.type.trimmedDescription == element && !(!$0.isMutable && $0.defaultValue != nil) }) else {
            throw Type.Failure("@Representable requires homogeneous stored coordinates without initialized constants")
        }
        var labels: [String?] = properties.fields.map(\.name)
        if properties.hasCustomInitializer {
            let constructors = structure.memberBlock.members.compactMap { $0.decl.as(InitializerDeclSyntax.self) }
            guard let constructor = constructors.first(where: { initializer in
                let parameters = Array(initializer.signature.parameterClause.parameters)
                guard initializer.optionalMark == nil, initializer.genericParameterClause == nil,
                      initializer.genericWhereClause == nil, initializer.signature.effectSpecifiers == nil,
                      initializer.attributes.isEmpty, parameters.count == properties.fields.count,
                      let body = initializer.body, body.statements.count == parameters.count else { return false }
                return zip(zip(properties.fields, parameters), body.statements).allSatisfy { pair, statement in
                    let (field, parameter) = pair
                    return parameter.type.trimmedDescription == field.type.trimmedDescription
                        && parameter.modifiers.isEmpty && parameter.attributes.isEmpty && parameter.ellipsis == nil
                        && statement.tokens(viewMode: .sourceAccurate).map(\.text) == ["self", ".", field.name, "=", (parameter.secondName ?? parameter.firstName).text]
                }
            }) else {
                throw Type.Failure("@Representable requires a direct fieldwise initializer; validating or transforming construction needs a manual representation")
            }
            labels = constructor.signature.parameterClause.parameters.map { $0.firstName.text == "_" ? nil : $0.firstName.text }
        }
        return (properties, element, Type.Syntax.Recursion.access(of: structure), labels)
    }

    public static func members(of declaration: some DeclGroupSyntax) throws -> [DeclSyntax] {
        guard let structure = declaration.as(StructDeclSyntax.self) else { throw Type.Failure("@Representable requires a fixed homogeneous product") }
        let shape = try shape(of: structure)
        let parameter = shape.element
        let fields = shape.properties.fields
        let arms = fields.map { "case .\($0.name): return self.\($0.name)" }.joined(separator: "\n")
        let arguments = zip(fields, shape.labels).map { field, label in "\(label.map { "\($0): " } ?? "")value(.\(field.name))" }.joined(separator: ", ")
        return [DeclSyntax(stringLiteral: """
            \(shape.access)var values: LazyMapCollection<Index.AllCases, \(parameter)> {
                Index.allCases.lazy.map(self.index)
            }
            """), DeclSyntax(stringLiteral: """
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
        let shape = try shape(of: structure)
        let cases = shape.properties.fields.map { "case \($0.name)" }.joined(separator: "\n")
        return [DeclSyntax(stringLiteral: "@Finite\n\(shape.access)enum \(structure.name.text)Index: Finite::Finite.Enumerable, Swift.CaseIterable, Swift.Sendable { \(cases) }")]
    }
}
