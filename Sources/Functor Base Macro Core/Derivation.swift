import Type_Algebra_Syntax
public import SwiftSyntax
import SwiftSyntaxBuilder

public enum Derivation {
    public static func base(of declaration: EnumDeclSyntax) -> [DeclSyntax] {
        do { try Type.Syntax.Recursion.validate(declaration) } catch {
            return [DeclSyntax(stringLiteral: "#error(\(String(reflecting: String(describing: error))))")]
        }
        let access = Type.Syntax.Recursion.access(of: declaration)
        let cases = Type.Syntax.Recursion.elements(of: declaration)
        let declarations = cases.map { element in
            let parameters = Type.Syntax.Recursion.parameters(of: element).map { parameter in
                let type = Type.Syntax.Recursion.isRecursive(parameter.type, in: declaration)
                    ? "Recursive"
                    : parameter.type.trimmedDescription
                guard let label = Type.Syntax.Recursion.label(of: parameter) else { return type }
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
