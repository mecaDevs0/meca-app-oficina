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
import '../../widgets/verify_account_modal.dart';
import '../setup/services_selection_screen.dart';
import 'edit_password_screen.dart';
import 'edit_profile_screen.dart';

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
  bool _isConnectingPagbank = false;
  Map<String, dynamic>? _workshopData;
  Map<String, dynamic>? _pagbankData;
  String? _logoUrl;

  @override
  void initState() {
    super.initState();
    _loadWorkshopData();
  }

  Future<void> _loadWorkshopData() async {
    setState(() => _isLoading = true);

    try {
      // Carregar notificações para atualizar badge do perfil
      try {
        final notificationsResponse = await _apiService.getNotifications();
        if (notificationsResponse['success'] && mounted) {
          final data = notificationsResponse['data'] ?? {};
          final unreadCount = data['unread_count'] is int
              ? data['unread_count']
              : int.tryParse('${data['unread_count']}') ?? 0;
          final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
          notificationProvider.setUnreadNotifications(unreadCount, resetBadge: unreadCount == 0);
        }
      } catch (e) {
        // Erro ao carregar notificações não deve bloquear o carregamento da tela
        print('⚠️ Erro ao carregar notificações: $e');
      }
      
      final response = await _apiService.getProfile();
      if (response['success']) {
        setState(() {
          _workshopData = response['data'];
          _logoUrl = _workshopData?['logo_url'] ?? _workshopData?['logo'];
        });
      }

      // Buscar dados PagBank (account-status retorna email, name, status)
      final pagbankStatusResponse = await _apiService.getPagBankAccountStatus();
      if (pagbankStatusResponse['success']) {
        setState(() {
          _pagbankData = pagbankStatusResponse['data'] as Map<String, dynamic>?;
        });
      }
    } catch (e) {
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleConnectPagBank() async {
    if (_isConnectingPagbank) return;

    setState(() => _isConnectingPagbank = true);
    String? feedback;
    Color? snackBarColor;

    try {
      final response = await _apiService.startPagBankConnect();
      
      if (response['success'] == true) {
        final data = Map<String, dynamic>.from(response['data'] ?? {});
        final authorizeUrl = (data['authorize_url'] ?? data['url'] ?? data['redirect_url'])?.toString();
        final expiresIn = data['expires_in_minutes'];


        if (authorizeUrl != null && authorizeUrl.isNotEmpty) {
          // Validar se a URL é válida
          try {
          final uri = Uri.parse(authorizeUrl);
            
            // Verificar se a URL contém os parâmetros necessários
            if (!uri.queryParameters.containsKey('client_id')) {
              feedback = '⚠️ URL de autorização inválida: falta client_id';
              snackBarColor = Colors.orange;
            } else if (!uri.queryParameters.containsKey('redirect_uri')) {
              feedback = '⚠️ URL de autorização inválida: falta redirect_uri';
              snackBarColor = Colors.orange;
            } else {
          final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);

          if (!launched) {
                feedback = '❌ Não foi possível abrir a página de autorização do PagBank. Verifique se há um navegador instalado.';
                snackBarColor = Colors.red;
          } else {
            feedback = expiresIn != null
                    ? '✅ Autorização PagBank aberta. Conclua o processo em até $expiresIn minutos.'
                    : '✅ Autorização PagBank aberta em uma nova janela.';
                snackBarColor = Colors.green;
              }
            }
          } catch (e) {
            feedback = '❌ URL de autorização inválida: $e';
            snackBarColor = Colors.red;
          }
        } else {
          feedback = '❌ A API não retornou a URL de autorização do PagBank. Verifique os logs do servidor.';
          snackBarColor = Colors.red;
        }
      } else {
        final errorMsg = response['error']?.toString() ?? 'Falha ao iniciar o fluxo PagBank Connect.';
        feedback = '❌ Erro: $errorMsg';
        snackBarColor = Colors.red;
      }
    } catch (e) {
      feedback = '❌ Erro ao iniciar PagBank Connect: $e';
      snackBarColor = Colors.red;
    } finally {
      if (mounted) {
        setState(() => _isConnectingPagbank = false);
        if (feedback != null && feedback.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(feedback),
              backgroundColor: snackBarColor,
              duration: const Duration(seconds: 5),
            ),
          );
        }
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
                      _buildPagBankCard(isDark, textColor, secondaryText),
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
                        title: 'Método de pagamento',
                        subtitle: 'Configuração de pagamentos',
                        isDark: isDark,
                        onTap: () async {
                          await Navigator.pushNamed(context, '/config/pagbank');
                          if (mounted) {
                            await _loadWorkshopData();
                          }
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
                        onTap: _showHelp,
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
    final cnpj = _workshopData?['cnpj'] ?? 'CNPJ indisponível';
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

  Widget _buildPagBankCard(bool isDark, Color textColor, Color secondaryText) {
    final cardColor = ThemeService.getCardColor(isDark);
    final borderColor = secondaryText.withOpacity(0.18);
    final data = _pagbankData ?? const {};
    final accountId = data['pagbank_account_id'] ?? data['account_id'];
    final hasOAuthConnection = accountId != null && 
                               (data['pagbank_access_token'] != null || data['has_authorization'] == true);
    final isVerified = data['pagbank_verified'] == true;
    final status = (data['status'] ?? 'not_created').toString().toLowerCase();
    final email = data['email']?.toString();
    final name = data['name']?.toString();
    final statusMessage = data['status_message']?.toString() ?? '';
    final warningBackground = isDark ? const Color(0xFF2C1B0E) : const Color(0xFFFFF4E5);
    final warningBorder = isDark ? const Color(0xFF5A3414) : const Color(0xFFFFD9B0);
    final warningTitleColor = isDark ? const Color(0xFFFFC58F) : const Color(0xFF8A4B16);
    final warningBodyColor = isDark ? Colors.white70 : const Color(0xFF5F3B10);

    // Determinar estado: not_created, connected (OAuth mas não verificado), verified (OAuth + verificado)
    String pagbankState;
    if (hasOAuthConnection && isVerified) {
      pagbankState = 'verified';
    } else if (hasOAuthConnection && !isVerified) {
      pagbankState = 'connected';
    } else if (accountId != null && accountId.toString().isNotEmpty) {
      pagbankState = status == 'approved' ? 'approved' : 'pending';
    } else {
      pagbankState = 'not_created';
    }

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: isDark
            ? [BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 24, offset: const Offset(0, 18))]
            : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 16))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF00C977).withOpacity(isDark ? 0.14 : 0.18),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.account_balance_wallet_outlined, color: Color(0xFF00C977), size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recebimentos PagBank',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      pagbankState == 'not_created'
                          ? 'Para receber pagamentos via MECA Marketplace, você precisa criar uma conta PagBank Seller.'
                          : pagbankState == 'connected'
                              ? 'Conta PagBank conectada, aguardando validação'
                              : pagbankState == 'verified'
                                  ? 'Conta PagBank conectada e verificada'
                                  : pagbankState == 'pending'
                                      ? 'Conta PagBank criada, pendente de validação'
                                      : 'PagBank aprovado',
                      style: TextStyle(color: secondaryText, fontSize: 14),
                    ),
                  ],
                ),
              ),
              if (pagbankState != 'not_created')
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                    color: _pagbankStatusColor(pagbankState).withOpacity(isDark ? 0.15 : 0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (pagbankState == 'verified')
                      const Icon(Icons.check_circle, size: 14, color: Color(0xFF22C55E)),
                    if (pagbankState == 'verified') const SizedBox(width: 4),
                    Text(
                        _pagbankStatusLabel(pagbankState),
                      style: TextStyle(
                          color: _pagbankStatusColor(pagbankState),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // ESTADO 1: Não cadastrado
          if (pagbankState == 'not_created') ...[
            Text(
              'Para começar a receber pagamentos, você precisa criar uma conta PagBank Seller.',
              style: TextStyle(color: secondaryText, fontSize: 14),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await Navigator.pushNamed(context, '/config/pagbank');
                  if (mounted) {
                    await _loadWorkshopData();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C977),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Cadastrar PagBank'),
              ),
            ),
          ]
          
          // ESTADO 2: Conectado via OAuth mas não verificado
          else if (pagbankState == 'connected') ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7).withOpacity(isDark ? 0.2 : 1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFFCD34D).withOpacity(isDark ? 0.5 : 1),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.link, color: const Color(0xFFF59E0B), size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Conta Conectada',
                          style: TextStyle(
                            color: isDark ? Colors.white : const Color(0xFF92400E),
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Sua conta PagBank está conectada. Agora você precisa validá-la para começar a receber pagamentos.',
                          style: TextStyle(
                            color: isDark ? Colors.white70 : const Color(0xFF78350F),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showVerifyAccountModal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C977),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.verified_user),
                label: const Text('Validar Conta'),
              ),
            ),
          ]
          
          // ESTADO 2.5: Cadastrado mas não validado (método antigo)
          else if (pagbankState == 'pending') ...[
            if (name != null && name.isNotEmpty)
              _buildKeyValueRow('Nome', name, textColor, secondaryText),
            if (email != null && email.isNotEmpty)
              _buildKeyValueRow('Email', email, textColor, secondaryText),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: warningBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: warningBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline, color: Color(0xFFF97316), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Status: Verificação pendente',
                          style: TextStyle(
                            color: warningTitleColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    statusMessage.isNotEmpty
                        ? statusMessage
                        : 'Para validar sua conta e começar a receber pagamentos, você precisa entrar no app PagBank.',
                    style: TextStyle(color: warningBodyColor, fontSize: 13, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
                onPressed: _openPagBankAppStore,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C977),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
                icon: const Icon(Icons.download_outlined),
                label: const Text('Abrir app PagBank'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
                onPressed: _checkAccountStatus,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Já validei minha conta'),
              ),
            ),
          ]
          
          // ESTADO 3: Verificado via OAuth
          else if (pagbankState == 'verified') ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4).withOpacity(isDark ? 0.2 : 1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF86EFAC).withOpacity(isDark ? 0.5 : 1),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Color(0xFF22C55E), size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Conta Verificada',
                          style: TextStyle(
                            color: isDark ? Colors.white : const Color(0xFF166534),
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Sua conta PagBank está conectada e verificada. Você já pode receber pagamentos!',
                          style: TextStyle(
                            color: isDark ? Colors.white70 : const Color(0xFF15803D),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (accountId != null)
              _buildKeyValueRow('ID da Conta', accountId.toString(), textColor, secondaryText),
          ]
          
          // ESTADO 3.5: Validado (método antigo)
          else if (pagbankState == 'approved') ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF86EFAC)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Color(0xFF22C55E), size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PagBank aprovado',
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Sua conta foi aprovada pelo PagBank. Agora você pode receber pagamentos normalmente.',
                          style: TextStyle(color: secondaryText, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (email != null && email.isNotEmpty)
              _buildKeyValueRow('Email cadastrado', email, textColor, secondaryText),
            if (name != null && name.isNotEmpty)
              _buildKeyValueRow('Nome da empresa', name, textColor, secondaryText),
          ],
        ],
      ),
    );
  }

  Color _pagbankStatusColor(String state) {
    switch (state) {
      case 'verified':
        return const Color(0xFF22C55E);
      case 'connected':
        return const Color(0xFF3B82F6);
      case 'approved':
        return const Color(0xFF22C55E);
      case 'pending':
        return const Color(0xFFF97316);
      default:
        return const Color(0xFF6B7280);
    }
  }

  String _pagbankStatusLabel(String state) {
    switch (state) {
      case 'verified':
        return 'Verificado';
      case 'connected':
        return 'Conectado';
      case 'approved':
        return 'Aprovado';
      case 'pending':
        return 'Pendente';
      default:
        return 'Não cadastrado';
    }
  }

  Future<void> _showVerifyAccountModal() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => VerifyAccountModal(
        onVerify: () async {
          Navigator.pop(context);
          await _verifyAccount();
        },
      ),
    );
  }

  Future<void> _verifyAccount() async {
    if (_isConnectingPagbank) return;

    setState(() => _isConnectingPagbank = true);

    try {
      final response = await _apiService.verifyPagBankAccount();

      if (response['success']) {
        final data = response['data'];
        final isValid = data['valid'] == true;

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isValid
                    ? '✅ Conta verificada com sucesso! Você já pode receber pagamentos.'
                    : '⚠️ Conta ainda não verificada. Valide sua conta no app PagBank primeiro.',
              ),
              backgroundColor: isValid ? Colors.green : Colors.orange,
              duration: const Duration(seconds: 4),
            ),
          );
        }

        // Recarregar dados
        await _loadWorkshopData();
      } else {
        throw Exception(response['error'] ?? 'Erro ao verificar conta');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isConnectingPagbank = false);
    }
  }

  Future<void> _openPagBankAppStore() async {
    try {
      // Detectar plataforma e abrir loja apropriada
      final package = 'com.pagseguro.app';
      // App Store: usar ID correto do PagBank (precisa verificar o ID real)
      final appStoreUrl = 'https://apps.apple.com/br/app/pagbank/id1455236751';
      final playStoreUrl = 'https://play.google.com/store/apps/details?id=$package';
      
      // Detectar plataforma usando import 'dart:io'
      final uri = Uri.parse(
        Theme.of(context).platform == TargetPlatform.iOS 
            ? appStoreUrl 
            : playStoreUrl
      );
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      
      if (!launched) {
                if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Não foi possível abrir a loja de aplicativos.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao abrir loja: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _checkAccountStatus() async {
    try {
      setState(() => _isLoading = true);
      
      final response = await _apiService.getPagBankAccountStatus();
      
      if (response['success']) {
        setState(() {
          _pagbankData = response['data'] as Map<String, dynamic>?;
        });
        
        final status = (response['data']?['status'] ?? '').toString().toLowerCase();
        
        if (mounted) {
          if (status == 'approved') {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Conta PagBank aprovada!'),
                backgroundColor: Color(0xFF22C55E),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('⏳ Conta ainda está em análise. Tente novamente mais tarde.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro: ${response['error'] ?? 'Erro ao verificar status'}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao verificar status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
              thumbColor: WidgetStateProperty.all(const Color(0xFF22C55E)),
              trackColor: WidgetStateProperty.all(const Color(0xFF86EFAC)),
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

  String _formatAddressSummary() {
    final raw = _workshopData?['address'];
    if (raw == null) return 'Endereço não cadastrado';

    try {
      Map<String, dynamic> addressMap;
      if (raw is Map<String, dynamic>) {
        addressMap = raw;
      } else if (raw is String) {
        addressMap = Map<String, dynamic>.from(jsonDecode(raw));
      } else {
        return raw.toString();
      }

      final components = [
        addressMap['logradouro'] ?? addressMap['street'],
        addressMap['numero'] ?? addressMap['number'],
        addressMap['bairro'] ?? addressMap['district'],
        addressMap['cidade'] ?? addressMap['city'],
        addressMap['estado'] ?? addressMap['state'],
        addressMap['cep'] ?? addressMap['zip'],
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF00C977),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.build,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text('MECA - Suporte'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Precisa de ajuda? Entre em contato conosco:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildContactInfo(
                Icons.email,
                'Email',
                'contato@mecabr.com',
              ),
              const SizedBox(height: 12),
              _buildContactInfo(
                Icons.access_time,
                'Horário de Atendimento',
                'Horário de 24hrs',
              ),
              const SizedBox(height: 12),
              const SizedBox(height: 16),
              const Text(
                'FAQ Rápido:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('• Como agendar um serviço?'),
              const Text('• Como cancelar um agendamento?'),
              const Text('• Como alterar meus dados?'),
              const Text('• Como funciona o pagamento?'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final emailUri = Uri(
                scheme: 'mailto',
                path: 'contato@mecabr.com',
                query: 'subject=Suporte MECA - Solicitação de Ajuda',
              );
              if (await canLaunchUrl(emailUri)) {
                await launchUrl(emailUri);
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Não foi possível abrir o aplicativo de email.'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C977),
            ),
            child: const Text('Entrar em Contato'),
          ),
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
