import Type_Algebra_Syntax
public import SwiftSyntax
import SwiftSyntaxBuilder

public enum Derivation {
    private enum Effect: String, CaseIterable { case optional, result, sequential }
    private static func expression(_ type: TypeExpression, value: String, parameter: String, effect: Effect, depth: Int = 0) throws -> String {
        let target = type.spelling(replacing: [parameter: "Mapped"])
        switch type {
        case .constant:
            switch effect {
            case .optional: return "Optional<\(target)>.some(\(value))"
            case .result: return "Result<\(target), Failure>.success(\(value))"
            case .sequential: return value
            }
        case .parameter: return "\(effect == .sequential ? "try await " : "")transform(\(value))"
        case .array(let element), .optional(let element):
            let body = try expression(element, value: "element\(depth)", parameter: parameter, effect: effect, depth: depth + 1)
            return "\(effect == .sequential ? "try await " : "")Traversal_Support::Traversal.\(effect.rawValue)(\(value), { element\(depth) in \(body) })"
        case .tuple(let coordinates):
            let parts = try coordinates.enumerated().map { index, coordinate in
                try expression(coordinate.type, value: "(\(value)).\(index)", parameter: parameter, effect: effect, depth: depth + 1)
            }
            let names = parts.indices.map { "part\(depth)_\($0)" }
            let result = "(" + coordinates.enumerated().map { index, coordinate in
                (coordinate.label.map { $0 == "_" ? "" : "\($0): " } ?? "") + names[index]
            }.joined(separator: ", ") + ")"
            switch effect {
            case .optional:
                return "({ () -> \(target)? in " + parts.enumerated().map { "guard let \(names[$0.offset]) = \($0.element) else { return nil }" }.joined(separator: "\n") + "\nreturn .some(\(result)) })()"
            case .result:
                return "Result<\(target), Failure> { () throws(Failure) in " + parts.enumerated().map { "let \(names[$0.offset]) = try (\($0.element)).get()" }.joined(separator: "\n") + "\nreturn \(result) }"
            case .sequential:
                // A tuple expression evaluates its elements in source order without another async closure.
                return "(" + coordinates.enumerated().map { index, coordinate in
                    (coordinate.label.map { $0 == "_" ? "" : "\($0): " } ?? "") + parts[index]
                }.joined(separator: ", ") + ")"
            }
        case .arrow, .unsupported: throw AlgebraDiagnostic("@Traversable requires finite polynomial positions; function and unknown constructors need an explicit implementation")
        }
    }

    public static func members(of declaration: some DeclGroupSyntax) throws -> [DeclSyntax] {
        let parameter: String
        let name: String
        let access = RecursiveShape.access(of: declaration)
        let fields: [(label: String?, value: String, type: TypeExpression)]
        let enumeration: EnumDeclSyntax?
        if let structure = declaration.as(StructDeclSyntax.self) {
            let shape = try GenericProduct(structure, arity: 1)
            parameter = shape.parameters[0]; name = structure.name.text; enumeration = nil
            fields = shape.properties.fields.enumerated().map { (label: $0.element.name, value: "self.\($0.element.name)", type: shape.fields[$0.offset]) }
        } else if let value = declaration.as(EnumDeclSyntax.self), let generics = value.genericParameterClause,
            generics.parameters.count == 1, let first = generics.parameters.first, first.inheritedType == nil, value.genericWhereClause == nil {
            parameter = first.name.text; name = value.name.text; enumeration = value; fields = []
        } else { throw AlgebraDiagnostic("@Traversable requires a struct or enum with one unconstrained parameter") }
        let target = "\(name)<Mapped>"
        return try Effect.allCases.map { effect in
            func body(_ fields: [(label: String?, value: String, type: TypeExpression)], constructor: String) throws -> String {
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
                let arms = try RecursiveShape.elements(of: enumeration).map { item -> String in
                    let payloads = RecursiveShape.parameters(of: item)
                    let pattern = payloads.isEmpty ? ".\(item.name.text)" : "let .\(item.name.text)(" + payloads.indices.map { "value\($0)" }.joined(separator: ", ") + ")"
                    let fields = payloads.enumerated().map { (label: RecursiveShape.label(of: $0.element), value: "value\($0.offset)", type: TypeExpression($0.element.type, parameters: [parameter])) }
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
