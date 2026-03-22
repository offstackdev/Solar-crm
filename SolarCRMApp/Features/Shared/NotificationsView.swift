import SwiftUI

struct NotificationsView: View {
    @EnvironmentObject private var appState: AppState

    private var unread: [AppNotification] {
        appState.notifications.filter { !$0.isRead }
    }

    private var read: [AppNotification] {
        appState.notifications.filter { $0.isRead }
    }

    var body: some View {
        NavigationStack {
            List {
                if unread.isEmpty && read.isEmpty {
                    EmptyStateView(title: "No notifications", message: "Reminder requests, assignment changes, and lead updates will appear here.", systemImage: "bell.slash")
                        .listRowSeparator(.hidden)
                }

                if !unread.isEmpty {
                    Section("Unread") {
                        ForEach(unread) { notification in
                            NotificationRow(notification: notification)
                        }
                    }
                }

                if !read.isEmpty {
                    Section("Earlier") {
                        ForEach(read) { notification in
                            NotificationRow(notification: notification)
                        }
                    }
                }
            }
            .navigationTitle("Notifications")
        }
    }
}

private struct NotificationRow: View {
    @EnvironmentObject private var appState: AppState
    let notification: AppNotification

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: notification.kind.symbolName)
                .font(.headline)
                .foregroundStyle(notification.isRead ? Color.secondary : Color.blue)
                .frame(width: 24)

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
        }
        .contentShape(Rectangle())
        .onTapGesture {
            Task { await appState.markNotificationRead(notification) }
        }
    }
}
