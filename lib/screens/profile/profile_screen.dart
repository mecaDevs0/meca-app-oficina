import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../../services/theme_service.dart';
import '../../widgets/animation_widgets.dart';
import '../../widgets/image_picker_widget.dart';
import '../../widgets/theme_switch_widget.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _workshopData;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadWorkshopData();
  }

  Future<void> _loadWorkshopData() async {
    setState(() => _isLoading = true);
    
    try {
      final token = await StorageService.getToken();
      if (token == null) {
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      await _apiService.loadToken();
      
      // Adicionar timeout para evitar loading infinito
      final response = await _apiService.getProfile().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Timeout ao carregar dados da oficina');
        },
      );
      
      if (response['success']) {
        print('Profile data: ${response['data']}');
        setState(() {
          _workshopData = response['data'];
        });
      } else {
        print('Erro na resposta da API: ${response['error']}');
        // Carregar dados mockados em caso de erro
        setState(() {
          _workshopData = {
            'name': 'Oficina Demo',
            'cnpj': '12.345.678/0001-90',
            'email': 'contato@oficinademo.com',
            'phone': '(11) 99999-9999',
            'address': 'Rua das Oficinas, 123',
            'status': 'ativa',
          };
        });
      }
      
    } catch (e) {
      print('Erro ao carregar dados da oficina: $e');
      // Carregar dados mockados em caso de erro
      setState(() {
        _workshopData = {
          'name': 'Oficina Demo',
          'cnpj': '12.345.678/0001-90',
          'email': 'contato@oficinademo.com',
          'phone': '(11) 99999-9999',
          'address': 'Rua das Oficinas, 123',
          'status': 'ativa',
        };
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onLogoSelected(String imagePath) {
    // Recarregar dados após upload
    _loadWorkshopData();
  }

  void _onLogoRemoved() {
    // Recarregar dados após remoção
    _loadWorkshopData();
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final isDark = themeService.isDarkMode;
    final bgColor = ThemeService.getBackgroundColor(isDark);
    final textColor = ThemeService.getTextColor(isDark);
    final secondaryTextColor = ThemeService.getSecondaryTextColor(isDark);
    final cardColor = ThemeService.getCardColor(isDark);
    final borderColor = ThemeService.getBorderColor(isDark);
    
    return Scaffold(
      backgroundColor: bgColor,
      body: _isLoading
          ? AnimationWidgets.buildLoadingWidget(
              message: 'Carregando dados da oficina...',
              size: 200,
            )
          : RefreshIndicator(
              onRefresh: _loadWorkshopData,
              color: const Color(0xFF00C977),
              backgroundColor: cardColor,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Header
                  SliverAppBar(
                    expandedHeight: 120,
                    floating: false,
                    pinned: true,
                    backgroundColor: bgColor,
                    elevation: 0,
                    actions: [
                      const ThemeSwitchButton(),
                      IconButton(
                        onPressed: _logout,
                        icon: Icon(Icons.logout, color: textColor),
                      ),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isDark
                                ? [
                                    const Color(0xFF0A0A0A),
                                    const Color(0xFF1A1A1A),
                                  ]
                                : [
                                    const Color(0xFFF5F7FA),
                                    const Color(0xFFE5E7EB),
                            ],
                          ),
                        ),
                        child: SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Perfil',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: textColor,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Gerencie suas informações',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: secondaryTextColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Content
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Profile Card
                          _buildProfileCard(),
                          const SizedBox(height: 24),
                          
                          // Logo Section
                          _buildLogoSection(),
                          const SizedBox(height: 24),
                          
                          // Location Section
                          _buildLocationSection(),
                          const SizedBox(height: 24),
                          
                          // Menu Options
                          _buildMenuOptions(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileCard() {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    final isDark = themeService.isDarkMode;
    final textColor = ThemeService.getTextColor(isDark);
    final secondaryTextColor = ThemeService.getSecondaryTextColor(isDark);
    final cardColor = ThemeService.getCardColor(isDark);
    final borderColor = ThemeService.getBorderColor(isDark);
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark 
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header com ícone
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF00C977).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.business,
                  color: Color(0xFF00C977),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informações da Oficina',
                      style: TextStyle(
                        fontSize: 14,
                        color: secondaryTextColor,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Dados principais',
                      style: TextStyle(
                        fontSize: 12,
                        color: secondaryTextColor.withOpacity(0.7),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Workshop Name
          Text(
            _workshopData?['name'] ?? 
            _workshopData?['nome'] ?? 
            _workshopData?['business_name'] ?? 
            _workshopData?['title'] ?? 
            _workshopData?['company_name'] ??
            'Oficina Demo',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: textColor,
              letterSpacing: -0.5,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          
          // CNPJ
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark 
                  ? Colors.grey.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.badge,
                  size: 16,
                  color: secondaryTextColor,
                ),
                const SizedBox(width: 8),
            Text(
                  'CNPJ: ${_workshopData?['cnpj'] ?? '12.345.678/0001-90'}',
                  style: TextStyle(
                fontSize: 14,
                    color: secondaryTextColor,
                    fontWeight: FontWeight.w500,
              ),
            ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          // Status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF00C977).withOpacity(isDark ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF00C977).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF00C977),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Oficina Ativa',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF00C977),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoSection() {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    final isDark = themeService.isDarkMode;
    final cardColor = ThemeService.getCardColor(isDark);
    final borderColor = ThemeService.getBorderColor(isDark);
    final textColor = ThemeService.getTextColor(isDark);
    final secondaryTextColor = ThemeService.getSecondaryTextColor(isDark);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
        boxShadow: isDark ? [] : [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00C977).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.image,
                  color: Color(0xFF00C977),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Logo da Oficina',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ImagePickerWidget(
                imageType: 'logo',
                currentImageUrl: _workshopData?['logo_url'],
                onImageSelected: _onLogoSelected,
                onImageRemoved: _onLogoRemoved,
                width: 100,
                height: 100,
                placeholder: 'Logo',
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Adicione o logo da sua oficina',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Tamanho recomendado: 512x512px\nFormatos: JPG, PNG, WebP\nTamanho máximo: 2MB',
                      style: TextStyle(
                        fontSize: 13,
                        color: secondaryTextColor,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    final isDark = themeService.isDarkMode;
    final cardColor = ThemeService.getCardColor(isDark);
    final borderColor = ThemeService.getBorderColor(isDark);
    final textColor = ThemeService.getTextColor(isDark);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
        boxShadow: isDark ? [] : [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00C977).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.location_on,
                  color: Color(0xFF00C977),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Localização',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // TODO: Adicionar API key do Google Maps
          // WorkshopMapWidget(
          //   initialLatitude: _workshopData?['latitude']?.toDouble(),
          //   initialLongitude: _workshopData?['longitude']?.toDouble(),
          //   workshopName: _workshopData?['name'],
          //   workshopAddress: _workshopData?['address'],
          //   isEditable: false,
          // ),
        ],
      ),
    );
  }

  Widget _buildMenuOptions() {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    final isDark = themeService.isDarkMode;
    final textColor = ThemeService.getTextColor(isDark);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Configurações',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        const SizedBox(height: 16),
        
        _buildMenuOption(
          icon: Icons.analytics,
          title: 'Insights & Analytics',
          subtitle: 'Métricas e performance da oficina',
          onTap: () => Navigator.pushNamed(context, '/insights'),
        ),
        _buildMenuOption(
          icon: Icons.notifications,
          title: 'Notificações',
          subtitle: 'Central de notificações e alertas',
          onTap: () => Navigator.pushNamed(context, '/notifications'),
        ),
        _buildMenuOption(
          icon: Icons.payment,
          title: 'PagBank',
          subtitle: 'Configuração de pagamentos',
          onTap: () => Navigator.pushNamed(context, '/config/pagbank'),
        ),
        
        _buildMenuOption(
          icon: Icons.help,
          title: 'Central de Ajuda',
          subtitle: 'Dúvidas e suporte',
          onTap: () => _showHelp(),
        ),
        _buildMenuOption(
          icon: Icons.logout,
          title: 'Sair',
          subtitle: 'Fazer logout da conta',
          onTap: () => _logout(),
          isDestructive: true,
        ),
      ],
    );
  }

  Widget _buildMenuOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    final isDark = themeService.isDarkMode;
    final cardColor = ThemeService.getCardColor(isDark);
    final borderColor = ThemeService.getBorderColor(isDark);
    final textColor = ThemeService.getTextColor(isDark);
    final secondaryTextColor = ThemeService.getSecondaryTextColor(isDark);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: 1,
            ),
            boxShadow: isDark ? [] : [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (isDestructive ? const Color(0xFFEF4444) : const Color(0xFF00C977)).withOpacity(isDark ? 0.2 : 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isDestructive ? const Color(0xFFEF4444) : const Color(0xFF00C977),
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: secondaryTextColor,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHelp() {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    final isDark = themeService.isDarkMode;
    final cardColor = ThemeService.getCardColor(isDark);
    final textColor = ThemeService.getTextColor(isDark);
    final secondaryTextColor = ThemeService.getSecondaryTextColor(isDark);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        title: Text(
          'Central de Ajuda',
          style: TextStyle(color: textColor),
        ),
        content: Text(
          'Para suporte, entre em contato:\n\nEmail: suporte@meca.com.br\nTelefone: (11) 99999-9999\n\nHorário de atendimento:\nSegunda a Sexta: 8h às 18h',
          style: TextStyle(color: secondaryTextColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Fechar',
              style: TextStyle(color: Color(0xFF00C977)),
            ),
          ),
        ],
      ),
    );
  }

  void _logout() {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    final isDark = themeService.isDarkMode;
    final cardColor = ThemeService.getCardColor(isDark);
    final textColor = ThemeService.getTextColor(isDark);
    final secondaryTextColor = ThemeService.getSecondaryTextColor(isDark);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        title: Text(
          'Confirmar Logout',
          style: TextStyle(color: textColor),
        ),
        content: Text(
          'Tem certeza que deseja sair da sua conta?',
          style: TextStyle(color: secondaryTextColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: TextStyle(color: secondaryTextColor),
            ),
          ),
          TextButton(
            onPressed: () async {
              await StorageService.clearToken();
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: const Text(
              'Sair',
              style: TextStyle(color: Color(0xFFEF4444)),
            ),
          ),
        ],
      ),
    );
  }
}

          subtitle: 'Central de notificações e alertas',
          onTap: () => Navigator.pushNamed(context, '/notifications'),
        ),
        _buildMenuOption(
          icon: Icons.payment,
          title: 'PagBank',
          subtitle: 'Configuração de pagamentos',
          onTap: () => Navigator.pushNamed(context, '/config/pagbank'),
        ),
        
        _buildMenuOption(
          icon: Icons.help,
          title: 'Central de Ajuda',
          subtitle: 'Dúvidas e suporte',
          onTap: () => _showHelp(),
        ),
        _buildMenuOption(
          icon: Icons.logout,
          title: 'Sair',
          subtitle: 'Fazer logout da conta',
          onTap: () => _logout(),
          isDestructive: true,
        ),
      ],
    );
  }

  Widget _buildMenuOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    final isDark = themeService.isDarkMode;
    final cardColor = ThemeService.getCardColor(isDark);
    final borderColor = ThemeService.getBorderColor(isDark);
    final textColor = ThemeService.getTextColor(isDark);
    final secondaryTextColor = ThemeService.getSecondaryTextColor(isDark);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: 1,
            ),
            boxShadow: isDark ? [] : [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (isDestructive ? const Color(0xFFEF4444) : const Color(0xFF00C977)).withOpacity(isDark ? 0.2 : 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isDestructive ? const Color(0xFFEF4444) : const Color(0xFF00C977),
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: secondaryTextColor,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHelp() {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    final isDark = themeService.isDarkMode;
    final cardColor = ThemeService.getCardColor(isDark);
    final textColor = ThemeService.getTextColor(isDark);
    final secondaryTextColor = ThemeService.getSecondaryTextColor(isDark);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        title: Text(
          'Central de Ajuda',
          style: TextStyle(color: textColor),
        ),
        content: Text(
          'Para suporte, entre em contato:\n\nEmail: suporte@meca.com.br\nTelefone: (11) 99999-9999\n\nHorário de atendimento:\nSegunda a Sexta: 8h às 18h',
          style: TextStyle(color: secondaryTextColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Fechar',
              style: TextStyle(color: Color(0xFF00C977)),
            ),
          ),
        ],
      ),
    );
  }

  void _logout() {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    final isDark = themeService.isDarkMode;
    final cardColor = ThemeService.getCardColor(isDark);
    final textColor = ThemeService.getTextColor(isDark);
    final secondaryTextColor = ThemeService.getSecondaryTextColor(isDark);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        title: Text(
          'Confirmar Logout',
          style: TextStyle(color: textColor),
        ),
        content: Text(
          'Tem certeza que deseja sair da sua conta?',
          style: TextStyle(color: secondaryTextColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: TextStyle(color: secondaryTextColor),
            ),
          ),
          TextButton(
            onPressed: () async {
              await StorageService.clearToken();
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: const Text(
              'Sair',
              style: TextStyle(color: Color(0xFFEF4444)),
            ),
          ),
        ],
      ),
    );
  }
}

          subtitle: 'Central de notificações e alertas',
          onTap: () => Navigator.pushNamed(context, '/notifications'),
        ),
        _buildMenuOption(
          icon: Icons.payment,
          title: 'PagBank',
          subtitle: 'Configuração de pagamentos',
          onTap: () => Navigator.pushNamed(context, '/config/pagbank'),
        ),
        
        _buildMenuOption(
          icon: Icons.help,
          title: 'Central de Ajuda',
          subtitle: 'Dúvidas e suporte',
          onTap: () => _showHelp(),
        ),
        _buildMenuOption(
          icon: Icons.logout,
          title: 'Sair',
          subtitle: 'Fazer logout da conta',
          onTap: () => _logout(),
          isDestructive: true,
        ),
      ],
    );
  }

  Widget _buildMenuOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    final isDark = themeService.isDarkMode;
    final cardColor = ThemeService.getCardColor(isDark);
    final borderColor = ThemeService.getBorderColor(isDark);
    final textColor = ThemeService.getTextColor(isDark);
    final secondaryTextColor = ThemeService.getSecondaryTextColor(isDark);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: 1,
            ),
            boxShadow: isDark ? [] : [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (isDestructive ? const Color(0xFFEF4444) : const Color(0xFF00C977)).withOpacity(isDark ? 0.2 : 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isDestructive ? const Color(0xFFEF4444) : const Color(0xFF00C977),
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: secondaryTextColor,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHelp() {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    final isDark = themeService.isDarkMode;
    final cardColor = ThemeService.getCardColor(isDark);
    final textColor = ThemeService.getTextColor(isDark);
    final secondaryTextColor = ThemeService.getSecondaryTextColor(isDark);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        title: Text(
          'Central de Ajuda',
          style: TextStyle(color: textColor),
        ),
        content: Text(
          'Para suporte, entre em contato:\n\nEmail: suporte@meca.com.br\nTelefone: (11) 99999-9999\n\nHorário de atendimento:\nSegunda a Sexta: 8h às 18h',
          style: TextStyle(color: secondaryTextColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Fechar',
              style: TextStyle(color: Color(0xFF00C977)),
            ),
          ),
        ],
      ),
    );
  }

  void _logout() {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    final isDark = themeService.isDarkMode;
    final cardColor = ThemeService.getCardColor(isDark);
    final textColor = ThemeService.getTextColor(isDark);
    final secondaryTextColor = ThemeService.getSecondaryTextColor(isDark);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        title: Text(
          'Confirmar Logout',
          style: TextStyle(color: textColor),
        ),
        content: Text(
          'Tem certeza que deseja sair da sua conta?',
          style: TextStyle(color: secondaryTextColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: TextStyle(color: secondaryTextColor),
            ),
          ),
          TextButton(
            onPressed: () async {
              await StorageService.clearToken();
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: const Text(
              'Sair',
              style: TextStyle(color: Color(0xFFEF4444)),
            ),
          ),
        ],
      ),
    );
  }
}

          subtitle: 'Central de notificações e alertas',
          onTap: () => Navigator.pushNamed(context, '/notifications'),
        ),
        _buildMenuOption(
          icon: Icons.payment,
          title: 'PagBank',
          subtitle: 'Configuração de pagamentos',
          onTap: () => Navigator.pushNamed(context, '/config/pagbank'),
        ),
        
        _buildMenuOption(
          icon: Icons.help,
          title: 'Central de Ajuda',
          subtitle: 'Dúvidas e suporte',
          onTap: () => _showHelp(),
        ),
        _buildMenuOption(
          icon: Icons.logout,
          title: 'Sair',
          subtitle: 'Fazer logout da conta',
          onTap: () => _logout(),
          isDestructive: true,
        ),
      ],
    );
  }

  Widget _buildMenuOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    final isDark = themeService.isDarkMode;
    final cardColor = ThemeService.getCardColor(isDark);
    final borderColor = ThemeService.getBorderColor(isDark);
    final textColor = ThemeService.getTextColor(isDark);
    final secondaryTextColor = ThemeService.getSecondaryTextColor(isDark);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: 1,
            ),
            boxShadow: isDark ? [] : [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (isDestructive ? const Color(0xFFEF4444) : const Color(0xFF00C977)).withOpacity(isDark ? 0.2 : 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isDestructive ? const Color(0xFFEF4444) : const Color(0xFF00C977),
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: secondaryTextColor,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHelp() {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    final isDark = themeService.isDarkMode;
    final cardColor = ThemeService.getCardColor(isDark);
    final textColor = ThemeService.getTextColor(isDark);
    final secondaryTextColor = ThemeService.getSecondaryTextColor(isDark);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        title: Text(
          'Central de Ajuda',
          style: TextStyle(color: textColor),
        ),
        content: Text(
          'Para suporte, entre em contato:\n\nEmail: suporte@meca.com.br\nTelefone: (11) 99999-9999\n\nHorário de atendimento:\nSegunda a Sexta: 8h às 18h',
          style: TextStyle(color: secondaryTextColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Fechar',
              style: TextStyle(color: Color(0xFF00C977)),
            ),
          ),
        ],
      ),
    );
  }

  void _logout() {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    final isDark = themeService.isDarkMode;
    final cardColor = ThemeService.getCardColor(isDark);
    final textColor = ThemeService.getTextColor(isDark);
    final secondaryTextColor = ThemeService.getSecondaryTextColor(isDark);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        title: Text(
          'Confirmar Logout',
          style: TextStyle(color: textColor),
        ),
        content: Text(
          'Tem certeza que deseja sair da sua conta?',
          style: TextStyle(color: secondaryTextColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: TextStyle(color: secondaryTextColor),
            ),
          ),
          TextButton(
            onPressed: () async {
              await StorageService.clearToken();
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: const Text(
              'Sair',
              style: TextStyle(color: Color(0xFFEF4444)),
            ),
          ),
        ],
      ),
    );
  }
}

          subtitle: 'Central de notificações e alertas',
          onTap: () => Navigator.pushNamed(context, '/notifications'),
        ),
        _buildMenuOption(
          icon: Icons.payment,
          title: 'PagBank',
          subtitle: 'Configuração de pagamentos',
          onTap: () => Navigator.pushNamed(context, '/config/pagbank'),
        ),
        
        _buildMenuOption(
          icon: Icons.help,
          title: 'Central de Ajuda',
          subtitle: 'Dúvidas e suporte',
          onTap: () => _showHelp(),
        ),
        _buildMenuOption(
          icon: Icons.logout,
          title: 'Sair',
          subtitle: 'Fazer logout da conta',
          onTap: () => _logout(),
          isDestructive: true,
        ),
      ],
    );
  }

  Widget _buildMenuOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    final isDark = themeService.isDarkMode;
    final cardColor = ThemeService.getCardColor(isDark);
    final borderColor = ThemeService.getBorderColor(isDark);
    final textColor = ThemeService.getTextColor(isDark);
    final secondaryTextColor = ThemeService.getSecondaryTextColor(isDark);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: 1,
            ),
            boxShadow: isDark ? [] : [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (isDestructive ? const Color(0xFFEF4444) : const Color(0xFF00C977)).withOpacity(isDark ? 0.2 : 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isDestructive ? const Color(0xFFEF4444) : const Color(0xFF00C977),
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: secondaryTextColor,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHelp() {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    final isDark = themeService.isDarkMode;
    final cardColor = ThemeService.getCardColor(isDark);
    final textColor = ThemeService.getTextColor(isDark);
    final secondaryTextColor = ThemeService.getSecondaryTextColor(isDark);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        title: Text(
          'Central de Ajuda',
          style: TextStyle(color: textColor),
        ),
        content: Text(
          'Para suporte, entre em contato:\n\nEmail: suporte@meca.com.br\nTelefone: (11) 99999-9999\n\nHorário de atendimento:\nSegunda a Sexta: 8h às 18h',
          style: TextStyle(color: secondaryTextColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Fechar',
              style: TextStyle(color: Color(0xFF00C977)),
            ),
          ),
        ],
      ),
    );
  }

  void _logout() {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    final isDark = themeService.isDarkMode;
    final cardColor = ThemeService.getCardColor(isDark);
    final textColor = ThemeService.getTextColor(isDark);
    final secondaryTextColor = ThemeService.getSecondaryTextColor(isDark);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        title: Text(
          'Confirmar Logout',
          style: TextStyle(color: textColor),
        ),
        content: Text(
          'Tem certeza que deseja sair da sua conta?',
          style: TextStyle(color: secondaryTextColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: TextStyle(color: secondaryTextColor),
            ),
          ),
          TextButton(
            onPressed: () async {
              await StorageService.clearToken();
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: const Text(
              'Sair',
              style: TextStyle(color: Color(0xFFEF4444)),
            ),
          ),
        ],
      ),
    );
  }
}

          subtitle: 'Central de notificações e alertas',
          onTap: () => Navigator.pushNamed(context, '/notifications'),
        ),
        _buildMenuOption(
          icon: Icons.payment,
          title: 'PagBank',
          subtitle: 'Configuração de pagamentos',
          onTap: () => Navigator.pushNamed(context, '/config/pagbank'),
        ),
        
        _buildMenuOption(
          icon: Icons.help,
          title: 'Central de Ajuda',
          subtitle: 'Dúvidas e suporte',
          onTap: () => _showHelp(),
        ),
        _buildMenuOption(
          icon: Icons.logout,
          title: 'Sair',
          subtitle: 'Fazer logout da conta',
          onTap: () => _logout(),
          isDestructive: true,
        ),
      ],
    );
  }

  Widget _buildMenuOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    final isDark = themeService.isDarkMode;
    final cardColor = ThemeService.getCardColor(isDark);
    final borderColor = ThemeService.getBorderColor(isDark);
    final textColor = ThemeService.getTextColor(isDark);
    final secondaryTextColor = ThemeService.getSecondaryTextColor(isDark);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: 1,
            ),
            boxShadow: isDark ? [] : [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (isDestructive ? const Color(0xFFEF4444) : const Color(0xFF00C977)).withOpacity(isDark ? 0.2 : 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isDestructive ? const Color(0xFFEF4444) : const Color(0xFF00C977),
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: secondaryTextColor,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHelp() {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    final isDark = themeService.isDarkMode;
    final cardColor = ThemeService.getCardColor(isDark);
    final textColor = ThemeService.getTextColor(isDark);
    final secondaryTextColor = ThemeService.getSecondaryTextColor(isDark);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        title: Text(
          'Central de Ajuda',
          style: TextStyle(color: textColor),
        ),
        content: Text(
          'Para suporte, entre em contato:\n\nEmail: suporte@meca.com.br\nTelefone: (11) 99999-9999\n\nHorário de atendimento:\nSegunda a Sexta: 8h às 18h',
          style: TextStyle(color: secondaryTextColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Fechar',
              style: TextStyle(color: Color(0xFF00C977)),
            ),
          ),
        ],
      ),
    );
  }

  void _logout() {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    final isDark = themeService.isDarkMode;
    final cardColor = ThemeService.getCardColor(isDark);
    final textColor = ThemeService.getTextColor(isDark);
    final secondaryTextColor = ThemeService.getSecondaryTextColor(isDark);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        title: Text(
          'Confirmar Logout',
          style: TextStyle(color: textColor),
        ),
        content: Text(
          'Tem certeza que deseja sair da sua conta?',
          style: TextStyle(color: secondaryTextColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: TextStyle(color: secondaryTextColor),
            ),
          ),
          TextButton(
            onPressed: () async {
              await StorageService.clearToken();
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: const Text(
              'Sair',
              style: TextStyle(color: Color(0xFFEF4444)),
            ),
          ),
        ],
      ),
    );
  }
}

          subtitle: 'Central de notificações e alertas',
          onTap: () => Navigator.pushNamed(context, '/notifications'),
        ),
        _buildMenuOption(
          icon: Icons.payment,
          title: 'PagBank',
          subtitle: 'Configuração de pagamentos',
          onTap: () => Navigator.pushNamed(context, '/config/pagbank'),
        ),
        
        _buildMenuOption(
          icon: Icons.help,
          title: 'Central de Ajuda',
          subtitle: 'Dúvidas e suporte',
          onTap: () => _showHelp(),
        ),
        _buildMenuOption(
          icon: Icons.logout,
          title: 'Sair',
          subtitle: 'Fazer logout da conta',
          onTap: () => _logout(),
          isDestructive: true,
        ),
      ],
    );
  }

  Widget _buildMenuOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    final isDark = themeService.isDarkMode;
    final cardColor = ThemeService.getCardColor(isDark);
    final borderColor = ThemeService.getBorderColor(isDark);
    final textColor = ThemeService.getTextColor(isDark);
    final secondaryTextColor = ThemeService.getSecondaryTextColor(isDark);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: 1,
            ),
            boxShadow: isDark ? [] : [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (isDestructive ? const Color(0xFFEF4444) : const Color(0xFF00C977)).withOpacity(isDark ? 0.2 : 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isDestructive ? const Color(0xFFEF4444) : const Color(0xFF00C977),
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: secondaryTextColor,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHelp() {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    final isDark = themeService.isDarkMode;
    final cardColor = ThemeService.getCardColor(isDark);
    final textColor = ThemeService.getTextColor(isDark);
    final secondaryTextColor = ThemeService.getSecondaryTextColor(isDark);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        title: Text(
          'Central de Ajuda',
          style: TextStyle(color: textColor),
        ),
        content: Text(
          'Para suporte, entre em contato:\n\nEmail: suporte@meca.com.br\nTelefone: (11) 99999-9999\n\nHorário de atendimento:\nSegunda a Sexta: 8h às 18h',
          style: TextStyle(color: secondaryTextColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Fechar',
              style: TextStyle(color: Color(0xFF00C977)),
            ),
          ),
        ],
      ),
    );
  }

  void _logout() {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    final isDark = themeService.isDarkMode;
    final cardColor = ThemeService.getCardColor(isDark);
    final textColor = ThemeService.getTextColor(isDark);
    final secondaryTextColor = ThemeService.getSecondaryTextColor(isDark);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        title: Text(
          'Confirmar Logout',
          style: TextStyle(color: textColor),
        ),
        content: Text(
          'Tem certeza que deseja sair da sua conta?',
          style: TextStyle(color: secondaryTextColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: TextStyle(color: secondaryTextColor),
            ),
          ),
          TextButton(
            onPressed: () async {
              await StorageService.clearToken();
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: const Text(
              'Sair',
              style: TextStyle(color: Color(0xFFEF4444)),
            ),
          ),
        ],
      ),
    );
  }
}

          subtitle: 'Central de notificações e alertas',
          onTap: () => Navigator.pushNamed(context, '/notifications'),
        ),
        _buildMenuOption(
          icon: Icons.payment,
          title: 'PagBank',
          subtitle: 'Configuração de pagamentos',
          onTap: () => Navigator.pushNamed(context, '/config/pagbank'),
        ),
        
        _buildMenuOption(
          icon: Icons.help,
          title: 'Central de Ajuda',
          subtitle: 'Dúvidas e suporte',
          onTap: () => _showHelp(),
        ),
        _buildMenuOption(
          icon: Icons.logout,
          title: 'Sair',
          subtitle: 'Fazer logout da conta',
          onTap: () => _logout(),
          isDestructive: true,
        ),
      ],
    );
  }

  Widget _buildMenuOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    final isDark = themeService.isDarkMode;
    final cardColor = ThemeService.getCardColor(isDark);
    final borderColor = ThemeService.getBorderColor(isDark);
    final textColor = ThemeService.getTextColor(isDark);
    final secondaryTextColor = ThemeService.getSecondaryTextColor(isDark);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: 1,
            ),
            boxShadow: isDark ? [] : [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (isDestructive ? const Color(0xFFEF4444) : const Color(0xFF00C977)).withOpacity(isDark ? 0.2 : 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isDestructive ? const Color(0xFFEF4444) : const Color(0xFF00C977),
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: secondaryTextColor,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHelp() {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    final isDark = themeService.isDarkMode;
    final cardColor = ThemeService.getCardColor(isDark);
    final textColor = ThemeService.getTextColor(isDark);
    final secondaryTextColor = ThemeService.getSecondaryTextColor(isDark);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        title: Text(
          'Central de Ajuda',
          style: TextStyle(color: textColor),
        ),
        content: Text(
          'Para suporte, entre em contato:\n\nEmail: suporte@meca.com.br\nTelefone: (11) 99999-9999\n\nHorário de atendimento:\nSegunda a Sexta: 8h às 18h',
          style: TextStyle(color: secondaryTextColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Fechar',
              style: TextStyle(color: Color(0xFF00C977)),
            ),
          ),
        ],
      ),
    );
  }

  void _logout() {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    final isDark = themeService.isDarkMode;
    final cardColor = ThemeService.getCardColor(isDark);
    final textColor = ThemeService.getTextColor(isDark);
    final secondaryTextColor = ThemeService.getSecondaryTextColor(isDark);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        title: Text(
          'Confirmar Logout',
          style: TextStyle(color: textColor),
        ),
        content: Text(
          'Tem certeza que deseja sair da sua conta?',
          style: TextStyle(color: secondaryTextColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: TextStyle(color: secondaryTextColor),
            ),
          ),
          TextButton(
            onPressed: () async {
              await StorageService.clearToken();
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: const Text(
              'Sair',
              style: TextStyle(color: Color(0xFFEF4444)),
            ),
          ),
        ],
      ),
    );
  }
}