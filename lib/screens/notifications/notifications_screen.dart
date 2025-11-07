import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../../services/theme_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _notifications = [];
  int _unreadCount = 0;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }
    
    try {
      final token = await StorageService.getToken();
      if (token == null) {
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      await _apiService.loadToken();
      
      final response = await _apiService.getNotifications();
      if (response['success']) {
        if (mounted) {
          setState(() {
            final data = response['data'] ?? {};
            _notifications = List<Map<String, dynamic>>.from(data['notifications'] ?? data ?? []);
            _unreadCount = data['unread_count'] is int
                ? data['unread_count']
                : int.tryParse('${data['unread_count']}') ?? 0;
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['error'] ?? 'Erro ao carregar notificações'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
      
    } catch (e) {
      if (mounted) {
        print('Erro ao carregar notificações: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      await _apiService.markNotificationAsRead(notificationId);
      if (!mounted) return;
      _loadNotifications();
    } catch (e) {
      print('Erro ao marcar notificação como lida: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        final isDark = themeService.isDarkMode;
        final backgroundColor = ThemeService.getBackgroundColor(isDark);
        final textColor = ThemeService.getTextColor(isDark);
        final badgeColor = isDark ? const Color(0xFFEF4444) : const Color(0xFFEF4444);

        return Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              'Notificações',
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            iconTheme: IconThemeData(color: textColor),
            actions: [
              if (_unreadCount > 0)
                Container(
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '$_unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: _notifications.isEmpty
                      ? _buildEmptyState(isDark)
                      : ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: _notifications.length,
                          itemBuilder: (context, index) {
                            final notification = _notifications[index];
                            return _buildNotificationCard(notification, isDark);
                          },
                        ),
                ),
        );
      },
    );
  }

  Widget _buildEmptyState(bool isDark) {
    final textColor = ThemeService.getTextColor(isDark);
    final secondary = ThemeService.getSecondaryTextColor(isDark);
    final iconColor = isDark ? Colors.white30 : const Color(0xFF252940);
    final circleColor = isDark
        ? Colors.white.withOpacity(0.05)
        : const Color(0xFF252940).withOpacity(0.05);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: circleColor,
                borderRadius: BorderRadius.circular(60),
              ),
              child: Icon(
                Icons.notifications_none,
                size: 60,
                color: iconColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Nenhuma notificação',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Você receberá notificações sobre\nnovos agendamentos e atualizações',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: secondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification, bool isDark) {
    final isRead = notification['is_read'] == true || notification['read'] == true;
    final type = notification['type'] as String?;
    final priority = notification['priority'] as String?;
    final textColor = ThemeService.getTextColor(isDark);
    final secondary = ThemeService.getSecondaryTextColor(isDark);
    final cardColor = isDark ? const Color(0xFF162031) : Colors.white;
    final tertiary = isDark ? Colors.white60 : const Color(0xFF6B7280);
    final borderColor = isRead
        ? (isDark ? Colors.white24 : const Color(0xFFE5E7EB))
        : _getNotificationColor(type, priority).withOpacity(isDark ? 0.6 : 0.2);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          if (!isRead) {
            _markAsRead(notification['id']);
          }
          _handleNotificationTap(notification);
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: borderColor,
              width: isRead ? 1 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.35 : 0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ícone da notificação
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getNotificationColor(type, priority).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getNotificationIcon(type),
                  color: _getNotificationColor(type, priority),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              
              // Conteúdo da notificação
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification['title'] ?? 'Notificação',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
                              color: textColor,
                            ),
                          ),
                        ),
                        if (!isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF252940),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      notification['message'] ?? '',
                      style: TextStyle(
                        fontSize: 14,
                        color: tertiary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: const Color(0xFF9CA3AF),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(notification['created_at']),
                          style: TextStyle(
                            fontSize: 12,
                            color: tertiary,
                          ),
                        ),
                        const Spacer(),
                        if (priority == 'high')
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Urgente',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFEF4444),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getNotificationIcon(String? type) {
    switch (type) {
      case 'new_booking':
        return Icons.calendar_today;
      case 'booking_confirmed':
        return Icons.check_circle;
      case 'booking_cancelled':
        return Icons.cancel;
      case 'payment_received':
        return Icons.payment;
      case 'system':
        return Icons.info;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String? type, String? priority) {
    if (priority == 'high') {
      return const Color(0xFFEF4444);
    }
    
    switch (type) {
      case 'new_booking':
        return const Color(0xFF3B82F6);
      case 'booking_confirmed':
        return const Color(0xFF10B981);
      case 'booking_cancelled':
        return const Color(0xFFEF4444);
      case 'payment_received':
        return const Color(0xFF10B981);
      case 'system':
        return const Color(0xFF6B7280);
      default:
        return const Color(0xFF252940);
    }
  }

  String _formatDate(String? date) {
    if (date == null) return 'Agora';
    
    try {
      final dateTime = DateTime.parse(date);
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inMinutes < 1) {
        return 'Agora';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m atrás';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h atrás';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d atrás';
      } else {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      }
    } catch (e) {
      return date;
    }
  }

  void _handleNotificationTap(Map<String, dynamic> notification) {
    final type = notification['type'] as String?;
    final data = notification['data'] as Map<String, dynamic>?;
    
    switch (type) {
      case 'new_booking':
      case 'booking_confirmed':
      case 'booking_cancelled':
        if (data?['booking_id'] != null) {
          // Navegar para detalhes do agendamento
          Navigator.pushNamed(
            context,
            '/booking-detail',
            arguments: {'id': data!['booking_id']},
          );
        }
        break;
      case 'payment_received':
        // Navegar para tela financeira
        Navigator.pushNamed(context, '/financial');
        break;
      default:
        // Não fazer nada para outros tipos
        break;
    }
  }
}
























