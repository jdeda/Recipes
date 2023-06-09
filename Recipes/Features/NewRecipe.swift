import SwiftUI
import ComposableArchitecture

struct NewRecipe: ReducerProtocol {
  struct State: Equatable {
    @BindingState var recipe: DatabaseClient.Recipe
  }
  
  enum Action: BindableAction, Equatable {
    case cancelButtonTapped
    case saveButtonTapped
    case saveError(DatabaseClient.Failure)
    case binding(BindingAction<State>)
  }
  
  @Dependency(\.database) var database
  @Dependency(\.dismiss) var dismiss
  
  var body: some ReducerProtocolOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
        
      case .cancelButtonTapped:
        return .run { _ in await self.dismiss() }
        
      case .saveButtonTapped:
        return .run { [recipe = state.recipe] send in
          await self.database.addRecipe(recipe)
          await self.dismiss()
        }
        
      case .saveError:
        return .none
        
      case .binding:
        return .none
        
      }
    }
  }
}

private extension NewRecipe.State {
  var isSaveButtonDisabled: Bool {
    recipe.name.isEmpty
  }
}

// MARK: - SwiftUI

struct NewRecipeView: View {
  let store: StoreOf<NewRecipe>
  
  var body: some View {
    WithViewStore(store) { viewStore in
      NavigationStack {
        List {
          Section("Name") {
            TextField("Example", text: viewStore.binding(\.$recipe.name))
          }
        }
        .navigationTitle("New Recipe")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
          ToolbarItemGroup(placement: .cancellationAction) {
            Button("Cancel") {
              viewStore.send(.cancelButtonTapped)
            }
          }
          ToolbarItemGroup(placement: .primaryAction) {
            Button("Save") {
              viewStore.send(.saveButtonTapped)
            }
            .disabled(viewStore.isSaveButtonDisabled)
          }
        }
      }
    }
  }
}

// MARK: - SwiftUI Previews

struct NewRecipeView_Previews: PreviewProvider {
  static var previews: some View {
    Text("Hello World")
      .sheet(isPresented: .constant(true)) {
        NewRecipeView(store: Store(
          initialState: NewRecipe.State(
            recipe: .init(
              id: .init(),
              name: ""
            )
          ),
          reducer: NewRecipe()
        ))
      }
  }
}
