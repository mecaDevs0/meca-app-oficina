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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final provider = Provider.of<NotificationProvider>(context, listen: false);
      _previousUnreadCount = provider.unreadNotifications;
      provider.markProfileBadgeSeen();
      // Marcar todas como lidas na API ANTES de carregar, para persistir e garantir estado correto ao reabrir o app
      await _markAllAsReadSilently();
      if (!mounted) return;
      _loadNotifications();
    });
  }

  // Marcar todas como lidas silenciosamente (sem mostrar mensagem)
  Future<void> _markAllAsReadSilently() async {
    try {
      final response = await _apiService.markAllNotificationsAsRead();
      if (response['success'] == true && mounted) {
        // Marcar notificações locais como lidas
        final updatedNotifications = _notifications.map((n) {
          return Map<String, dynamic>.from(n)
            ..['is_read'] = true
            ..['read'] = true;
        }).toList();
        
        // Atualizar estado local
        setState(() {
          _notifications = updatedNotifications;
          _unreadCount = 0;
        });
        
        // Atualizar provider imediatamente
        final provider = Provider.of<NotificationProvider>(context, listen: false);
        provider.setNotifications(updatedNotifications);
        provider.setUnreadNotifications(0, resetBadge: true);
        
        // NÃO recarregar do servidor
      }
    } catch (e) {
      // Silenciar erros - não mostrar mensagem ao usuário
      print('Erro ao marcar notificações como lidas: $e');
    }
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
          final data = response['data'] ?? {};
          final rawList = List<Map<String, dynamic>>.from(
            data['notifications'] ?? data ?? [],
          );
          final normalizedNotifications = rawList.map(_normalizeNotification).toList();
          final unreadCount = data['unread_count'] is int
              ? data['unread_count']
              : int.tryParse('${data['unread_count']}') ?? 0;
          
          setState(() {
            _notifications = normalizedNotifications;
            _unreadCount = unreadCount;
          });
          
          if (mounted) {
            final provider = Provider.of<NotificationProvider>(context, listen: false);
            
            // Usar setNotifications para manter lista no provider
            provider.setNotifications(normalizedNotifications);
            
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
        final provider = Provider.of<NotificationProvider>(context, listen: false);
        
        // PRIMEIRO: Marcar todas as notificações locais como lidas IMEDIATAMENTE
        final updatedNotifications = _notifications.map((n) {
          return Map<String, dynamic>.from(n)
            ..['is_read'] = true
            ..['read'] = true;
        }).toList();
        
        // Atualizar estado local
        setState(() {
          _notifications = updatedNotifications;
          _unreadCount = 0;
        });
        
        // Atualizar provider
        provider.setNotifications(updatedNotifications);
        provider.setUnreadNotifications(0, resetBadge: true);
        
        // NÃO recarregar do servidor! Mantém estado local.
        // Sincronização acontecerá quando usuário reabrir a tela
        
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
                            return _buildNotificationCard(notification, isDark, index);
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

  Widget _buildNotificationCard(Map<String, dynamic> notification, bool isDark, int index) {
    final isRead = notification['is_read'] == true || notification['read'] == true;
    final type = notification['type'] as String?;
    final priority = notification['priority'] as String?;
    final textColor = ThemeService.getTextColor(isDark);
    final cardColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final tertiaryColor = isDark ? Colors.white60 : const Color(0xFF6B7280);
    final notifColor = _getNotificationColor(type, priority);

    final card = Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () async {
          if (!isRead) {
            await _markAsRead(notification['id']);
          }
          await _handleNotificationTap(notification);
        },
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.white10 : const Color(0xFFE5E7EB),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.25 : 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon in colored circle — 40px
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: notifColor.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getNotificationIcon(type),
                      color: notifColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          notification['title'] ?? 'Notificação',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isRead ? FontWeight.w500 : FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Message — max 2 lines
                        Text(
                          notification['message'] ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: tertiaryColor,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Footer row: priority badge left, timestamp right
                        Row(
                          children: [
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
                            const Spacer(),
                            Text(
                              _formatDate(notification['created_at']),
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
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

            // Unread green dot — top-right
            if (!isRead)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF00C977),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    // FadeIn animation with staggered delay
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 50).clamp(0, 500)),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 12 * (1 - value)),
            child: child,
          ),
        );
      },
      child: card,
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
        return const Color(0xFF00C977);
      case 'booking_cancelled':
        return const Color(0xFFEF4444);
      case 'payment_received':
        return const Color(0xFF10B981);
      case 'system':
        return const Color(0xFF6B7280);
      default:
        return const Color(0xFF6B7280);
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
    final preCompraId = data['pre_compra_id'] ?? data['id'] ?? notification['pre_compra_id'];
    final vehicleId = data['vehicle_id'] ?? notification['vehicle_id'];
    final serviceId = data['service_id'] ?? notification['service_id'];
    final route = data['route']?.toString();

    if (route != null && route.isNotEmpty) {
      Navigator.pushNamed(context, route, arguments: data['payload']);
      return;
    }

    final typeLower = type.toLowerCase();
    final title = (notification['title'] ?? '').toString().toLowerCase();
    final message = (notification['message'] ?? '').toString().toLowerCase();

    // Verificar se é notificação de conta bancária / pagamento falhado
    final isBankAccountRelated =
        typeLower.contains('bank_account') ||
        title.contains('conta de recebimentos') ||
        title.contains('dados bancários') ||
        title.contains('dados bancarios') ||
        title.contains('cliente tentou pagar') ||
        message.contains('conta de recebimentos') ||
        message.contains('não está configurada') ||
        message.contains('configurações → dados bancários');
    if (isBankAccountRelated) {
      Navigator.pushNamed(context, '/config/banking');
      return;
    }

    // Verificar se é notificação de pré-compra
    final isPreCompraRelated = typeLower.contains('pre_compra') ||
        typeLower.contains('pre-compra') ||
        typeLower.contains('precompra') ||
        typeLower.contains('laudo') ||
        title.contains('pré-compra') ||
        title.contains('pre-compra') ||
        title.contains('laudo') ||
        message.contains('pré-compra') ||
        message.contains('laudo');

    if (isPreCompraRelated && preCompraId != null) {
      await _openPreCompraDetail(preCompraId.toString());
      return;
    }

    // Verificar se é notificação de agendamento/orçamento (por tipo ou título)
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
      case 'pre_compra':
      case 'pre_compra_created':
      case 'pre_compra_confirmed':
      case 'pre_compra_started':
      case 'pre_compra_cancelled':
      case 'pre_compra_concluido':
      case 'laudo_submitted':
        if (preCompraId != null) {
          await _openPreCompraDetail(preCompraId.toString());
        } else {
          Navigator.pushNamed(context, '/schedule');
        }
        break;
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
        // Se não identificou o tipo mas tem pre_compra_id, abrir detalhe pré-compra
        if (preCompraId != null) {
          await _openPreCompraDetail(preCompraId.toString());
        } else if (bookingId != null) {
          await _openBookingDetail(bookingId.toString());
        } else {
          // Voltar para a tela anterior (não navegar para /home que fica sem bottom bar)
          Navigator.pop(context);
        }
        break;
    }
  }

  Future<void> _openPreCompraDetail(String preCompraId) async {
    await Navigator.pushNamed(
      context,
      '/pre-compra-detail',
      arguments: {'id': preCompraId},
    );
    _loadNotifications();
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
