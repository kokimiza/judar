import SwiftUI

// Retained for compile compatibility — profile setup was removed.
struct ProfileEditView: View {
    let onComplete: () -> Void
    var body: some View { EmptyView().onAppear { onComplete() } }
}
