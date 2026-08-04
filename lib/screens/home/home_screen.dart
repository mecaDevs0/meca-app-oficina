import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../config/app_config.dart';
import '../../providers/notification_provider.dart';
import '../../services/api_service.dart';
import '../../services/theme_service.dart';
import '../../widgets/beautiful_error_snackbar.dart';
import '../../utils/date_formatter.dart';
import '../../utils/page_transitions.dart';
import '../asaas/identity_verification_screen.dart';
import '../config/agenda_config_screen.dart';
import '../config/services_config_screen.dart';
import '../core/core_screen.dart';

/// Banner âmbar exibido quando oficina não tem conta de recebimento Asaas configurada.
class AsaasPendingBanner extends StatelessWidget {
  final bool isDark;
  final VoidCallback onConfigure;

  const AsaasPendingBanner({
    super.key,
    required this.isDark,
    required this.onConfigure,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF3A2A08), const Color(0xFF241B08)]
              : [const Color(0xFFFFF6D8), const Color(0xFFFFFBEA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0A100).withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0A100).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.account_balance_wallet, color: Color(0xFFE0A100), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Ative seus recebimentos!',
                  style: TextStyle(
                    color: isDark ? const Color(0xFFFFF4D6) : const Color(0xFF6B4D00),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Preencha dados bancários e data de nascimento para começar a receber pagamentos.',
            style: TextStyle(
              color: isDark ? const Color(0xFFF2DFC0) : const Color(0xFF7A5A11),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onConfigure,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE0A100),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('Configurar agora', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  // 0 = Em Andamento, 1 = Próximos, 2 = Histórico
  int _selectedTab = 0;
  List<Map<String, dynamic>> _inProgressBookings = [];
  List<Map<String, dynamic>> _upcomingBookings = [];
  List<Map<String, dynamic>> _historyBookings = [];
  Map<String, dynamic>? _workshopData;
  final ApiService _apiService = ApiService();
  
  // Variáveis para controle de configuração
  bool _isAgendaInvalid = false;
  bool _isServiceInvalid = false;
  bool _isLogoMissing = false;
  bool _missingAsaasWallet = false;
  bool _asaasNeedsVerification = false;
  int _activeBookingsCount = 0; // Contador de serviços em andamento

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    const timeout = Duration(seconds: AppConfig.homeLoadTimeoutSeconds);
    Future<Map<String, dynamic>> _timeout(String name, Future<Map<String, dynamic>> f) {
      return f.timeout(timeout, onTimeout: () {
        print('⚠️ Timeout ao carregar $name');
        return {'success': false, 'error': 'Timeout'};
      });
    }

    try {
      final futureNotif = _timeout('notificações', _apiService.getNotifications());
      final futureProfile = _timeout('perfil', _apiService.getProfile());
      final futureSchedule = _timeout('agenda', _apiService.getSchedule());
      final futureServices = _timeout('serviços', _apiService.getMyServices());
      final futureBookings = _timeout('agendamentos', _apiService.getMyBookings());

      final results = await Future.wait([
        futureNotif,
        futureProfile,
        futureSchedule,
        futureServices,
        futureBookings,
      ]);

      if (!mounted) return;
      final notificationsResponse = results[0];
      final profileResponse = results[1];
      final scheduleResponse = results[2];
      final servicesResponse = results[3];
      final bookingsResponse = results[4];

      try {
        if (notificationsResponse['success'] && mounted) {
          final data = notificationsResponse['data'] ?? {};
          final rawList = List<Map<String, dynamic>>.from(
            data['notifications'] ?? data ?? [],
          );
          final normalizedNotifications = rawList.map((notif) {
            return Map<String, dynamic>.from(notif);
          }).toList();
          
          final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
          
          // PROTEÇÃO: Se usuário já marcou como lidas (contador = 0), NÃO sobrescrever
          if (notificationProvider.unreadNotifications == 0 && notificationProvider.notifications.isNotEmpty) {
            print('🔒 [Home] Mantendo notificações locais (já marcadas como lidas)');
          } else {
            // Atualizar com dados do servidor
            notificationProvider.setNotifications(normalizedNotifications);
          }
        }
      } catch (e) {
        print('⚠️ Erro ao processar notificações: $e');
      }

      if (profileResponse['success']) {
        setState(() => _workshopData = profileResponse['data']);
        final workshop = profileResponse['data'] is Map ? (profileResponse['data'] as Map) : {};
        final walletId = (workshop['asaas_wallet_id'] as String? ?? '').toString().trim();
        final asaasStatus = (workshop['asaas_status'] ?? '').toString().trim().toUpperCase();
        final logoUrl = (workshop['logo_url'] ?? workshop['logo'] ?? '').toString().trim();
        setState(() {
          _missingAsaasWallet = walletId.isEmpty;
          _asaasNeedsVerification = walletId.isNotEmpty && asaasStatus != 'APPROVED' && asaasStatus != 'ACTIVE';
          _isLogoMissing = logoUrl.isEmpty;
        });
      }

      bool hasSchedule = false;
      try {
        if (scheduleResponse['success']) {
          // Preferir o flag `configured` do backend (source of truth).
          // Fallback: heurística antiga para compat com API sem o flag.
          if (scheduleResponse.containsKey('configured')) {
            hasSchedule = scheduleResponse['configured'] == true;
          } else if (scheduleResponse['data'] is Map) {
            final raw = scheduleResponse['data'];
            // backend novo pode aninhar: { data: { data: {...}, configured: bool } }
            if (raw['configured'] is bool) {
              hasSchedule = raw['configured'] == true;
            } else {
              final Map scheduleData = raw is Map ? raw : {};
              hasSchedule = scheduleData.entries.any((entry) {
                final dayData = entry.value;
                return dayData is Map && dayData['is_open'] == true;
              });
            }
          }
        }
      } catch (e) {
        print('⚠️ Erro ao processar agenda: $e');
      }

      bool hasServices = false;
      try {
        if (servicesResponse['success'] && servicesResponse['data'] != null) {
          final servicesData = servicesResponse['data'];
          final servicesList = servicesData is Map
              ? (servicesData['services'] ?? [])
              : (servicesData is List ? servicesData : []);
          hasServices = servicesList.isNotEmpty;
        }
      } catch (e) {
        print('⚠️ Erro ao processar serviços: $e');
      }

      setState(() {
        _isAgendaInvalid = !hasSchedule;
        _isServiceInvalid = !hasServices;
      });

      try {
        if (bookingsResponse['success']) {
          final data = bookingsResponse['data'];
          final bookingsList = data is Map ? (data['bookings'] ?? []) : data ?? [];
          final bookings = List<Map<String, dynamic>>.from(bookingsList);
          final pendingCount = bookings.where((b) {
            final status = (b['status'] ?? '').toString().toLowerCase();
            return status == 'pending' ||
                status == 'pendente_oficina' ||
                status == 'pending_oficina';
          }).length;

          final inProgress = bookings.where((b) {
            final status = (b['status'] ?? '').toString().toLowerCase();
            return status == 'em_andamento' ||
                status == 'in_progress' ||
                status == 'started';
          }).toList()
            ..sort(
              (a, b) => (a['sort_timestamp'] ?? 0).compareTo(b['sort_timestamp'] ?? 0),
            );

          final upcoming = bookings.where((b) {
            final status = (b['status'] ?? '').toString().toLowerCase();
            return status == 'pending' ||
                status == 'pendente_oficina' ||
                status == 'confirmed' ||
                status == 'confirmado';
          }).toList()
            ..sort(
              (a, b) => (a['sort_timestamp'] ?? 0).compareTo(b['sort_timestamp'] ?? 0),
            );

          final history = bookings.where((b) {
            final status = (b['status'] ?? '').toString().toLowerCase();
            return status == 'completed' ||
                status == 'finished' ||
                status == 'concluido' ||
                status == 'concluído' ||
                status == 'pago';
          }).toList()
            ..sort(
              (a, b) => (b['sort_timestamp'] ?? 0).compareTo(a['sort_timestamp'] ?? 0),
            );

          setState(() {
            _inProgressBookings = inProgress;
            _upcomingBookings = upcoming;
            _historyBookings = history;
            _activeBookingsCount = inProgress.length;
          });
          if (mounted) {
            final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
            notificationProvider.setPendingBookingsCount(pendingCount, resetBadge: pendingCount == 0);
          }
        }
      } catch (e) {
        print('⚠️ Erro ao carregar agendamentos: $e');
      }
      
    } catch (e) {
      if (mounted) {
        final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
        notificationProvider.setPendingBookingsCount(0, resetBadge: true);
      }
    } finally {
      setState(() => _isLoading = false);
    }

    // Background sync: refresh Asaas status from API (force) so home banners stay current
    _syncAsaasStatusInBackground();
  }

  Future<void> _syncAsaasStatusInBackground() async {
    try {
      final workshopId = _workshopData?['id']?.toString();
      final walletId = (_workshopData?['asaas_wallet_id'] ?? '').toString().trim();
      if (workshopId == null || walletId.isEmpty) return;

      final response = await _apiService.getAsaasStatus(workshopId, force: true);
      if (!mounted || response['success'] != true) return;

      final newStatus = (response['data']?['asaas_status'] ?? '').toString().trim().toUpperCase();
      if (newStatus.isEmpty) return;

      setState(() {
        _asaasNeedsVerification = newStatus != 'APPROVED' && newStatus != 'ACTIVE';
      });
    } catch (_) {
      // Silent — don't disrupt home experience
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        final isDark = themeService.isDarkMode;
        final bgColor = isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF5F7FA);
        
        return Scaffold(
          backgroundColor: bgColor,
          body: SafeArea(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isDark ? const Color(0xFF00C977) : const Color(0xFF00C977),
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                          child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header com logo
                            _buildHeader(isDark, constraints.maxWidth),

                            const SizedBox(height: 20),

                            // Componente de 3 colunas (estatísticas)
                            _buildStatsCard(isDark),

                            if (_missingAsaasWallet) ...[
                              const SizedBox(height: 16),
                              AsaasPendingBanner(
                                isDark: isDark,
                                onConfigure: () async {
                                  await Navigator.pushNamed(context, '/config/banking');
                                  if (mounted) _loadData();
                                },
                              ),
                            ],
                            if (_asaasNeedsVerification) ...[
                              const SizedBox(height: 16),
                              _buildVerificationBanner(isDark),
                            ],

                            const SizedBox(height: 20),

                            // Card promocional do Dashboard Web
                            _buildDashboardPromoCard(isDark),

                            const SizedBox(height: 24),

                            // Configuração necessária (Agenda e Serviços)
                            if (_isAgendaInvalid || _isServiceInvalid || _isLogoMissing) ...[
                              const SizedBox(height: 20),
                              _buildConfigNeededSection(isDark),
                              const SizedBox(height: 24),
                            ],
                            
                            // Componente de agendamentos
                            _buildAppointmentsSection(isDark),
                          ],
                          ),
                        );
                      },
                    ),
                  ),
            ),
        );
      },
    );
  }

  Widget _buildVerificationBanner(bool isDark) {
    final bgColor = isDark ? const Color(0xFF1A2A20).withOpacity(0.9) : const Color(0xFFE8FFF3);
    final textColor = isDark ? Colors.white : const Color(0xFF1A5C3A);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF00C977).withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_user_outlined, color: Color(0xFF00C977), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Complete a verificação de identidade para ativar sua conta e receber pagamentos.',
              style: TextStyle(color: textColor, fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const IdentityVerificationScreen()),
              );
              if (mounted) _loadData();
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              foregroundColor: const Color(0xFF00C977),
            ),
            child: const Text('Verificar', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark, double maxWidth) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo MECA
          SizedBox(
            width: 52,
            height: 52,
            child: Image.asset(
              'assets/logos/icone_verde.png',
              width: 52,
              height: 52,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C977),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      'MECA',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Bem-vindo de volta!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _workshopData?['name'] ?? 'Oficina MECA',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF00C977),
                    height: 1.3,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardPromoCard(bool isDark) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF0D3B2A), const Color(0xFF1A1A2E)]
              : [const Color(0xFFE8FFF3), const Color(0xFFE0F4FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00C977).withOpacity(isDark ? 0.3 : 0.2),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Clipboard.setData(const ClipboardData(text: 'https://dashboard.mecabr.com'));
            BeautifulErrorSnackbar.showSuccess(context, 'Link copiado!');
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C977).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.desktop_mac_outlined,
                    color: Color(0xFF00C977),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Gerencie sua oficina pelo computador',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C977),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.copy_rounded, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Copiar',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Coluna 1: Em Andamento
            Expanded(
              child: _buildStatColumn(
                icon: Icons.build_circle_outlined,
                value: '$_activeBookingsCount',
                label: 'Em Andamento',
                color: const Color(0xFF3B82F6),
                isDark: isDark,
              ),
            ),
            VerticalDivider(
              width: 24,
              thickness: 1,
              color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08),
            ),
            // Coluna 2: Histórico
            Expanded(
              child: _buildStatColumn(
                icon: Icons.history_outlined,
                value: '${_historyBookings.length}',
                label: 'Histórico',
                color: const Color(0xFFF59E0B),
                isDark: isDark,
              ),
            ),
            VerticalDivider(
              width: 24,
              thickness: 1,
              color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08),
            ),
            // Coluna 3: Próximos (confirmados)
            Expanded(
              child: _buildStatColumn(
                icon: Icons.calendar_today_outlined,
                value: '${_upcomingBookings.length}',
                label: 'Próximos',
                color: const Color(0xFF00C977),
                isDark: isDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required bool isDark,
  }) {
    final iconBg = color.withOpacity(isDark ? 0.18 : 0.12);
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 10),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildConfigNeededSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Configuração Necessária',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        // 1. Agenda (primeiro)
        if (_isAgendaInvalid)
          _buildConfigCard(
            title: 'Configurar Agenda',
            description: 'Defina seus horários de atendimento',
            icon: Icons.access_time_outlined,
            iconColor: const Color(0xFF9333EA),
            bgColor: isDark ? const Color(0xFF3D1F5D) : const Color(0xFFF3E8FF),
            onTap: () async {
              final result = await Navigator.push(
                context,
                PageTransitions.slideFromRight(const AgendaConfigScreen()),
              );
              // Recarregar dados se salvou com sucesso
              if (result == true) {
                _loadData();
              }
            },
            isDark: isDark,
          ),
        if (_isAgendaInvalid) const SizedBox(height: 12),
        // 2. Serviços (segundo)
        if (_isServiceInvalid)
          _buildConfigCard(
            title: 'Serviços',
            description: 'Selecione os serviços que você oferece',
            icon: Icons.build_outlined,
            iconColor: const Color(0xFFF59E0B),
            bgColor: isDark ? const Color(0xFF5D3A1F) : const Color(0xFFFEF3C7),
            onTap: () async {
              final result = await Navigator.push(
                context,
                PageTransitions.slideFromRight(ServicesConfigScreen()),
              );
              // Recarregar dados se salvou com sucesso
              if (result == true) {
                _loadData();
              }
            },
            isDark: isDark,
          ),
        if (_isServiceInvalid && _isLogoMissing) const SizedBox(height: 12),
        // 3. Logo (opcional, mas recomendado)
        if (_isLogoMissing)
          _buildConfigCard(
            title: 'Adicionar logo da oficina',
            description: 'Uma logo ajuda os clientes a reconhecerem sua oficina',
            icon: Icons.image_outlined,
            iconColor: const Color(0xFF00C977),
            bgColor: isDark ? const Color(0xFF0D3B2A) : const Color(0xFFE8FFF3),
            onTap: () {
              CoreScreen.navigateToTab(context, 3); // Profile tab
            },
            isDark: isDark,
          ),
      ],
    );
  }

  Widget _buildConfigCard({
    required String title,
    required String description,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentsSection(bool isDark) {
    final tabs = [
      (label: 'Em Andamento', icon: Icons.build_circle_outlined, count: _inProgressBookings.length),
      (label: 'Próximos', icon: Icons.calendar_today_outlined, count: _upcomingBookings.length),
    ];

    List<Map<String, dynamic>> activeList() {
      if (_selectedTab == 0) return _inProgressBookings;
      return _upcomingBookings;
    }

    String emptyMessage() {
      if (_selectedTab == 0) return 'Nenhum serviço em andamento';
      return 'Nenhum agendamento próximo';
    }

    String emptySubtitle() {
      if (_selectedTab == 0) return 'Serviços iniciados aparecerão aqui';
      return 'Seus próximos agendamentos confirmados aparecerão aqui';
    }

    IconData emptyIcon() {
      if (_selectedTab == 0) return Icons.play_circle_outline;
      return Icons.calendar_today_outlined;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Agendamentos',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A1A) : Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: List.generate(tabs.length, (i) {
              final tab = tabs[i];
              return Expanded(
                child: _buildSegmentButton(
                  label: '${tab.label} (${tab.count})',
                  icon: tab.icon,
                  isSelected: _selectedTab == i,
                  isDark: isDark,
                  onTap: () => setState(() => _selectedTab = i),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 16),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 0.1),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              ),
            );
          },
          child: activeList().isEmpty
              ? Container(
                  key: ValueKey('empty-$_selectedTab'),
                  width: double.infinity,
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        emptyIcon(),
                        size: 48,
                        color: isDark ? Colors.grey[600] : Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        emptyMessage(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        emptySubtitle(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  key: ValueKey('list-$_selectedTab'),
                  children: activeList()
                      .take(5)
                      .map((booking) => _buildBookingCard(booking, isDark))
                      .toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildSegmentButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF00C977) : const Color(0xFF00C977))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.grey[400] : Colors.grey[600]),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.grey[400] : Colors.grey[600]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking, bool isDark) {
    final customerName = (booking['customer_name'] ?? 'Cliente MECA').toString();
    final vehicleLabel = (booking['vehicle_display'] ??
            '${booking['vehicle_brand'] ?? ''} ${booking['vehicle_model'] ?? ''}')
        .toString()
        .trim();
    final serviceName = (booking['service_name'] ?? 'Serviço').toString();
    final notes = (booking['customer_notes'] ?? '').toString().trim();
    final attachments = booking['customer_uploads'] is List
        ? (booking['customer_uploads'] as List).length
        : 0;
    final appointment = _parseDate(booking['appointment_date'] ?? booking['scheduled_date']);
    final humanDate = appointment != null ? humanizeBookingDate(appointment) : 'Data não definida';
    final initials = customerName.trim().isNotEmpty
        ? customerName.trim().substring(0, 1).toUpperCase()
        : 'C';
    final secondaryText = isDark ? Colors.white60 : const Color(0xFF6B7280);

    final boxDecoration = BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [const Color(0xFF111827), const Color(0xFF0F172A)]
            : [Colors.white, Colors.white],
      ),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE5E7EB),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: isDark
              ? Colors.black.withOpacity(0.45)
              : const Color(0xFF00C977).withOpacity(0.08),
          blurRadius: 18,
          offset: const Offset(0, 10),
        ),
      ],
    );

    return InkWell(
      onTap: () async {
        final result = await Navigator.pushNamed(
          context,
          '/booking-detail',
          arguments: booking,
        );
        if ((result == true || result == 'approved') && mounted) {
          _loadData();
        }
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: boxDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00C977), Color(0xFF0FBF9F)],
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehicleLabel.isNotEmpty
                            ? '$customerName · $vehicleLabel'
                            : customerName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF1F2937),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        serviceName,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: secondaryText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right,
                  color: isDark ? Colors.white30 : const Color(0xFF9CA3AF),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(isDark ? 0.05 : 0.4),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _buildIconChip(
                  icon: Icons.access_time_outlined,
                  label: humanDate,
                  isDark: isDark,
                  highlight: true,
                ),
                _buildStatusChip(booking['status'], isDark),
              ],
            ),
            if (notes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                notes,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  color: secondaryText,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (attachments > 0) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.photo_camera_outlined,
                    size: 16,
                    color: secondaryText,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    attachments == 1
                        ? '1 foto enviada'
                        : '$attachments fotos enviadas',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: secondaryText,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIconChip({
    required IconData icon,
    required String label,
    required bool isDark,
    bool highlight = false,
  }) {
    final iconColor = highlight
        ? const Color(0xFF00C977)
        : (isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: highlight
            ? const Color(0xFF00C977).withOpacity(isDark ? 0.15 : 0.10)
            : (isDark ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6)),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: highlight
              ? const Color(0xFF00C977).withOpacity(0.35)
              : (isDark ? Colors.white.withOpacity(0.08) : Colors.white),
          width: highlight ? 1 : 0.6,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: highlight
                  ? (isDark ? const Color(0xFF00C977) : const Color(0xFF007A49))
                  : (isDark ? Colors.white : const Color(0xFF1F2937)),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, Color> _getStatusChipConfig(String? status, bool isDark) {
    final n = (status ?? '').toLowerCase().trim();
    if (n == 'pending' || n == 'pendente_oficina' || n == 'pendente') {
      return isDark
          ? {'bg': const Color(0xFF3D2800), 'border': const Color(0xFFFF9800), 'text': const Color(0xFFFFB74D)}
          : {'bg': const Color(0xFFFFF3E0), 'border': const Color(0xFFFF9800), 'text': const Color(0xFFE65100)};
    }
    if (n == 'confirmed' || n == 'confirmado') {
      return isDark
          ? {'bg': const Color(0xFF003D20), 'border': const Color(0xFF00C977), 'text': const Color(0xFF4ADE80)}
          : {'bg': const Color(0xFFE0FFF0), 'border': const Color(0xFF00C977), 'text': const Color(0xFF047857)};
    }
    if (n == 'started' || n == 'in_progress' || n == 'em_andamento') {
      return isDark
          ? {'bg': const Color(0xFF0C2340), 'border': const Color(0xFF3B82F6), 'text': const Color(0xFF60A5FA)}
          : {'bg': const Color(0xFFE0EDFF), 'border': const Color(0xFF3B82F6), 'text': const Color(0xFF1D4ED8)};
    }
    if (n == 'pendente_cliente') {
      return isDark
          ? {'bg': const Color(0xFF3D3000), 'border': const Color(0xFFF59E0B), 'text': const Color(0xFFFBBF24)}
          : {'bg': const Color(0xFFFEF3C7), 'border': const Color(0xFFF59E0B), 'text': const Color(0xFFB45309)};
    }
    if (n == 'finalizado_aguardando_pagamento' || n == 'finalizado_cliente' || n == 'aguardando_pagamento' || n == 'awaiting_payment') {
      return isDark
          ? {'bg': const Color(0xFF2E1065), 'border': const Color(0xFF8B5CF6), 'text': const Color(0xFFA78BFA)}
          : {'bg': const Color(0xFFF0E6FF), 'border': const Color(0xFF8B5CF6), 'text': const Color(0xFF6D28D9)};
    }
    if (n == 'pago' || n == 'paid' || n == 'approved' || n == 'completed' || n == 'finished' || n == 'concluido' || n == 'concluído') {
      return isDark
          ? {'bg': const Color(0xFF003D20), 'border': const Color(0xFF10B981), 'text': const Color(0xFF34D399)}
          : {'bg': const Color(0xFFD1FAE5), 'border': const Color(0xFF10B981), 'text': const Color(0xFF047857)};
    }
    if (n == 'cancelled' || n == 'cancelado') {
      return isDark
          ? {'bg': const Color(0xFF3D0A0A), 'border': const Color(0xFFEF4444), 'text': const Color(0xFFF87171)}
          : {'bg': const Color(0xFFFEE2E2), 'border': const Color(0xFFEF4444), 'text': const Color(0xFFB91C1C)};
    }
    return isDark
        ? {'bg': const Color(0xFF2A2A2A), 'border': Colors.grey, 'text': Colors.grey}
        : {'bg': const Color(0xFFF3F4F6), 'border': Colors.grey, 'text': Colors.grey};
  }

  Widget _buildStatusChip(String? status, bool isDark) {
    final chipConfig = _getStatusChipConfig(status, isDark);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: chipConfig['bg'],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: chipConfig['border']!, width: 1),
      ),
      child: Text(
        _getStatusText(status),
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
          color: chipConfig['text'],
        ),
      ),
    );
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is int) {
      try {
        return DateTime.fromMillisecondsSinceEpoch(value, isUtc: false);
      } catch (_) {
        return null;
      }
    }
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return null;
      try {
        return DateTime.parse(trimmed);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  String _getStatusText(String? status) {
    if (status == null) return 'Desconhecido';
    
    final normalized = status.toString().toLowerCase().trim();
    
    switch (normalized) {
      case 'pending':
      case 'pendente_oficina':
      case 'pendente':
        return 'Pendente';
      case 'confirmed':
      case 'confirmado':
        return 'Confirmado';
      case 'started':
      case 'in_progress':
      case 'em_andamento':
        return 'Em Andamento';
      case 'pendente_cliente':
        return 'Aguardando Cliente';
      case 'finalizado_aguardando_pagamento':
      case 'finalizado_cliente':
        return 'Aguardando Pagamento';
      case 'pago':
      case 'paid':
      case 'approved':
        return 'Pago';
      case 'completed':
      case 'finished':
      case 'concluido':
      case 'concluído':
        return 'Concluído';
      case 'cancelled':
      case 'cancelado':
        return 'Cancelado';
      default:
        // Debug para identificar status não mapeados
        debugPrint('⚠️ [Home] Status não mapeado: $status (normalized: $normalized)');
        return 'Desconhecido';
    }
  }
}
