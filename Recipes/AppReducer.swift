import SwiftUI
import ComposableArchitecture

struct AppReducer: ReducerProtocol {
  struct State: Equatable {
    var recipeList = RecipeList.State()
  }
  enum Action: Equatable {
    case recipeList(RecipeList.Action)
  }
  var body: some ReducerProtocolOf<Self> {
    Scope(state: \.recipeList, action: /Action.recipeList) {
      RecipeList()
    }
  }
}

// MARK: - SwiftUI

struct AppView: View {
  let store: StoreOf<AppReducer>
  
  var body: some View {
    RecipeListView(store: store.scope(
      state: \.recipeList,
      action: AppReducer.Action.recipeList
    ))
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
