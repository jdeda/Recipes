import SwiftUI
import ComposableArchitecture

struct NewRecipe: ReducerProtocol {
  struct State: Equatable {
    @BindingState var recipe: DatabaseClient.Recipe
    @BindingState var focusedField: FocusField? = .name
    @PresentationState var alert: AlertState<Action.Alert>?
    
    enum FocusField: Equatable {
      case name
    }
  }
  
  enum Action: BindableAction, Equatable {
    case cancelButtonTapped
    case saveButtonTapped
    case saveError(DatabaseClient.Failure)
    case alert(PresentationAction<Alert>)
    case binding(BindingAction<State>)
    
    enum Alert: Equatable {}
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
        guard !state.recipe.name.isEmpty else {
          state.alert = .nameCannotBeEmpty
          return .none
        }
        return .run { [recipe = state.recipe] send in
          await self.database.addRecipe(recipe)
          await self.dismiss()
        }
        
      case .binding, .alert, .saveError:
        return .none
        
      }
    }
  }
}

extension AlertState where Action == NewRecipe.Action.Alert {
  static let nameCannotBeEmpty = Self {
    TextState("Name cannot be empty")
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
  @FocusState private var focusedField: NewRecipe.State.FocusField?
  
  var body: some View {
    WithViewStore(store) { viewStore in
      NavigationStack {
        List {
          Section("Name") {
            TextField("Example", text: viewStore.binding(\.$recipe.name))
              .focused($focusedField, equals: .name)
              .onSubmit { viewStore.send(.saveButtonTapped) }
          }
        }
        .navigationTitle("New Recipe")
        .navigationBarTitleDisplayMode(.inline)
        .synchronize(viewStore.binding(\.$focusedField), self.$focusedField)
        .onAppear { self.focusedField = viewStore.focusedField }
        .alert(store: store.scope(
          state: \.$alert,
          action: NewRecipe.Action.alert
        ))
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
