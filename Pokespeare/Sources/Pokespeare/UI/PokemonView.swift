import SwiftUI

/// The view used to display the Pokémon sprite and description.
public struct PokemonView: View {
  private let viewModel: PokemonViewModel

  public init(viewModel: PokemonViewModel) {
    self.viewModel = viewModel
  }

  public var body: some View {
    VStack(spacing: 8) {
      AsyncImage(url: viewModel.spriteUrl) {
        $0
          .resizable()
          .frame(width: 100, height: 100)
      } placeholder: {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
          .fill(.gray)
      }
      .frame(maxWidth: 100, maxHeight: 100)
      .clipShape(.rect(cornerRadius: 12))

      Text(viewModel.name)
        .font(.title)
        .bold()

      Text(viewModel.description)
        .multilineTextAlignment(.center)
    }
    .padding(.horizontal)
  }
}

#if DEBUG
#Preview {
  PokemonView(
    viewModel: PokemonViewModel(
      name: "Pikachu",
      description: "Pikachu stores electricity in its cheeks and discharges 't at which hour 't doth feel threatened.",
      spriteUrl: URL(string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/25.png")!
    )
  )
}
#endif
