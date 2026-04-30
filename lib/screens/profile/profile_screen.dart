import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/notification_provider.dart';
import '../../services/api_service.dart';
import '../../services/image_service.dart';
import '../../services/theme_service.dart';
import '../../services/onesignal_service.dart';
import '../../utils/formatters.dart';
import '../asaas/identity_verification_screen.dart';
import '../help/help_center_screen.dart';
import '../setup/services_selection_screen.dart';
import 'edit_password_screen.dart';
import 'edit_profile_screen.dart';
import 'referral_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  final ImagePicker _imagePicker = ImagePicker();
  bool _isLoading = true;
  bool _isUploadingLogo = false;
  Map<String, dynamic>? _workshopData;
  Map<String, dynamic>? _asaasData;
  bool _isLoadingAsaas = false;
  String? _logoUrl;

  @override
  void initState() {
    super.initState();
    _loadWorkshopData();
  }

  Future<void> _loadWorkshopData() async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);

    try {
      // Carregar notificações para atualizar badge do perfil
      try {
        final notificationsResponse = await _apiService.getNotifications();
        if (notificationsResponse['success'] && mounted) {
          final data = notificationsResponse['data'] ?? {};
          final rawList = List<Map<String, dynamic>>.from(
            data['notifications'] ?? data ?? [],
          );
          final normalizedNotifications = rawList.map((notif) {
            return Map<String, dynamic>.from(notif);
          }).toList();
          
          final unreadCount = data['unread_count'] is int
              ? data['unread_count']
              : int.tryParse('${data['unread_count']}') ?? 0;
          
          final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
          
          // PROTEÇÃO: Se usuário já marcou como lidas (contador = 0), NÃO sobrescrever
          if (notificationProvider.unreadNotifications == 0 && notificationProvider.notifications.isNotEmpty) {
            print('🔒 [Profile] Mantendo notificações locais (já marcadas como lidas)');
          } else {
            // Atualizar com dados do servidor
            notificationProvider.setNotifications(normalizedNotifications);
          }
        }
      } catch (e) {
        // Erro ao carregar notificações não deve bloquear o carregamento da tela
        print('⚠️ Erro ao carregar notificações: $e');
      }
      
      if (!mounted) return;
      
      final response = await _apiService.getProfile();
      if (response['success'] && mounted) {
        setState(() {
          _workshopData = response['data'];
          _logoUrl = _workshopData?['logo_url'] ?? _workshopData?['logo'];
        });
      }

      if (!mounted) return;

      // Buscar status Asaas + banking data (para asaas_error)
      final workshopId = _workshopData?['id']?.toString() ?? '';
      if (workshopId.isNotEmpty) {
        try {
          final asaasResponse = await _apiService.getAsaasStatus(workshopId, force: true);
          if (mounted) {
            setState(() => _asaasData = asaasResponse);
          }
        } catch (_) {}
        try {
          final bankingResponse = await _apiService.get('/workshop/$workshopId/banking');
          if (bankingResponse['success'] == true && mounted) {
            final bankData = bankingResponse['data'] as Map<String, dynamic>? ?? {};
            setState(() {
              _workshopData = {...?_workshopData, ...bankData};
            });
          }
        } catch (_) {}
      }
    } catch (e) {
      print('❌ Erro ao carregar dados: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        final isDark = themeService.isDarkMode;
        final bgColor = ThemeService.getBackgroundColor(isDark);
        final textColor = ThemeService.getTextColor(isDark);
        final secondaryText = ThemeService.getSecondaryTextColor(isDark);
        final notificationProvider = Provider.of<NotificationProvider>(context);
        final showNotificationsBadge = notificationProvider.showProfileBadge || notificationProvider.unreadNotifications > 0;
        
        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              'Perfil',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            iconTheme: IconThemeData(color: textColor),
            leading: IconButton(
              icon: Stack(
                children: [
                  Icon(Icons.notifications_outlined, color: textColor),
                  if (showNotificationsBadge)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              onPressed: () {
                Navigator.pushNamed(context, '/notifications');
              },
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.edit_outlined, color: textColor),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EditProfileScreen(),
                    ),
                  ).then((_) => _loadWorkshopData());
                },
              ),
            ],
          ),
          body: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00C977)),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProfileHeader(isDark, textColor, secondaryText, themeService),
                      const SizedBox(height: 32),
                      _buildAsaasStatusCard(isDark, textColor, secondaryText),
                      const SizedBox(height: 32),
                      _buildThemeCard(isDark, themeService),
                      const SizedBox(height: 32),
                      _buildSectionTitle('Configurações', textColor, secondaryText),
                      const SizedBox(height: 16),
                      _buildMenuOption(
                        icon: Icons.person,
                        title: 'Editar Perfil',
                        subtitle: 'Alterar informações pessoais',
                        isDark: isDark,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const EditProfileScreen(),
                            ),
                          ).then((_) => _loadWorkshopData());
                        },
                      ),
                      _buildMenuOption(
                        icon: Icons.access_time_outlined,
                        title: 'Horários de Funcionamento',
                        subtitle: 'Editar agenda e horários de atendimento',
                        isDark: isDark,
                        onTap: () async {
                          await Navigator.pushNamed(context, '/config/agenda');
                          if (mounted) {
                            await _loadWorkshopData();
                          }
                        },
                      ),
                      _buildMenuOption(
                        icon: Icons.build_outlined,
                        title: 'Editar Serviços',
                        subtitle: 'Selecionar ou remover serviços oferecidos',
                        isDark: isDark,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ServicesSelectionScreen(),
                            ),
                          );
                        },
                      ),
                      _buildMenuOption(
                        icon: Icons.notifications_active_outlined,
                        title: 'Notificações',
                        subtitle: 'Configurar alertas e notificações',
                        isDark: isDark,
                        showBadge: showNotificationsBadge,
                        onTap: () async {
                          await Navigator.pushNamed(context, '/notifications');
                          if (mounted) {
                            await _loadWorkshopData();
                          }
                        },
                      ),
                      _buildMenuOption(
                        icon: Icons.account_balance_wallet_outlined,
                        title: 'Dados bancários',
                        subtitle: 'Configurar conta de recebimento',
                        isDark: isDark,
                        onTap: () async {
                          final result = await Navigator.pushNamed(context, '/config/banking');
                          if (result == true && mounted) {
                            await _loadWorkshopData();
                          }
                        },
                      ),
                      _buildMenuOption(
                        icon: Icons.credit_card_outlined,
                        title: 'Parcelamento',
                        subtitle: 'Aceitar ou não parcelamento no cartão',
                        isDark: isDark,
                        onTap: () async {
                          await Navigator.pushNamed(context, '/config/installment');
                          if (mounted) {
                            await _loadWorkshopData();
                          }
                        },
                      ),
                      _buildMenuOption(
                        icon: Icons.card_giftcard_outlined,
                        title: 'Indique e Ganhe',
                        subtitle: 'Código de indicação e taxa reduzida',
                        isDark: isDark,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ReferralScreen(),
                            ),
                          );
                        },
                      ),
                      _buildMenuOption(
                        icon: Icons.lock_outline,
                        title: 'Alterar Senha',
                        subtitle: 'Alterar sua senha de acesso',
                        isDark: isDark,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const EditPasswordScreen(),
                            ),
                          );
                        },
                      ),
                      _buildMenuOption(
                        icon: Icons.help_outline,
                        title: 'Central de Ajuda',
                        subtitle: 'Dúvidas e suporte',
                        isDark: isDark,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpCenterScreen())),
                      ),
                      _buildMenuOption(
                        icon: Icons.logout,
                        title: 'Sair',
                        subtitle: 'Fazer logout da conta',
                        isDark: isDark,
                        isDestructive: true,
                        onTap: _logout,
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildProfileHeader(
    bool isDark,
    Color textColor,
    Color secondaryText,
    ThemeService themeService,
  ) {
    final gradientColors = isDark
        ? [const Color(0xFF0F172A), const Color(0xFF1E3A8A)]
        : [const Color(0xFF34D399), const Color(0xFF22C55E)];

    final workshopName = _workshopData?['name'] ?? 'Oficina MECA';
    final workshopEmail = _workshopData?['email'] ?? 'oficina@mecabr.com';
    final workshopPhone = _workshopData?['phone'] ?? 'Sem telefone cadastrado';
    final cnpj = Formatters.formatCnpj(_workshopData?['cnpj'] ?? '');
    final status = (_workshopData?['status'] ?? 'pending').toString();
    final address = _formatAddressSummary();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.45)
                : const Color(0xFF22C55E).withOpacity(0.35),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(isDark ? 0.04 : 0.13),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withOpacity(isDark ? 0.15 : 0.05),
              ),
            ),
          ),
          Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.22),
                    ),
                  ),
                  child: Text(
                    _statusLabel(status),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildAvatar(isDark),
              const SizedBox(height: 18),
              Text(
                workshopName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                workshopEmail,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.white.withOpacity(0.78),
                ),
              ),
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(isDark ? 0.08 : 0.18),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.25),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.call_outlined, color: Colors.white.withOpacity(0.9), size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                Formatters.formatPhone(workshopPhone),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(Icons.badge_outlined, color: Colors.white.withOpacity(0.9), size: 18),
                            const SizedBox(width: 8),
                            Text(
                              cnpj,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.location_on_outlined, color: Colors.white.withOpacity(0.9), size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                address,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.92),
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(bool isDark) {
    // Verificar se logo_url existe e é uma URL válida
    final hasLogo = _logoUrl != null && 
                    _logoUrl!.isNotEmpty && 
                    (_logoUrl!.startsWith('http://') || _logoUrl!.startsWith('https://'));
    final borderColor = Colors.white.withOpacity(isDark ? 0.25 : 0.45);

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
        Container(
          width: 116,
          height: 116,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF1D4ED8), const Color(0xFF2563EB)]
                  : [const Color(0xFF22C55E), const Color(0xFF10B981)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.45 : 0.15),
                blurRadius: 18,
                offset: const Offset(0, 12),
              ),
            ],
          ),
        ),
        Container(
          width: 112,
          height: 112,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: borderColor, width: 4),
          ),
          child: ClipOval(
            child: hasLogo
                ? Image.network(
                    _logoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.business_outlined,
                        size: 48,
                        color: Colors.white.withOpacity(0.9),
                      );
                    },
                  )
                : Icon(
                    Icons.business_outlined,
                    size: 48,
                    color: Colors.white.withOpacity(0.9),
                  ),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(
                color: const Color(0xFF00C977),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00C977).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(21),
                onTap: _isUploadingLogo ? null : _showLogoPicker,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (_isUploadingLogo)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00C977)),
                        ),
                      )
                    else
                      const Icon(
                        Icons.camera_alt,
                        size: 20,
                        color: Color(0xFF00C977),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
          ],
        ),
        if (!hasLogo) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _isUploadingLogo ? null : _showLogoPicker,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.camera_alt,
                    size: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Adicionar logo',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAsaasStatusCard(bool isDark, Color textColor, Color secondaryText) {
    final asaasDataInner = _asaasData?['data'] as Map<String, dynamic>?;
    final asaasStatus = (asaasDataInner?['asaas_status'] ??
        _workshopData?['asaas_status'] ?? '').toString().toUpperCase();
    final asaasError = (_workshopData?['asaas_error'] ?? '').toString();
    final needsKyc = asaasDataInner?['needs_kyc'] == true;
    final isActive = asaasStatus == 'APPROVED' || asaasStatus == 'ACTIVE';
    final isPending = asaasStatus == 'PENDING';
    final isError = asaasStatus == 'ERROR';
    final isRejected = asaasStatus == 'REJECTED';
    final hasBankData = (_workshopData?['bank_code'] ?? '').toString().trim().isNotEmpty ||
        (_workshopData?['pix_key'] ?? '').toString().trim().isNotEmpty;
    final isConfigured = isActive || isPending;

    // Status visual config
    final Color statusColor = isActive
        ? const Color(0xFF00C977)
        : isPending
            ? const Color(0xFFF59E0B)
            : isError
                ? const Color(0xFFEF4444)
                : isRejected
                    ? const Color(0xFFEF4444)
                    : hasBankData
                        ? const Color(0xFFF59E0B)
                        : Colors.grey;

    final IconData statusIcon = isActive
        ? Icons.check_circle
        : isPending && needsKyc
            ? Icons.verified_user_outlined
            : isPending
                ? Icons.hourglass_top_rounded
                : isError
                    ? Icons.error_outline
                    : isRejected
                        ? Icons.cancel_outlined
                        : hasBankData
                            ? Icons.info_outline
                            : Icons.account_balance_outlined;

    final String statusLabel = isActive
        ? 'Ativa'
        : isPending && needsKyc
            ? 'Verificacao pendente'
            : isPending
                ? 'Em analise'
                : isError
                    ? 'Erro'
                    : isRejected
                        ? 'Rejeitada'
                        : hasBankData
                            ? 'Incompleto'
                            : 'Pendente';

    final String statusDescription = isActive
        ? 'Sua conta esta ativa e pronta para receber pagamentos dos clientes.'
        : isPending && needsKyc
            ? 'Sua conta precisa de verificacao de identidade para ser ativada. Toque abaixo para completar.'
            : isPending
                ? 'Sua conta esta em analise pelo Asaas. Esse processo leva ate 2 dias uteis. Voce sera notificado quando for aprovada.'
                : isError
                    ? 'Houve um erro ao configurar sua conta. Toque em "Tentar novamente" para corrigir.'
                    : isRejected
                        ? 'Sua conta foi rejeitada. Verifique se os dados cadastrados estao corretos e tente novamente.'
                        : hasBankData
                            ? 'Seus dados bancarios foram salvos, mas a conta de recebimento ainda nao foi ativada. Preencha todos os campos obrigatorios.'
                            : 'Configure seus dados bancarios para comecar a receber pagamentos dos clientes.';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Conta de Recebimento',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textColor),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        statusDescription,
                        style: TextStyle(fontSize: 13, color: secondaryText, height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: statusColor),
                  ),
                ),
              ],
            ),

            // Progress steps (when pending)
            if (isPending) ...[
              const SizedBox(height: 20),
              _buildProgressSteps(isDark, secondaryText),
            ],

            // Error message
            if ((isError || isRejected) && asaasError.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: Color(0xFFEF4444)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        asaasError.length > 120 ? '${asaasError.substring(0, 120)}...' : asaasError,
                        style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFFFF8A8A) : const Color(0xFFB91C1C), height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Action buttons
            if (isActive) ...[
              // Active: show edit button
              _buildActionRow(
                icon: Icons.settings_outlined,
                label: 'Editar dados bancarios',
                color: const Color(0xFF00C977),
                secondaryText: secondaryText,
                onTap: () => _navigateToBanking(),
              ),
            ] else if (isPending) ...[
              // KYC needed: prominent verification button
              if (needsKyc) ...[
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00C977), Color(0xFF00A865)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const IdentityVerificationScreen(),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.verified_user_outlined, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'Completar verificacao',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              // Pending: show refresh + edit
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.refresh,
                      label: 'Atualizar status',
                      color: const Color(0xFFF59E0B),
                      isDark: isDark,
                      isLoading: _isLoadingAsaas,
                      onTap: _refreshAsaasStatus,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.edit_outlined,
                      label: 'Ver dados',
                      color: secondaryText,
                      isDark: isDark,
                      outlined: true,
                      onTap: () => _navigateToBanking(),
                    ),
                  ),
                ],
              ),
            ] else if (isError || isRejected) ...[
              // Error/Rejected: retry button prominent
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _navigateToBanking(),
                    borderRadius: BorderRadius.circular(12),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.refresh, color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Tentar novamente',
                            style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ] else ...[
              // Not configured: CTA
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00C977), Color(0xFF00A563)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _navigateToBanking(),
                    borderRadius: BorderRadius.circular(12),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.account_balance, color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Configurar Dados Bancarios',
                            style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'A MECA arca com 100% das taxas do gateway de pagamento.',
                style: TextStyle(fontSize: 12, color: secondaryText),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProgressSteps(bool isDark, Color secondaryText) {
    return Row(
      children: [
        _buildStep(label: 'Cadastro', done: true, isDark: isDark),
        _buildStepConnector(done: true),
        _buildStep(label: 'Analise', done: false, active: true, isDark: isDark),
        _buildStepConnector(done: false),
        _buildStep(label: 'Aprovado', done: false, isDark: isDark),
      ],
    );
  }

  Widget _buildStep({required String label, required bool done, bool active = false, required bool isDark}) {
    final color = done
        ? const Color(0xFF00C977)
        : active
            ? const Color(0xFFF59E0B)
            : Colors.grey.withOpacity(0.4);

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done ? const Color(0xFF00C977) : Colors.transparent,
              border: Border.all(color: color, width: 2),
            ),
            child: done
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : active
                    ? Center(
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFF59E0B),
                          ),
                        ),
                      )
                    : null,
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              color: done
                  ? const Color(0xFF00C977)
                  : active
                      ? const Color(0xFFF59E0B)
                      : Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStepConnector({required bool done}) {
    return Container(
      width: 30,
      height: 2,
      margin: const EdgeInsets.only(bottom: 18),
      color: done ? const Color(0xFF00C977) : Colors.grey.withOpacity(0.3),
    );
  }

  Widget _buildActionRow({
    required IconData icon,
    required String label,
    required Color color,
    required Color secondaryText,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 16, color: secondaryText),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w600)),
            const Spacer(),
            Icon(Icons.chevron_right, size: 18, color: secondaryText),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    bool outlined = false,
    bool isLoading = false,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: outlined ? Colors.transparent : color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: outlined ? Border.all(color: color.withOpacity(0.3)) : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                  SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: color))
                else
                  Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _navigateToBanking() async {
    final result = await Navigator.pushNamed(context, '/config/banking');
    if (result == true && mounted) {
      _loadWorkshopData();
    }
  }

  Future<void> _refreshAsaasStatus() async {
    final workshopId = _workshopData?['id']?.toString() ?? '';
    if (workshopId.isEmpty) return;

    setState(() => _isLoadingAsaas = true);
    try {
      final asaasResponse = await _apiService.getAsaasStatus(workshopId, force: true);
      if (mounted) {
        setState(() {
          _asaasData = asaasResponse;
        });
        // Reload full profile to get updated workshop data (now synced with Asaas)
        final response = await _apiService.getProfile();
        if (response['success'] && mounted) {
          setState(() {
            _workshopData = response['data'];
          });
        }

        final newStatus = (asaasResponse['data']?['asaas_status'] ?? '').toString().toUpperCase();
        if (newStatus == 'APPROVED' || newStatus == 'ACTIVE') {
          _showStatusSnackbar('Conta aprovada! Voce ja pode receber pagamentos.', const Color(0xFF00C977));
        } else if (newStatus == 'PENDING') {
          _showStatusSnackbar('Sua conta ainda esta em analise. Voce sera notificado quando for aprovada.', const Color(0xFFF59E0B));
        } else if (newStatus == 'REJECTED') {
          _showStatusSnackbar('Conta rejeitada. Verifique seus dados e tente novamente.', const Color(0xFFEF4444));
        }
      }
    } catch (e) {
      if (mounted) {
        _showStatusSnackbar('Erro ao verificar status. Tente novamente.', const Color(0xFFEF4444));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingAsaas = false);
      }
    }
  }

  void _showStatusSnackbar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == const Color(0xFF00C977)
                  ? Icons.check_circle
                  : color == const Color(0xFFF59E0B)
                      ? Icons.info_outline
                      : Icons.error_outline,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: const TextStyle(fontSize: 14))),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Widget _buildKeyValueRow(String label, dynamic value, Color primary, Color secondary) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: secondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value?.toString() ?? '-',
              style: TextStyle(
                color: primary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _formatDateTime(dynamic value) {
    if (value == null) return null;
    try {
      final date = value is DateTime ? value : DateTime.parse(value.toString());
      final local = date.toLocal();
      final day = local.day.toString().padLeft(2, '0');
      final month = local.month.toString().padLeft(2, '0');
      final year = local.year.toString();
      final hour = local.hour.toString().padLeft(2, '0');
      final minute = local.minute.toString().padLeft(2, '0');
      return '$day/$month/$year $hour:$minute';
    } catch (_) {
      return value.toString();
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'active':
      case 'approved':
        return const Color(0xFF22C55E);
      case 'pending':
        return const Color(0xFFF97316);
      default:
        return const Color(0xFF6B7280);
    }
  }

  String _formatBank(Map<String, dynamic> bank) {
    final code = (bank['bank_code'] ?? '').toString();
    final name = (bank['bank_name'] ?? '').toString();
    if (code.isEmpty && name.isEmpty) return '-';
    if (name.isEmpty) return code;
    if (code.isEmpty) return name;
    return '$code · $name';
  }

  String _translateAccountType(dynamic value) {
    switch (value?.toString()) {
      case 'savings':
      case 'poupanca':
        return 'Poupança';
      default:
        return 'Conta corrente';
    }
  }

  String _translatePixType(dynamic value) {
    switch (value?.toString()) {
      case 'cpf':
        return 'CPF';
      case 'cnpj':
        return 'CNPJ';
      case 'email':
        return 'E-mail';
      case 'phone':
      case 'telefone':
        return 'Telefone';
      case 'aleatorio':
        return 'Chave aleatória';
      default:
        return 'Outro';
    }
  }

  Widget _buildThemeCard(bool isDark, ThemeService themeService) {
    final cardColor = isDark ? const Color(0xFF111827) : Colors.white;
    final borderColor = isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE5E7EB);
    final textColor = ThemeService.getTextColor(isDark);
    final subtitleColor = ThemeService.getSecondaryTextColor(isDark);

    return GestureDetector(
      onTap: () => themeService.toggleTheme(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withOpacity(0.4) : Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF22D3EE), const Color(0xFF6366F1)]
                      : [const Color(0xFF22C55E), const Color(0xFF0EA5E9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Icon(
                isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tema do aplicativo',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isDark
                        ? 'Modo escuro ativo. Toque para usar o modo claro.'
                        : 'Modo claro ativo. Toque para usar o modo escuro.',
                    style: TextStyle(
                      fontSize: 14,
                      color: subtitleColor,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: isDark,
              onChanged: (_) => themeService.toggleTheme(),
              thumbColor: MaterialStateProperty.all(const Color(0xFF22C55E)),
              trackColor: MaterialStateProperty.all(const Color(0xFF86EFAC)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color primary, Color secondary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: primary,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 46,
          height: 4,
          decoration: BoxDecoration(
            color: const Color(0xFF22C55E),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
    bool isDestructive = false,
    bool showBadge = false,
  }) {
    final cardColor = isDark ? const Color(0xFF101826) : Colors.white;
    final borderColor = isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0);
    final iconColor = isDestructive ? const Color(0xFFEF4444) : const Color(0xFF10B981);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.25) : const Color(0xFFCBD5F5).withOpacity(0.45),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: iconColor.withOpacity(0.12),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white.withOpacity(0.65) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                if (showBadge)
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(
                        color: isDark ? cardColor : Colors.white,
                        width: 1,
                      ),
                    ),
                  ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: isDark ? Colors.white.withOpacity(0.5) : const Color(0xFF94A3B8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatCepVisual(String? cep) {
    if (cep == null || cep.isEmpty) return '';
    final digits = cep.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 8) {
      return '${digits.substring(0, 5)}-${digits.substring(5)}';
    }
    return cep;
  }

  String _formatAddressSummary() {
    // Suportar formato plano da API (address, city, state, cep) e objeto (logradouro, cidade, etc.)
    final raw = _workshopData?['address'];
    final flatCity = _workshopData?['city']?.toString().trim();
    final flatState = _workshopData?['state']?.toString().trim();
    final flatCep = _formatCepVisual(_workshopData?['cep']?.toString().trim());
    final flatAddressStr = raw is String ? (raw as String).trim() : null;

    if (flatAddressStr != null && flatAddressStr.isNotEmpty) {
      final parts = [flatAddressStr, flatCity, flatState, flatCep]
          .whereType<String>()
          .where((s) => s.isNotEmpty)
          .toList();
      if (parts.isNotEmpty) return parts.join(', ');
    }

    if (raw == null) return 'Endereço não cadastrado';

    try {
      Map<String, dynamic> addressMap;
      if (raw is Map<String, dynamic>) {
        addressMap = raw;
      } else if (raw is String) {
        try {
          addressMap = Map<String, dynamic>.from(jsonDecode(raw));
        } catch (_) {
          return raw.isEmpty ? 'Endereço não cadastrado' : raw;
        }
      } else {
        return raw.toString();
      }

      final rawCep = (addressMap['cep'] ?? addressMap['zip'])?.toString() ?? '';
      final components = [
        addressMap['logradouro'] ?? addressMap['street'],
        addressMap['numero'] ?? addressMap['number'],
        addressMap['bairro'] ?? addressMap['district'],
        addressMap['cidade'] ?? addressMap['city'],
        addressMap['estado'] ?? addressMap['state'],
        _formatCepVisual(rawCep),
      ].whereType<String>().where((element) => element.isNotEmpty).toList();

      if (components.isEmpty) {
        return 'Endereço não cadastrado';
      }

      return components.join(', ');
    } catch (_) {
      return raw.toString();
    }
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'active':
        return 'Ativa';
      case 'pending':
        return 'Em análise';
      case 'rejected':
      case 'inactive':
        return 'Inativa';
      default:
        return status;
    }
  }

  void _showHelp() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0B1120) : Colors.white;
    final card = isDark ? const Color(0xFF101826) : const Color(0xFFF8FAFC);
    final textColor = isDark ? Colors.white : Colors.black87;
    final secondary = isDark ? Colors.white70 : Colors.black54;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white : Colors.black).withOpacity(0.18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00C977).withOpacity(0.16),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.support_agent, color: Color(0xFF00C977)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('MECA Suporte', style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 2),
                          Text('Respostas rápidas', style: TextStyle(color: secondary)),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: textColor.withOpacity(0.8)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: card,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFF00C977).withOpacity(0.18)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFaqItem(
                        title: 'Taxas do gateway',
                        body: 'As taxas do gateway de pagamento (PIX e cartao) sao arcadas integralmente pela MECA. Voce nao e descontado.',
                        isDark: isDark,
                      ),
                      _buildFaqItem(
                        title: 'Taxa MECA (12%)',
                        body: 'O MECA cobra 12% em cada pagamento (split automatico). A MECA arca com 100% das taxas do gateway; voce recebe 88% do valor pago pelo cliente.',
                        isDark: isDark,
                      ),
                      _buildFaqItem(
                        title: 'Como funciona o split',
                        body: 'O cliente paga no MECA e o gateway faz o repasse automaticamente: 12% vai para o MECA e 88% vai para sua conta bancaria.',
                        isDark: isDark,
                      ),
                      _buildFaqItem(
                        title: 'Conta nao atualizada',
                        body: 'Puxe a tela para baixo para atualizar os dados. Se o problema persistir, entre em contato com suporte@mecabr.com.',
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      final emailUri = Uri(
                        scheme: 'mailto',
                        path: 'contato@mecabr.com',
                        query: 'subject=Suporte MECA - Ajuda',
                      );
                      if (await canLaunchUrl(emailUri)) {
                        await launchUrl(emailUri);
                      } else {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Não foi possível abrir o aplicativo de email.'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00C977),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.email_outlined),
                    label: const Text('Falar com suporte'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFaqItem({required String title, required String body, required bool isDark}) {
    final textColor = isDark ? Colors.white : Colors.black87;
    final secondary = isDark ? Colors.white70 : Colors.black54;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: textColor, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(body, style: TextStyle(color: secondary, height: 1.25)),
          const SizedBox(height: 10),
          Divider(height: 1, color: (isDark ? Colors.white : Colors.black).withOpacity(0.08)),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildContactInfo(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF00C977)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showLogoPicker() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Título
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00C977).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.image,
                        color: Color(0xFF00C977),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Atualizar Logo da Oficina',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              
              const Divider(height: 1),
              
              // Opções de upload
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    // Galeria
            ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00C977).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.photo_library,
                          color: Color(0xFF00C977),
                          size: 24,
                        ),
                      ),
                      title: const Text(
                        'Escolher da galeria',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: const Text('Selecione uma imagem já salva no seu dispositivo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
                    
                    // Câmera
            ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.blue,
                          size: 24,
                        ),
                      ),
                      title: const Text(
                        'Tirar foto',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: const Text('Capture uma nova imagem com a câmera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
                    
                    // Remover logo (se existir)
                    if (_logoUrl != null && _logoUrl!.isNotEmpty) ...[
                      const Divider(height: 1),
              ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                            size: 24,
                          ),
                        ),
                        title: const Text(
                          'Remover logo',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.red,
                          ),
                        ),
                        subtitle: const Text('Remover a logo atual da oficina'),
                onTap: () {
                  Navigator.pop(context);
                  _removeLogo();
                },
              ),
                    ],
                  ],
                ),
              ),
              
              // Informações sobre o upload
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Colors.blue,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Recomendações:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.blue,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '• Dimensões recomendadas: 512x512px\n• Formatos: JPG, PNG ou WebP\n• Tamanho máximo: 2MB\n• Use uma imagem quadrada para melhor resultado',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.blue,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 90,
      );
      
      if (image != null) {
        // Validar tipo de arquivo
        if (!ImageService.validateImageType(image.path)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tipo de arquivo não suportado. Use JPG, PNG ou WebP'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
        
        // Validar tamanho
        final isValidSize = await ImageService.validateImageSize(image, 'logo');
        if (!isValidSize) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Imagem muito grande. Tamanho máximo: 2MB'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
        
        await _uploadLogo(image);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao selecionar imagem: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _uploadLogo(XFile imageFile) async {
    setState(() => _isUploadingLogo = true);

    try {
      // Comprimir e converter para base64 usando ImageService
      final uploadResult = await ImageService.uploadImage(
        imageType: 'logo',
        imageFile: imageFile,
      );

      if (uploadResult['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Expanded(child: Text('Logo atualizado com sucesso!')),
              ],
            ),
            backgroundColor: const Color(0xFF00C977),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 3),
          ),
        );
        await _loadWorkshopData();
      } else {
        throw Exception(uploadResult['error'] ?? 'Erro ao fazer upload');
      }
    } catch (e) {
      String errorMessage = 'Erro ao fazer upload da logo';
      if (e.toString().contains('Formato')) {
        errorMessage = 'Formato de imagem inválido. Use JPG ou PNG';
      } else if (e.toString().contains('grande') || e.toString().contains('tamanho')) {
        errorMessage = 'Imagem muito grande. Tamanho máximo: 2MB';
      } else if (e.toString().contains('permissão')) {
        errorMessage = 'Você não tem permissão para atualizar esta oficina';
      } else {
        errorMessage = e.toString();
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(errorMessage)),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      setState(() => _isUploadingLogo = false);
    }
  }

  Future<void> _removeLogo() async {
    // Confirmar remoção
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover Logo'),
        content: const Text('Tem certeza que deseja remover a logo da sua oficina?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
    
    if (confirm != true) return;
    
    setState(() => _isUploadingLogo = true);
    
    try {
      final result = await _apiService.removeLogo();
      
      if (result['success']) {
    ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Expanded(child: Text('Logo removida com sucesso!')),
              ],
            ),
            backgroundColor: const Color(0xFF00C977),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 3),
          ),
        );
        await _loadWorkshopData();
      } else {
        throw Exception(result['error'] ?? 'Erro ao remover logo');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('Erro ao remover logo: ${e.toString()}')),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      setState(() => _isUploadingLogo = false);
    }
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmar Logout'),
        content: const Text('Tem certeza que deseja sair da sua conta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              // Fechar diálogo primeiro
              Navigator.pop(dialogContext);
              
              // Aguardar um frame para garantir que o diálogo foi fechado
              await Future.delayed(const Duration(milliseconds: 300));
              
              // Remover token OneSignal antes de fazer logout
              try {
                final playerId = OneSignalService.getSubscriptionId();
                if (playerId != null) {
                  await _apiService.removeDeviceToken(playerId);
                  await OneSignalService.removeExternalUserId();
                }
              } catch (e) {
                print('Erro ao remover device token: $e');
              }
              
              // Fazer logout na API
              try {
                await _apiService.logout();
              } catch (e) {
                print('Erro ao fazer logout na API: $e');
              }
              
              // Aguardar um pouco mais para garantir que tudo foi processado
              await Future.delayed(const Duration(milliseconds: 200));
              
              // Navegar usando o contexto do MaterialApp diretamente
              // Usar uma abordagem mais segura que não depende do estado do widget
              if (mounted) {
                try {
                  // Tentar usar o Navigator do contexto atual
                  Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
                    '/login',
                    (route) => false,
                  );
                } catch (e) {
                  print('Erro ao navegar com Navigator.of: $e');
                  // Se falhar, tentar usar uma abordagem alternativa
                  try {
                    // Forçar navegação usando o contexto do MaterialApp
                    final navigatorKey = Navigator.of(context);
                    navigatorKey.pushNamedAndRemoveUntil(
                      '/login',
                      (route) => false,
                    );
                  } catch (e2) {
                    print('Erro ao navegar após logout: $e2');
                    // Em último caso, o app será redirecionado na próxima inicialização
                    // pois o token já foi removido
                  }
                }
              }
            },
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }
}
