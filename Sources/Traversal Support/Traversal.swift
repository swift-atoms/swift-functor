/// Concrete finite traversals. Arrays are visited left-to-right; failures stop further visits.
/// Async traversal is sequential and introduces no tasks or parallel scheduling policy.
public enum Traversal {
    public static func optional<A, B>(_ values: [A], _ transform: (A) -> B?) -> [B]? {
        var result: [B] = []
        for value in values { guard let mapped = transform(value) else { return nil }; result.append(mapped) }
        return result
    }
    public static func optional<A, B>(_ value: A?, _ transform: (A) -> B?) -> B?? {
        guard let value else { return .some(nil) }
        guard let mapped = transform(value) else { return nil }
        return .some(.some(mapped))
    }
    public static func result<A, B, Failure: Error>(_ values: [A], _ transform: (A) -> Result<B, Failure>) -> Result<[B], Failure> {
        var result: [B] = []
        for value in values {
            switch transform(value) { case .success(let mapped): result.append(mapped); case .failure(let error): return .failure(error) }
        }
        return .success(result)
    }
    public static func result<A, B, Failure: Error>(_ value: A?, _ transform: (A) -> Result<B, Failure>) -> Result<B?, Failure> {
        guard let value else { return .success(nil) }
        return transform(value).map(Optional.some)
    }
    public static func sequential<A, B>(_ values: [A], _ transform: (A) async throws -> B) async rethrows -> [B] {
        var result: [B] = []
        for value in values { result.append(try await transform(value)) }
        return result
    }
    public static func sequential<A, B>(_ value: A?, _ transform: (A) async throws -> B) async rethrows -> B? {
        guard let value else { return nil }
        return try await transform(value)
    }
}
