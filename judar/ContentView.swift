import SwiftUI
import SwiftData

// Root coordinator: creates BattleViewModel once modelContext is available, then hands off to BattleView.
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var battleVM: BattleViewModel?

    var body: some View {
        Group {
            if let vm = battleVM {
                BattleView()
                    .environment(vm)
            } else {
                Color.black.ignoresSafeArea()
                    .onAppear {
                        battleVM = BattleViewModel(modelContext: modelContext)
                    }
            }
        }
    }
}
