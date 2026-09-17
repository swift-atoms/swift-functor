import SwiftSyntax

final class Recursion: SyntaxVisitor {
    private let name: String
    private var found = false

    private init(name: String) {
        self.name = name
        super.init(viewMode: .sourceAccurate)
    }

    override func visit(
        _ node: IdentifierTypeSyntax
    ) -> SyntaxVisitorContinueKind {
        if node.name.text == "Self" || node.name.text == name {
            found = true
            return .skipChildren
        }
        return .visitChildren
    }
}

extension Recursion {
    static func contains(in type: TypeSyntax, named name: String) -> Bool {
        let recursion = Recursion(name: name)
        recursion.walk(type)
        return recursion.found
    }
}
