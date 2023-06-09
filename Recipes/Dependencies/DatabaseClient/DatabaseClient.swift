import Foundation
import Dependencies

struct DatabaseClient {
  var getRecipes: @Sendable () -> AsyncStream<[Recipe]>
  var deleteRecipe: @Sendable (Recipe.ID) async throws -> Void
  
  struct Recipe: Identifiable, Equatable, Codable {
    let id: UUID
    let name: String
  }
}

extension DependencyValues {
  var database: DatabaseClient {
    get { self[DatabaseClient.self] }
    set { self[DatabaseClient.self] = newValue }
  }
}

extension DatabaseClient: DependencyKey {
  static var liveValue = Self.live
}
