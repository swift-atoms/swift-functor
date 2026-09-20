import Type_Algebra_Syntax
public import SwiftSyntax
import SwiftSyntaxBuilder

public enum Derivation {
    private enum Effect: String, CaseIterable { case optional, result, sequential }
    private static func expression(_ type: Type.Syntax.Expression, value: String, parameter: String, effect: Effect) throws -> String {
        try Type.Syntax.Traversal.interpret(type, value: value, parameter: parameter,
            constant: { shape, value in
                let target = shape.spelling(replacing: [parameter: "Mapped"])
                switch effect {
                case .optional: return "Optional<\(target)>.some(\(value))"
                case .result: return "Result<\(target), Failure>.success(\(value))"
                case .sequential: return value
                }
            },
            transform: { "\(effect == .sequential ? "try await " : "")transform(\($0))" },
            collection: { _, value, binding, body in
                "\(effect == .sequential ? "try await " : "")Traversal_Support::Traversal.\(effect.rawValue)(\(value), { \(binding) in \(body) })"
            },
            product: { shape, coordinates, depth in
                let target = shape.spelling(replacing: [parameter: "Mapped"])
                let parts = coordinates.map { $0.1 }
                let names = parts.indices.map { "part\(depth)_\($0)" }
                func tuple(_ values: [String]) -> String {
                    "(" + zip(coordinates, values).map { coordinate, value in
                        (coordinate.0.map { $0 == "_" ? "" : "\($0): " } ?? "") + value
                    }.joined(separator: ", ") + ")"
                }
                switch effect {
                case .optional:
                    return "({ () -> \(target)? in " + parts.enumerated().map { "guard let \(names[$0.offset]) = \($0.element) else { return nil }" }.joined(separator: "\n") + "\nreturn .some(\(tuple(names))) })()"
                case .result:
                    return "Result<\(target), Failure> { () throws(Failure) in " + parts.enumerated().map { "let \(names[$0.offset]) = try (\($0.element)).get()" }.joined(separator: "\n") + "\nreturn \(tuple(names)) }"
                case .sequential: return tuple(parts)
                }
            })
    }

    public static func members(of declaration: some DeclGroupSyntax) throws -> [DeclSyntax] {
        let parameter: String
        let name: String
        let access = Type.Syntax.Recursion.access(of: declaration)
        let fields: [(label: String?, value: String, type: Type.Syntax.Expression)]
        let enumeration: EnumDeclSyntax?
        if let structure = declaration.as(StructDeclSyntax.self) {
            let shape = try Type.Syntax.Product(structure, arity: 1)
            parameter = shape.parameters[0]; name = structure.name.text; enumeration = nil
            fields = shape.properties.fields.enumerated().map { (label: $0.element.name, value: "self.\($0.element.name)", type: shape.fields[$0.offset]) }
        } else if let value = declaration.as(EnumDeclSyntax.self), let generics = value.genericParameterClause,
            generics.parameters.count == 1, let first = generics.parameters.first, first.inheritedType == nil, value.genericWhereClause == nil {
            parameter = first.name.text; name = value.name.text; enumeration = value; fields = []
        } else { throw Type.Failure("@Traversable requires a struct or enum with one unconstrained parameter") }
        let target = "\(name)<Mapped>"
        return try Effect.allCases.map { effect in
            func body(_ fields: [(label: String?, value: String, type: Type.Syntax.Expression)], constructor: String) throws -> String {
                let expressions = try fields.map { try expression($0.type, value: $0.value, parameter: parameter, effect: effect) }
                let result = constructor + (fields.isEmpty && constructor.hasPrefix(".") ? "" : "(" + fields.enumerated().map { index, field in
                    (field.label.map { "\($0): " } ?? "") + "field\(index)"
                }.joined(separator: ", ") + ")")
                switch effect {
                case .optional:
                    return expressions.enumerated().map { "guard let field\($0.offset) = \($0.element) else { return nil }" }.joined(separator: "\n") + "\nreturn .some(\(result))"
                case .result:
                    return "return Result<\(target), Failure> { () throws(Failure) in\n" + expressions.enumerated().map { "let field\($0.offset) = try (\($0.element)).get()" }.joined(separator: "\n") + "\nreturn \(result)\n}"
                case .sequential:
                    return expressions.enumerated().map { "let field\($0.offset) = \($0.element)" }.joined(separator: "\n") + "\nreturn \(result)"
                }
            }
            let implementation: String
            if let enumeration {
                let arms = try Type.Syntax.Recursion.elements(of: enumeration).map { item -> String in
                    let payloads = Type.Syntax.Recursion.parameters(of: item)
                    let pattern = payloads.isEmpty ? ".\(item.name.text)" : "let .\(item.name.text)(" + payloads.indices.map { "value\($0)" }.joined(separator: ", ") + ")"
                    let fields = payloads.enumerated().map { (label: Type.Syntax.Recursion.label(of: $0.element), value: "value\($0.offset)", type: Type.Syntax.Expression($0.element.type, parameters: [parameter])) }
                    return "case \(pattern):\n" + (try body(fields, constructor: ".\(item.name.text)"))
                }
                implementation = "switch self {\n" + arms.joined(separator: "\n") + "\n}"
            } else { implementation = try body(fields, constructor: target) }
            let method: String
            switch effect {
            case .optional: method = "traverseOptional<Mapped>(_ transform: (\(parameter)) -> Mapped?) -> \(target)?"
            case .result: method = "traverseResult<Mapped, Failure: Error>(_ transform: (\(parameter)) -> Result<Mapped, Failure>) -> Result<\(target), Failure>"
            case .sequential: method = "traverseSequential<Mapped>(_ transform: (\(parameter)) async throws -> Mapped) async rethrows -> \(target)"
            }
            return DeclSyntax(stringLiteral: "\(access)func \(method) {\n\(implementation)\n}")
        }
    }
}
