import SwiftUI

/// The view used to display the Pokémon sprite and description.
public struct PokemonView: View {
  /// The sprite side, scaled with the user's text size so it does not stay a fixed 100pt
  /// square while everything around it grows.
  @ScaledMetric(relativeTo: .title) private var spriteSide: CGFloat = 100

  private let viewModel: PokemonViewModel

  public init(viewModel: PokemonViewModel) {
    self.viewModel = viewModel
  }

  public var body: some View {
    VStack(spacing: 8) {
      sprite
        .frame(width: spriteSide, height: spriteSide)
        .clipShape(.rect(cornerRadius: 12))
        .accessibilityLabel(Text(String(localized: "Sprite of \(viewModel.name)", bundle: .module)))

      Text(viewModel.name)
        .font(.title)
        .bold()

      Text(viewModel.description)
        .multilineTextAlignment(.center)
    }
    .padding(.horizontal)
    // One element for VoiceOver: name and description read as a single sentence rather
    // than as three separate stops.
    .accessibilityElement(children: .combine)
  }

  /// The sprite, with a distinct state for "still loading" and "could not be loaded".
  @ViewBuilder private var sprite: some View {
    AsyncImage(url: viewModel.spriteUrl) { phase in
      switch phase {
        case let .success(image):
          image.resizable()
        case .failure:
          placeholder(systemImage: "photo.badge.exclamationmark")
        case .empty:
          placeholder(systemImage: nil)
        @unknown default:
          placeholder(systemImage: nil)
      }
    }
  }

  private func placeholder(systemImage: String?) -> some View {
    RoundedRectangle(cornerRadius: 12, style: .continuous)
      .fill(.quaternary)
      .overlay {
        if let systemImage {
          Image(systemName: systemImage)
            .foregroundStyle(.secondary)
        }
      }
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
