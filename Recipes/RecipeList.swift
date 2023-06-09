import SwiftUI
import ComposableArchitecture

struct RecipeList: ReducerProtocol {
  struct State: Equatable {
    
  }
  enum Action: Equatable {
    
  }
  var body: some ReducerProtocolOf<Self> {
    EmptyReducer()
  }
}

// MARK: - SwiftUI

struct RecipeListView: View {
  let store: StoreOf<RecipeList>
  
  var body: some View {
    VStack {
      Image(systemName: "globe")
        .imageScale(.large)
        .foregroundColor(.accentColor)
      Text("Hello, world!")
    }
    .padding()
  }
}

// MARK: - SwiftUI Previews

struct RecipeListView_Previews: PreviewProvider {
  static var previews: some View {
    RecipeListView(store: Store(
      initialState: RecipeList.State(),
      reducer: RecipeList()
    ))
  }
}
