import SwiftUI
import ComposableArchitecture

struct RecipeList: ReducerProtocol {
  struct State: Equatable {
    var recipes = IdentifiedArrayOf<DatabaseClient.Recipe>()
    @PresentationState var destination: Destination.State?
  }
  enum Action: Equatable {
    case task
    case taskResponse(TaskResult<[DatabaseClient.Recipe]>)
    case addButtonTapped
    case deleteButtonTapped(id: DatabaseClient.Recipe.ID)
    case deleteResponse(TaskResult<String>)
    case destination(PresentationAction<Destination.Action>)
  }
  
  @Dependency(\.uuid) var uuid
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
        
      case .addButtonTapped:
        state.destination = .newRecipe(.init(recipe: .init(
          id: self.uuid(),
          name: ""
        )))
        return .none
        
      case let .deleteButtonTapped(id: id):
        return .task {
          await .deleteResponse(TaskResult {
            try await self.database.deleteRecipe(id)
            return "Success"
          })
        }
        
      case .destination, .deleteResponse, .taskResponse:
        return .none
      }
    }
    .ifLet(\.$destination, action: /Action.destination) {
      Destination()
    }
  }
  
  struct Destination: ReducerProtocol {
    enum State: Equatable {
      case newRecipe(NewRecipe.State)
    }
    enum Action: Equatable {
      case newRecipe(NewRecipe.Action)
    }
    var body: some ReducerProtocolOf<Self> {
      Scope(state: /State.newRecipe, action: /Action.newRecipe) {
        NewRecipe()
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
      .navigationBarTitleDisplayMode(.large)
      .task { await viewStore.send(.task).finish() }
      .sheet(
        store: store.scope(state: \.$destination, action: RecipeList.Action.destination),
        state: /RecipeList.Destination.State.newRecipe,
        action: RecipeList.Destination.Action.newRecipe,
        content: NewRecipeView.init(store:)
      )
      .toolbar {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
          Button {
            viewStore.send(.addButtonTapped)
          } label: {
            Image(systemName: "plus")
          }
        }
      }
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
