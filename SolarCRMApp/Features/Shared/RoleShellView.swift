import SwiftUI

struct RoleShellView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        switch appState.currentUser?.role {
        case .doorKnocker:
            DoorKnockerTabView()
        case .closer:
            CloserTabView()
        case .manager:
            ManagerTabView()
        case .none:
            LoginView()
        }
    }
}
