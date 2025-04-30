import SwiftUI

/// A `ViewModifier` that adds the clear button to a `TextField`
/// and allows track its changes through the binding of `text`.
///
/// Inspired by [Hacking With Swift](https://www.hackingwithswift.com/forums/100-days-of-swift/adding-a-clear-button-to-a-textfield/12079/12086)
/// and then improved.
struct TextFieldClearButton: ViewModifier {
  var visibility: Visibility
  @FocusState private var focused
  @Binding var text: String
  
  func body(content: Content) -> some View {
    content
      .focused($focused)
      .overlay {
        switch visibility {
          case .hidden: EmptyView()
          case .automatic: clearButton.opacity(focused ? 1 : 0)
          case .visible: clearButton
        }
      }
      .animation(.smooth, value: focused)
  }
  
  private var clearButton: some View {
    HStack {
      Spacer()
      
      Button {
        text = ""
      } label: {
        Image(systemName: "multiply.circle.fill")
      }
      .foregroundColor(.secondary)
      .padding(.trailing, 4)
      .transition(.opacity)
    }
  }
}

extension TextField where Label == Text {
  /// Adds the modifier that displays the clear button overlayed on trailing.
  ///
  /// - Parameters:
  ///   - visibility: The visibility of the clear button. `automatic` by default.
  ///   - text: The text of the `TextField` it is applied to.
  /// - Returns: The text field with a clear button, based on the given `visibility`.
  func clearButtonVisibility(_ visibility: Visibility = .automatic, text: Binding<String>) -> some View {
    self.modifier(TextFieldClearButton(visibility: visibility, text: text))
  }
}
