import struct Pokespeare.PokemonView
import SwiftData
import SwiftUI

struct SearchView: View {
  @Environment(\.modelContext) private var modelContext
  @State private var viewModel = SearchViewModel()
  
  var body: some View {
    NavigationStack {
      content
    }
    .sheet(item: $viewModel.pokemonDetail) { pokemon in
      PokemonView(viewModel: viewModel.pokemonViewModel(for: pokemon))
        .padding()
        .presentationDetents([.fraction(0.4)])
        .presentationDragIndicator(.visible)
    }
    .alert(viewModel.warning, isPresented: $viewModel.isErrorVisible) {
      Button(viewModel.ok, action: viewModel.didTapAlertButton)
    } message: {
      Text(viewModel.errorDescription)
    }
    .alert(viewModel.warning, isPresented: $viewModel.historyAlertConfirmation) {
      Button(viewModel.cancel, role: .cancel, action: viewModel.didTapCancelHistoryDeletion)
      Button(viewModel.confirm, role: .destructive, action: viewModel.didTapConfirmHistoryDeletion)
    } message: {
      Text(viewModel.confirmMessage)
    }
  }
  
  // MARK: - Subviews
  
  /// The content of the view.
  private var content: some View {
    VStack(alignment: .leading, spacing: 16) {
      searchHeader
        .padding([.top, .horizontal], 16)
      recentlySearchedList
    }
    .background(Color(UIColor.systemGroupedBackground))
    .navigationTitle(viewModel.title)
    .onAppear {
      viewModel.evaluateModelContext(modelContext)
    }
  }
  
  /// The search bar component.
  private var searchHeader: some View {
    HStack(spacing: 16) {
      TextField(viewModel.searchPlaceholder, text: $viewModel.searchText)
        .clearButtonVisibility(text: $viewModel.searchText)
        .onChange(of: viewModel.searchText, viewModel.searchTextDidChange)
        .onSubmit(viewModel.didTapSearchButton)
        .autocorrectionDisabled()
        .keyboardType(.asciiCapable)
        .padding(10)
        .foregroundStyle(viewModel.isLoading ? Color(.secondaryLabel) : Color(.label))
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.capsule(style: .continuous))
        .disabled(viewModel.isLoading)
      
      if viewModel.isSearchButtonVisible {
        Button(action: viewModel.didTapSearchButton) {
          Text(viewModel.search).bold()
        }
        .transition(
          .asymmetric(
            insertion: .push(from: .trailing),
            removal: .push(from: .leading)
          )
        )
        .disabled(viewModel.isLoading)
      }
    }
    .animation(.default, value: viewModel.isSearchButtonVisible)
  }
  
  /// The history list component.
  @ViewBuilder private var recentlySearchedList: some View {
    if viewModel.hasHistory {
      List {
        Section {
          ForEach(viewModel.recentlySearched, content: item)
        } header: {
          HStack {
            Text(viewModel.sectionHeader)
              .font(.footnote)
              .foregroundStyle(.gray)
            
            Spacer()
            
            Button(action: viewModel.didTapClearHistoryButton) {
              Image(systemName: "trash")
            }
            .disabled(viewModel.isLoading)
          }
          .padding(.vertical, 8)
          .padding(.horizontal)
        }
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .listRowInsets(.init(top: 4, leading: .zero, bottom: 4, trailing: .zero))
      }
      .scrollIndicators(.hidden)
    } else {
      Spacer()
    }
  }
  
  /// Creates the item component for the given `pokemon`.
  /// - Parameter pokemon: The Pokémon model.
  /// - Returns: The history list item component.
  private func item(for pokemon: Pokemon) -> some View {
    Button {
      viewModel.didTapPokemon(pokemon)
    } label: {
      HStack {
        AsyncImage(url: pokemon.spriteUrl) {
          $0
            .resizable()
            .aspectRatio(contentMode: .fill)
        } placeholder: {
          Image(.pokeBall)
            .resizable()
            .aspectRatio(contentMode: .fill)
        }
        .frame(maxWidth: 50, maxHeight: 30)
        
        Text(pokemon.name.capitalized)
          .tint(Color.primary)
        
        Spacer()
      }
      .padding(.leading, 8)
      .padding([.top, .bottom, .trailing], 16)
      .background(Color(.secondarySystemGroupedBackground))
    }
    .disabled(viewModel.isLoading)
    .clipShape(.rect(cornerRadius: 12, style: .continuous))
  }
}

#if DEBUG
#Preview {
  SearchView()
    .modelContainer(for: Pokemon.self)
}
#endif
