import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/notification_provider.dart';
import '../../services/api_service.dart';
import '../../services/theme_service.dart';
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
      final response = await _apiService.getProfile();
      if (response['success']) {
        setState(() {
          _workshopData = response['data'];
          _logoUrl = _workshopData?['logo_url'] ?? _workshopData?['logo'];
        });
      }

      final pagbankResponse = await _apiService.getPagBankAccount();
      if (pagbankResponse['success']) {
        setState(() {
          _pagbankData = pagbankResponse['data'] as Map<String, dynamic>?;
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
    final workshopEmail = _workshopData?['email'] ?? 'oficina@meca.com';
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
                                workshopPhone,
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
    final hasLogo = _logoUrl != null && _logoUrl!.isNotEmpty;
    final borderColor = Colors.white.withOpacity(isDark ? 0.25 : 0.45);

    return Stack(
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
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(19),
                onTap: _isUploadingLogo ? null : _showLogoPicker,
                child: const Icon(
                  Icons.camera_alt_outlined,
                  size: 18,
                  color: Color(0xFF10B981),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPagBankCard(bool isDark, Color textColor, Color secondaryText) {
    final cardColor = ThemeService.getCardColor(isDark);
    final borderColor = secondaryText.withOpacity(0.18);
    final data = _pagbankData ?? const {};
    final hasAccount = data['has_account'] == true;
    final status = (data['status'] ?? 'pending').toString();
    final bank = (data['bank_account'] as Map<String, dynamic>?) ?? const {};
    final connect = (data['connect'] as Map<String, dynamic>?) ?? const {};
    final connectAuthorized = connect['authorized'] == true;
    final connectLastError = (connect['last_error'] ?? '').toString();
    final connectAuthorizedAt = _formatDateTime(connect['authorized_at']);
    final tokenExpiresAt = _formatDateTime(connect['token_expires_at']);

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
                      'Método de pagamento',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasAccount
                          ? 'Pagamentos ativos pelo PagBank usando sua conta bancária.'
                          : 'Cadastre sua conta bancária para ativar os pagamentos.',
                      style: TextStyle(color: secondaryText, fontSize: 14),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: _statusColor(status).withOpacity(isDark ? 0.15 : 0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _statusLabel(status),
                  style: TextStyle(
                    color: _statusColor(status),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (hasAccount) ...[
            _buildKeyValueRow('Banco', _formatBank(bank), textColor, secondaryText),
            _buildKeyValueRow('Agência', bank['agency_number'] ?? '-', textColor, secondaryText),
            _buildKeyValueRow('Conta', bank['account_number'] ?? '-', textColor, secondaryText),
            _buildKeyValueRow('Tipo', _translateAccountType(bank['account_type']), textColor, secondaryText),
            _buildKeyValueRow('Titular', bank['holder_name'] ?? '-', textColor, secondaryText),
            if ((bank['holder_document'] ?? '').toString().isNotEmpty)
              _buildKeyValueRow('Documento', bank['holder_document'], textColor, secondaryText),
            if ((bank['pix_key'] ?? '').toString().isNotEmpty)
              _buildKeyValueRow('Chave Pix', bank['pix_key'], textColor, secondaryText),
            if ((bank['pix_key_type'] ?? '').toString().isNotEmpty)
              _buildKeyValueRow('Tipo da chave', _translatePixType(bank['pix_key_type']), textColor, secondaryText),
            if (connectAuthorizedAt != null)
              _buildKeyValueRow('Autorizado em', connectAuthorizedAt, textColor, secondaryText),
            if (tokenExpiresAt != null)
              _buildKeyValueRow('Token expira em', tokenExpiresAt, textColor, secondaryText),
          ] else
            Text(
              'Nenhuma conta bancária vinculada ainda.',
              style: TextStyle(color: secondaryText, fontSize: 14),
            ),
          if (!connectAuthorized)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'Autorize o PagBank para que os pagamentos sejam direcionados automaticamente à sua conta.',
                style: TextStyle(color: secondaryText, fontSize: 13),
              ),
            ),
          if (connectLastError.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF2F2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFB4B4)),
                ),
                child: Text(
                  'Último erro: $connectLastError',
                  style: const TextStyle(color: Color(0xFFD14343), fontSize: 13),
                ),
              ),
            ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isConnectingPagbank ? null : _handleConnectPagBank,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C977),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: Icon(connectAuthorized ? Icons.refresh_outlined : Icons.link_outlined),
              label: Text(connectAuthorized ? 'Reautorizar PagBank' : 'Conectar PagBank'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                await Navigator.pushNamed(context, '/config/pagbank');
                if (mounted) {
                  await _loadWorkshopData();
                }
              },
              icon: const Icon(Icons.edit_outlined),
              label: Text(hasAccount ? 'Editar dados bancários' : 'Adicionar dados bancários'),
            ),
          ),
        ],
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
        title: const Text('Central de Ajuda'),
        content: const Text(
          'Para suporte, entre em contato:\n\n'
          'Email: suporte@meca.com\n'
          'Telefone: (11) 99999-9999\n'
          'Horário: 8h às 18h',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _showLogoPicker() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Escolher da galeria'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Tirar foto'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            if (_logoUrl != null && _logoUrl!.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Remover logo', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _removeLogo();
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(source: source);
      if (image != null) {
        await _uploadLogo(image.path);
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

  Future<void> _uploadLogo(String imagePath) async {
    setState(() => _isUploadingLogo = true);

    try {
      final workshopId = await _apiService.getWorkshopId();
      if (workshopId == null) {
        throw Exception('Workshop ID não encontrado');
      }

      final result = await _apiService.uploadLogo(imagePath);

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logo atualizado com sucesso!'),
            backgroundColor: Color(0xFF00C977),
          ),
        );
        await _loadWorkshopData();
      } else {
        throw Exception(result['error'] ?? 'Erro ao fazer upload');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao fazer upload: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isUploadingLogo = false);
    }
  }

  Future<void> _removeLogo() async {
    // TODO: Implementar remoção de logo na API
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidade de remoção de logo em desenvolvimento'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Logout'),
        content: const Text('Tem certeza que deseja sair da sua conta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _apiService.logout();
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }
}
