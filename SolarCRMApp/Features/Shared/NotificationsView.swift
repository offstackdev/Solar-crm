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
            AppScreen(title: "Notifications") {
                if unread.isEmpty && read.isEmpty {
                    EmptyStateView(title: "No notifications", message: "Reminder requests, assignment changes, and lead updates will appear here.", systemImage: "bell.slash")
                }

                if !unread.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        AppSectionHeader("Unread")
                        ForEach(unread) { notification in
                            NotificationRow(notification: notification)
                        }
                    }
                }

                if !read.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        AppSectionHeader("Earlier")
                        ForEach(read) { notification in
                            NotificationRow(notification: notification)
                        }
                    }
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private struct NotificationRow: View {
    @EnvironmentObject private var appState: AppState
    let notification: AppNotification

    var body: some View {
        AppOutlinedSurface {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: notification.kind.symbolName)
                    .font(.headline)
                    .foregroundStyle(notification.isRead ? AppTheme.onSurfaceVariant : AppTheme.primary)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(notification.title)
                            .font(.headline.weight(.bold))
                            .foregroundStyle(AppTheme.onSurface)
                        Spacer()
                        if !notification.isRead {
                            Circle()
                                .fill(AppTheme.primary)
                                .frame(width: 10, height: 10)
                        }
                    }
                    Text(notification.message)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.onSurfaceVariant)
                    Text(notification.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(AppTheme.onSurfaceVariant.opacity(0.7))
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            Task { await appState.markNotificationRead(notification) }
        }
    }
}
