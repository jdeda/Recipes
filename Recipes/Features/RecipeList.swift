import SwiftUI
import ComposableArchitecture

struct RecipeList: ReducerProtocol {
  struct State: Equatable {
    var recipes = IdentifiedArrayOf<DatabaseClient.Recipe>()
  }
  enum Action: Equatable {
    case task
    case taskResponse(TaskResult<[DatabaseClient.Recipe]>)
    case deleteButtonTapped(id: DatabaseClient.Recipe.ID)
    case deleteResponse(TaskResult<String>)
  }
  
  @Dependency(\.database) var database
  
  var body: some ReducerProtocolOf<Self> {
    Reduce { state, action in
      switch action {
      
      case .task:
        return .run { send in
          for await value in self.database.getRecipes() {
            await send(.taskResponse(.success(value)))
          }
        }
        
      case let .taskResponse(.success(value)):
        state.recipes = .init(uniqueElements: value)
        return .none
        
      case let .deleteButtonTapped(id: id):
        return .task {
          await .deleteResponse(TaskResult {
            try await self.database.deleteRecipe(id)
            return "Success"
          })
        }
        
      case .deleteResponse:
        return .none
      
      case .taskResponse:
        return .none
        
      }
    }
  }
}

// MARK: - SwiftUI

struct RecipeListView: View {
  let store: StoreOf<RecipeList>
  
  struct ViewState: Equatable {
    let recipes: IdentifiedArrayOf<DatabaseClient.Recipe>
    
    init(_ state: RecipeList.State) {
      self.recipes = state.recipes
    }
  }
  
  var body: some View {
    WithViewStore(store, observe: ViewState.init) { viewStore in
      List {
        Section("Results") {
          ForEach(viewStore.recipes) { recipe in
            Text(recipe.name)
              .swipeActions {
                Button {
                  viewStore.send(.deleteButtonTapped(id: recipe.id))
                } label: {
                  Label("Delete", systemImage: "trash")
                }
                .tint(.red)
              }
          }
        }
      }
      .navigationTitle("Recipes")
      .task { await viewStore.send(.task).finish() }
    }
  }
}

// MARK: - SwiftUI Previews

struct RecipeListView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      RecipeListView(store: Store(
        initialState: RecipeList.State(),
        reducer: RecipeList()
      ))
    }
  }
}
