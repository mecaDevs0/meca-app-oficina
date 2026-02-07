import 'package:flutter/foundation.dart';

class NotificationProvider extends ChangeNotifier {
  int _unreadNotifications = 0;
  bool _showProfileBadge = false;
  int _pendingBookings = 0;
  bool _showAgendaBadge = false;
  bool _showFinancialBadge = false;
  List<Map<String, dynamic>> _notifications = [];

  int get unreadNotifications => _unreadNotifications;
  bool get showProfileBadge => _showProfileBadge;
  int get pendingBookings => _pendingBookings;
  bool get showAgendaBadge => _showAgendaBadge;
  bool get showFinancialBadge => _showFinancialBadge;
  List<Map<String, dynamic>> get notifications => _notifications;

  void setUnreadNotifications(int count, {bool resetBadge = false}) {
    final normalized = count.clamp(0, 9999).toInt();
    _unreadNotifications = normalized;
    if (!resetBadge) {
      _showProfileBadge = normalized > 0;
    } else if (normalized == 0) {
      _showProfileBadge = false;
    }
    notifyListeners();
  }
  
  void setNotifications(List<Map<String, dynamic>> notifications) {
    _notifications = notifications.map((n) => Map<String, dynamic>.from(n)).toList();
    final unread = _countUnread(notifications).clamp(0, 9999);
    _unreadNotifications = unread;
    _showProfileBadge = unread > 0;
    notifyListeners();
  }

  void markProfileBadgeSeen() {
    if (_showProfileBadge) {
      _showProfileBadge = false;
      notifyListeners();
    }
  }

  void setPendingBookingsCount(int count, {bool resetBadge = false}) {
    final normalized = count.clamp(0, 9999).toInt();
    _pendingBookings = normalized;
    if (!resetBadge) {
      _showAgendaBadge = normalized > 0;
    } else if (normalized == 0) {
      _showAgendaBadge = false;
    }
    notifyListeners();
  }

  void markAgendaBadgeSeen() {
    if (_showAgendaBadge) {
      _showAgendaBadge = false;
      notifyListeners();
    }
  }

  void setFinancialBadge(bool show, {bool resetBadge = false}) {
    if (!resetBadge) {
      _showFinancialBadge = show;
    } else if (!show) {
      _showFinancialBadge = false;
    }
    notifyListeners();
  }

  void markFinancialBadgeSeen() {
    if (_showFinancialBadge) {
      _showFinancialBadge = false;
      notifyListeners();
    }
  }

  // Verificar se há notificações de pagamento não lidas
  bool hasUnreadPaymentNotifications(List<Map<String, dynamic>> notifications) {
    for (final notification in notifications) {
      final isRead = notification['read'] == true || notification['is_read'] == true;
      if (isRead) continue;

      final type = (notification['type'] ?? '').toString().toLowerCase();
      final title = (notification['title'] ?? '').toString().toLowerCase();
      final message = (notification['message'] ?? '').toString().toLowerCase();

      final bool paymentKeyword = type.contains('payment') ||
          type.contains('pagamento') ||
          title.contains('pagamento') ||
          title.contains('recebido') ||
          title.contains('payment') ||
          message.contains('pagamento') ||
          message.contains('recebido') ||
          message.contains('payment');

      if (paymentKeyword) {
        return true;
      }
    }
    return false;
  }
  
  static int _countUnread(List<Map<String, dynamic>> notifications) {
    int count = 0;
    for (final notification in notifications) {
      final isRead = notification['read'] == true || notification['is_read'] == true;
      if (!isRead) count++;
    }
    return count;
  }
}

