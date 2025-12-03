import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../providers/notification_provider.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../../services/theme_service.dart';
import '../../core/app_colors.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _notifications = [];
  int _unreadCount = 0;
  int _previousUnreadCount = 0;
  final ApiService _apiService = ApiService();
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = Provider.of<NotificationProvider>(context, listen: false);
      _previousUnreadCount = provider.unreadNotifications;
      provider.markProfileBadgeSeen();
    });
    _loadNotifications();
  }

  Future<void> _initializeNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(initSettings);
  }

  Future<void> _loadNotifications() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }
    
    try {
      final token = await StorageService.getToken();
      if (token == null) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      await _apiService.loadToken();
      
      final response = await _apiService.getNotifications();
      if (response['success']) {
        if (mounted) {
          setState(() {
            final data = response['data'] ?? {};
            final rawList = List<Map<String, dynamic>>.from(
              data['notifications'] ?? data ?? [],
            );
            _notifications = rawList.map(_normalizeNotification).toList();
            _unreadCount = data['unread_count'] is int
                ? data['unread_count']
                : int.tryParse('${data['unread_count']}') ?? 0;
          });
          if (mounted) {
            final provider = Provider.of<NotificationProvider>(context, listen: false);
            provider.setUnreadNotifications(_unreadCount, resetBadge: _unreadCount == 0);
            
            _previousUnreadCount = _unreadCount;
            
            // Verificar se há notificações de pagamento não lidas
            final hasUnreadPayments = provider.hasUnreadPaymentNotifications(_notifications);
            provider.setFinancialBadge(hasUnreadPayments, resetBadge: !hasUnreadPayments);
          }
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
    }
  }

  Future<void> _markAllAsRead() async {
    if (_notifications.isEmpty) return;

    try {
      final response = await _apiService.markAllNotificationsAsRead();
      if (!mounted) return;

      if (response['success'] == true) {
        await _loadNotifications();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Todas as notificações foram marcadas como lidas.'),
            backgroundColor: AppColors.primaryColor,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['error'] ?? 'Não foi possível atualizar as notificações'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
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
              TextButton.icon(
                onPressed: _notifications.isEmpty ? null : _markAllAsRead,
                icon: Icon(
                  Icons.done_all,
                  color: _notifications.isEmpty
                      ? ThemeService.getSecondaryTextColor(isDark)
                      : AppColors.primaryColor,
                ),
                label: Text(
                  'Ler tudo',
                  style: TextStyle(
                    color: _notifications.isEmpty
                        ? ThemeService.getSecondaryTextColor(isDark)
                        : AppColors.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
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
              const SizedBox(width: 4),
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
    final cardColor = isDark ? const Color(0xFF162031) : Colors.white;
    final tertiary = isDark ? Colors.white60 : const Color(0xFF6B7280);
    final borderColor = isRead
        ? (isDark ? Colors.white24 : const Color(0xFFE5E7EB))
        : _getNotificationColor(type, priority).withOpacity(isDark ? 0.6 : 0.2);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () async {
          if (!isRead) {
            await _markAsRead(notification['id']);
          }
          await _handleNotificationTap(notification);
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

  Future<void> _handleNotificationTap(Map<String, dynamic> notification) async {
    final type = (notification['type'] ?? '').toString();
    final data = notification['data'] is Map
        ? Map<String, dynamic>.from(notification['data'] as Map)
        : <String, dynamic>{};
    final bookingId = data['booking_id'] ?? notification['booking_id'];
    final vehicleId = data['vehicle_id'] ?? notification['vehicle_id'];
    final serviceId = data['service_id'] ?? notification['service_id'];
    final route = data['route']?.toString();

    if (route != null && route.isNotEmpty) {
      Navigator.pushNamed(context, route, arguments: data['payload']);
      return;
    }

    // Verificar se é notificação de agendamento/orçamento (por tipo ou título)
    final typeLower = type.toLowerCase();
    final title = (notification['title'] ?? '').toString().toLowerCase();
    final message = (notification['message'] ?? '').toString().toLowerCase();
    
    final isBookingRelated = typeLower.contains('booking') ||
        typeLower.contains('agendamento') ||
        typeLower.contains('orcamento') ||
        typeLower.contains('budget') ||
        typeLower.contains('quote') ||
        title.contains('agendamento') ||
        title.contains('orcamento') ||
        title.contains('orçamento') ||
        message.contains('agendamento') ||
        message.contains('orcamento') ||
        message.contains('orçamento');
    
    // Se for relacionado a agendamento e tiver booking_id, abrir detalhes
    if (isBookingRelated && bookingId != null) {
      await _openBookingDetail(bookingId.toString());
      return;
    }
    
    switch (type) {
      case 'new_booking':
      case 'booking_created':
      case 'booking_confirmed':
      case 'booking_cancelled':
      case 'booking_updated':
      case 'booking_approved':
      case 'budget_approved':
      case 'quote_approved':
      case 'orcamento_aprovado':
      case 'orçamento_aprovado':
        if (bookingId != null) {
          await _openBookingDetail(bookingId.toString());
        } else {
          Navigator.pushNamed(context, '/schedule');
        }
        break;
      case 'payment_received':
      case 'payment_confirmed':
      case 'pagamento_recebido':
      case 'pagamento_confirmado':
        Navigator.pushNamed(context, '/financial');
        break;
      case 'vehicle_update':
        if (vehicleId != null) {
          Navigator.pushNamed(context, '/vehicle-detail', arguments: {'id': vehicleId});
        }
        break;
      case 'service_update':
        if (serviceId != null) {
          Navigator.pushNamed(context, '/service-detail', arguments: {'id': serviceId});
        }
        break;
      case 'agenda_reminder':
      case 'schedule_update':
        Navigator.pushNamed(context, '/schedule');
        break;
      case 'profile_alert':
      case 'bank_account_required':
        Navigator.pushNamed(context, '/profile');
        break;
      default:
        // Se não identificou o tipo mas tem booking_id, tentar abrir detalhes
        if (bookingId != null) {
          await _openBookingDetail(bookingId.toString());
        } else {
          Navigator.pushNamed(context, '/home');
        }
        break;
    }
  }

  Future<void> _openBookingDetail(String bookingId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final response = await _apiService.getBookingById(bookingId);

    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();

    if (response['success'] == true && response['data'] != null) {
      await Navigator.pushNamed(
        context,
        '/booking-detail',
        arguments: Map<String, dynamic>.from(response['data'] as Map),
      );
      _loadNotifications();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['error']?.toString() ?? 'Não foi possível abrir o agendamento.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Map<String, dynamic> _normalizeNotification(Map<String, dynamic> notification) {
    final normalized = Map<String, dynamic>.from(notification);
    normalized['data'] = _decodeNotificationData(notification['data']);
    return normalized;
  }

  Map<String, dynamic> _decodeNotificationData(dynamic raw) {
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    if (raw is String && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
      } catch (_) {
        return {'raw': raw};
      }
    }
    return <String, dynamic>{};
  }
}
