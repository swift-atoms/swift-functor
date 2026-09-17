public import SwiftSyntax
import SwiftSyntaxBuilder

public enum Derivation {
    public static func base(of declaration: EnumDeclSyntax) -> [DeclSyntax] {
        guard supports(declaration) else {
            return ["""
                #error("Recursive occurrences must be direct enum-case payloads.")
                """]
        }
        let access = access(of: declaration)
        let cases = elements(of: declaration)
        let declarations = cases.map { element in
            let parameters = parameters(of: element).map { parameter in
                let type = isRecursive(parameter.type, in: declaration)
                    ? "Recursive"
                    : parameter.type.trimmedDescription
                guard let label = label(of: parameter) else { return type }
                return "\(label): \(type)"
            }.joined(separator: ", ")
            return parameters.isEmpty
                ? "case \(element.name.text)"
                : "case \(element.name.text)(\(parameters))"
        }.joined(separator: "\n")

        let branches = cases.map { element in
            let parameters = parameters(of: element)
            let bindings = pattern(of: parameters)
            let arguments = parameters.enumerated().map { index, parameter in
                let value = isRecursive(parameter.type, in: declaration)
                    ? "transform(value\(index))"
                    : "value\(index)"
                guard let label = label(of: parameter) else { return value }
                return "\(label): \(value)"
            }.joined(separator: ", ")
            guard !parameters.isEmpty else {
                return "case .\(element.name.text): return .\(element.name.text)"
            }
            return "case let .\(element.name.text)(\(bindings)): return .\(element.name.text)(\(arguments))"
        }.joined(separator: "\n")

        return ["""
            \(raw: access)enum Base<Recursive> {
                \(raw: declarations)

                \(raw: access)func map<Mapped>(
                    _ transform: (Recursive) -> Mapped
                ) -> Base<Mapped> {
                    switch self {
                    \(raw: branches)
                    }
                }
            }
            """]
    }

    public static func project(of declaration: EnumDeclSyntax) -> [DeclSyntax] {
        let access = access(of: declaration)
        let branches = elements(of: declaration).map { element in
            let parameters = parameters(of: element)
            guard !parameters.isEmpty else {
                return "case .\(element.name.text): return .\(element.name.text)"
            }
            return "case let .\(element.name.text)(\(pattern(of: parameters))): return .\(element.name.text)(\(arguments(of: parameters)))"
        }.joined(separator: "\n")

        return ["""
            \(raw: access)func project() -> Base<Self> {
                switch self {
                \(raw: branches)
                }
            }
            """]
    }

    public static func embed(of declaration: EnumDeclSyntax) -> [DeclSyntax] {
        let access = access(of: declaration)
        let branches = elements(of: declaration).map { element in
            let parameters = parameters(of: element)
            guard !parameters.isEmpty else {
                return "case .\(element.name.text): return .\(element.name.text)"
            }
            return "case let .\(element.name.text)(\(pattern(of: parameters))): return .\(element.name.text)(\(arguments(of: parameters)))"
        }.joined(separator: "\n")

        return ["""
            \(raw: access)static func embed(_ base: Base<Self>) -> Self {
                switch base {
                \(raw: branches)
                }
            }
            """]
    }

    private static func access(of declaration: EnumDeclSyntax) -> String {
        declaration.modifiers.contains { $0.name.tokenKind == .keyword(.public) }
            ? "public "
            : ""
    }

    private static func elements(
        of declaration: EnumDeclSyntax
    ) -> [EnumCaseElementSyntax] {
        declaration.memberBlock.members
            .compactMap { $0.decl.as(EnumCaseDeclSyntax.self) }
            .flatMap(\.elements)
    }

    private static func parameters(
        of element: EnumCaseElementSyntax
    ) -> [EnumCaseParameterSyntax] {
        Array(element.parameterClause?.parameters ?? [])
    }

    private static func pattern(
        of parameters: [EnumCaseParameterSyntax]
    ) -> String {
        parameters.enumerated().map { index, parameter in
            guard let label = label(of: parameter) else { return "value\(index)" }
            return "\(label): value\(index)"
        }.joined(separator: ", ")
    }

    private static func arguments(
        of parameters: [EnumCaseParameterSyntax]
    ) -> String {
        parameters.enumerated().map { index, parameter in
            guard let label = label(of: parameter) else { return "value\(index)" }
            return "\(label): value\(index)"
        }.joined(separator: ", ")
    }

    private static func label(
        of parameter: EnumCaseParameterSyntax
    ) -> String? {
        guard let label = parameter.firstName, label.text != "_" else { return nil }
        return label.trimmedDescription
    }

    private static func isRecursive(
        _ type: TypeSyntax,
        in declaration: EnumDeclSyntax
    ) -> Bool {
        let spelling = type.trimmedDescription
        return spelling == "Self"
            || spelling == declaration.name.text
            || spelling.hasPrefix("\(declaration.name.text)<")
    }

    private static func supports(_ declaration: EnumDeclSyntax) -> Bool {
        elements(of: declaration).allSatisfy { element in
            parameters(of: element).allSatisfy { parameter in
                isRecursive(parameter.type, in: declaration)
                    || !Recursion.contains(
                        in: parameter.type,
                        named: declaration.name.text
                    )
            }
        }
    }
}
