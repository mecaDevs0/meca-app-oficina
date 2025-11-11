import 'package:flutter/foundation.dart';

class NotificationProvider extends ChangeNotifier {
  int _unreadNotifications = 0;
  bool _showProfileBadge = false;
  int _pendingBookings = 0;
  bool _showAgendaBadge = false;

  int get unreadNotifications => _unreadNotifications;
  bool get showProfileBadge => _showProfileBadge;
  int get pendingBookings => _pendingBookings;
  bool get showAgendaBadge => _showAgendaBadge;

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
}

