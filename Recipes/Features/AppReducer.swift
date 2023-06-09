import SwiftUI
import ComposableArchitecture

struct AppReducer: ReducerProtocol {
  struct State: Equatable {
    @PresentationState var destination: Destination.State?
  }
  
  enum Action: Equatable {
    case navigateToRecipeList
    case destination(PresentationAction<Destination.Action>)
  }
  
  var body: some ReducerProtocolOf<Self> {
    Reduce { state, action in
      switch action {
        
      case .navigateToRecipeList:
        state.destination = .recipeList()
        return .none
        
      case .destination:
        return .none
        
      }
    }
    .ifLet(\.$destination, action: /Action.destination) {
      Destination()
    }
    ._printChanges()
  }
  
  struct Destination: ReducerProtocol {
    enum State: Equatable {
      case recipeList(RecipeList.State = .init())
    }
    enum Action: Equatable {
      case recipeList(RecipeList.Action)
    }
    var body: some ReducerProtocolOf<Self> {
      Scope(state: /State.recipeList, action: /Action.recipeList) {
        RecipeList()
      }
    }
  }
}

// MARK: - SwiftUI

struct AppView: View {
  let store: StoreOf<AppReducer>
  
  var body: some View {
    WithViewStore(store) { viewStore in
      NavigationStack {
        List {
          Button("Recipe List") {
            viewStore.send(.navigateToRecipeList)
          }
        }
        .navigationTitle("Recipes")
        .navigationDestination(
          store: store.scope(state: \.$destination, action: AppReducer.Action.destination),
          state: /AppReducer.Destination.State.recipeList,
          action: AppReducer.Destination.Action.recipeList,
          destination: RecipeListView.init(store:)
        )
      }
    }
  }
}

// MARK: - SwiftUI Previews

struct AppView_Previews: PreviewProvider {
  static var previews: some View {
    AppView(store: Store(
      initialState: AppReducer.State(),
      reducer: AppReducer()
    ))
  }
}
