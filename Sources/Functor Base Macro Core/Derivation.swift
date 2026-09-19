import Type_Algebra_Syntax
public import SwiftSyntax
import SwiftSyntaxBuilder

public enum Derivation {
    public static func base(of declaration: EnumDeclSyntax) -> [DeclSyntax] {
        do { try RecursiveShape.validate(declaration) } catch {
            return [DeclSyntax(stringLiteral: "#error(\(String(reflecting: String(describing: error))))")]
        }
        let access = RecursiveShape.access(of: declaration)
        let cases = RecursiveShape.elements(of: declaration)
        let declarations = cases.map { element in
            let parameters = RecursiveShape.parameters(of: element).map { parameter in
                let type = RecursiveShape.isRecursive(parameter.type, in: declaration)
                    ? "Recursive"
                    : parameter.type.trimmedDescription
                guard let label = RecursiveShape.label(of: parameter) else { return type }
                return "\(label): \(type)"
            }.joined(separator: ", ")
            return parameters.isEmpty
                ? "case \(element.name.text)"
                : "case \(element.name.text)(\(parameters))"
        }.joined(separator: "\n")

        return ["""
            @Functor
            \(raw: access)enum Base<Recursive> {
                \(raw: declarations)

            }
            """]
    }

}
