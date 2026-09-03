public import SwiftSyntax
import SwiftSyntaxBuilder

public enum Derivation {
    public static func expansion(of structure: StructDeclSyntax) -> [DeclSyntax] {
        guard
            let generic = structure.genericParameterClause,
            generic.parameters.count == 1,
            let parameter = generic.parameters.first
        else { return [] }

        let element = parameter.name.text
        let fields = structure.memberBlock.members
            .compactMap { $0.decl.as(VariableDeclSyntax.self) }
            .flatMap(\.bindings)
            .compactMap { binding -> (String, TypeSyntax)? in
                guard
                    let name = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text,
                    let type = binding.typeAnnotation?.type
                else { return nil }
                return (name, type)
            }

        guard fields.allSatisfy({ field in
            field.1.trimmedDescription == element
                || !field.1.tokens(viewMode: .sourceAccurate).contains {
                    $0.tokenKind == .identifier(element)
                }
        }) else {
            return []
        }

        let target = "\(structure.name.text)<Mapped>"
        let arguments = fields.map { field in
            "\(field.0): \(field.1.trimmedDescription == element ? "transform(self.\(field.0))" : "self.\(field.0)")"
        }.joined(separator: ", ")

        return ["""
            func map<Mapped>(_ transform: (\(raw: element)) -> Mapped) -> \(raw: target) {
                \(raw: target)(\(raw: arguments))
            }
            """]
    }
}
