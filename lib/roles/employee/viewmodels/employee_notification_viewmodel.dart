import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickboom_app/core/constants/app_config.dart';
import '../services/employee_api_service.dart';

class NotificationState {
  final bool isLoading;
  final List<Map<String, dynamic>> notifications;
  final int unreadCount;
  final String? errorMessage;

  const NotificationState({
    this.isLoading = false,
    this.notifications = const [],
    this.unreadCount = 0,
    this.errorMessage,
  });

  NotificationState copyWith({
    bool? isLoading,
    List<Map<String, dynamic>>? notifications,
    int? unreadCount,
    String? errorMessage,
  }) {
    return NotificationState(
      isLoading: isLoading ?? this.isLoading,
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class EmployeeNotificationNotifier extends Notifier<NotificationState> {
  @override
  NotificationState build() {
    Future.microtask(() => loadNotifications());
    return const NotificationState(isLoading: true);
  }

  EmployeeApiService get _service => ref.read(employeeApiServiceProvider);

  Future<void> loadNotifications() async {
    if (AppConfig.uiOnlyMode) {
      state = state.copyWith(
        isLoading: false,
        notifications: const [],
        unreadCount: 0,
      );
      return;
    }
    try {
      state = state.copyWith(isLoading: true);
      final list = await _service.getNotifications();
      final unread = list
          .where((n) => n['isRead'] == false || n['isUnread'] == true)
          .length;
      state = state.copyWith(
        isLoading: false,
        notifications: list,
        unreadCount: unread,
      );
    } catch (e) {
      debugPrint('[NOTIFICATION_NOTIFIER] loadNotifications error: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await _service.markNotificationAsRead(id);
      final updated = state.notifications.map((n) {
        if (n['id'].toString() == id) {
          final copy = Map<String, dynamic>.from(n);
          copy['isRead'] = true;
          copy['isUnread'] = false;
          return copy;
        }
        return n;
      }).toList();

      final unread = updated
          .where((n) => n['isRead'] == false || n['isUnread'] == true)
          .length;
      state = state.copyWith(notifications: updated, unreadCount: unread);
    } catch (e) {
      debugPrint('[NOTIFICATION_NOTIFIER] markAsRead error: $e');
    }
  }

  Future<void> deleteNotification(String id) async {
    try {
      await _service.deleteNotification(id);
      final updated = state.notifications
          .where((n) => n['id'].toString() != id)
          .toList();
      final unread = updated
          .where((n) => n['isRead'] == false || n['isUnread'] == true)
          .length;
      state = state.copyWith(notifications: updated, unreadCount: unread);
    } catch (e) {
      debugPrint('[NOTIFICATION_NOTIFIER] deleteNotification error: $e');
      rethrow;
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _service.markAllNotificationsAsRead();
      final updated = state.notifications.map((n) {
        final copy = Map<String, dynamic>.from(n);
        copy['isRead'] = true;
        copy['isUnread'] = false;
        return copy;
      }).toList();
      state = state.copyWith(notifications: updated, unreadCount: 0);
    } catch (e) {
      debugPrint('[NOTIFICATION_NOTIFIER] markAllAsRead error: $e');
    }
  }
}

final employeeNotificationProvider =
    NotifierProvider<EmployeeNotificationNotifier, NotificationState>(
      EmployeeNotificationNotifier.new,
    );
