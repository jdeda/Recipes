import Foundation
import Dependencies
import Combine
import IdentifiedCollections

extension DatabaseClient {
  static var live: Self {
    final actor Actor {
      @Published var recipes = IdentifiedArrayOf<Recipe>(uniqueElements: [
        .init(id: UUID(), name: "Chicken Parmesan"),
        .init(id: UUID(), name: "Spaghetti Bolognese"),
        .init(id: UUID(), name: "Grilled Salmon"),
        .init(id: UUID(), name: "Vegetable Stir-Fry"),
        .init(id: UUID(), name: "Beef Tacos"),
        .init(id: UUID(), name: "Roasted Chicken"),
        .init(id: UUID(), name: "Pasta Carbonara"),
        .init(id: UUID(), name: "Shrimp Scampi"),
        .init(id: UUID(), name: "Veggie Pizza"),
        .init(id: UUID(), name: "Beef Stir-Fry"),
        .init(id: UUID(), name: "Baked Ziti"),
        .init(id: UUID(), name: "Honey Garlic Chicken"),
        .init(id: UUID(), name: "Fish Tacos")
      ])
      
      func remove(recipe id: Recipe.ID) {
        self.recipes.remove(id: id)
      }
    }
    
    let actor = Actor()
    
    return Self(
      getRecipes: {
        AsyncStream { continuation in
          let task = Task {
            while !Task.isCancelled {
              for await value in await actor.$recipes.values {
                continuation.yield(value.elements)
              }
            }
          }
          continuation.onTermination = { _ in task.cancel() }
        }
      },
      deleteRecipe: { id in
        try await actor.remove(recipe: id)
      }
    )
  }
}
