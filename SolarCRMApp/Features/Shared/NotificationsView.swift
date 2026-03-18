import SwiftUI

struct NotificationsView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationStack {
            List {
                ForEach(appState.notifications) { notification in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(notification.title)
                                .font(.headline)
                            Spacer()
                            if !notification.isRead {
                                Circle()
                                    .fill(.blue)
                                    .frame(width: 10, height: 10)
                            }
                        }
                        Text(notification.message)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(notification.createdAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        Task { await appState.markNotificationRead(notification) }
                    }
                }
            }
            .navigationTitle("Notifications")
        }
    }
}
