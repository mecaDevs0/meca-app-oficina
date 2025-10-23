import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../../services/theme_service.dart';
import '../../widgets/theme_switch_widget.dart';

class ServicesConfigScreen extends StatefulWidget {
  const ServicesConfigScreen({Key? key}) : super(key: key);

  @override
  State<ServicesConfigScreen> createState() => _ServicesConfigScreenState();
}

class _ServicesConfigScreenState extends State<ServicesConfigScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasChanges = false; // Track if services were added
  List<Map<String, dynamic>> _myServices = [];
  List<Map<String, dynamic>> _masterServices = [];
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    setState(() => _isLoading = true);
    
    try {
      final token = await StorageService.getToken();
      if (token == null) {
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      await _apiService.loadToken();
      
      // Carregar serviços da oficina
      final myServicesResponse = await _apiService.getMyServices();
      if (myServicesResponse['success']) {
        setState(() {
          _myServices = List<Map<String, dynamic>>.from(myServicesResponse['data']['services'] ?? []);
        });
      }

      // Carregar serviços master disponíveis
      final masterServicesResponse = await _apiService.getMasterServices();
      if (masterServicesResponse['success']) {
        setState(() {
          _masterServices = List<Map<String, dynamic>>.from(masterServicesResponse['data']['services'] ?? []);
        });
      }
      
    } catch (e) {
      print('Erro ao carregar serviços: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showAddServiceDialog(Map<String, dynamic> service) {
    final priceController = TextEditingController();
    final durationController = TextEditingController();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF00C977).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00C977).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.add_circle_outline,
                      color: Color(0xFF00C977),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Adicionar Serviço',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          service['title'] ?? 'Serviço',
                          style: const TextStyle(
                            color: Color(0xFF8B8B8B),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close,
                      color: Color(0xFF8B8B8B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Description
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  service['description'] ?? 'Serviço de qualidade',
                  style: const TextStyle(
                    color: Color(0xFFB8B8B8),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Price field
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Preço (R\$) - Opcional',
                  labelStyle: const TextStyle(color: Color(0xFF8B8B8B)),
                  prefixIcon: const Icon(Icons.attach_money, color: Color(0xFF00C977)),
                  filled: true,
                  fillColor: const Color(0xFF2A2A2A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF444444)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF00C977), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Duration field
              TextField(
                controller: durationController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Duração (minutos) - Opcional',
                  labelStyle: const TextStyle(color: Color(0xFF8B8B8B)),
                  prefixIcon: const Icon(Icons.access_time, color: Color(0xFF00C977)),
                  filled: true,
                  fillColor: const Color(0xFF2A2A2A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF444444)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF00C977), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(
                          color: Color(0xFF8B8B8B),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final price = priceController.text.isNotEmpty 
                            ? double.tryParse(priceController.text) ?? 0.0
                            : 0.0;
                        final duration = durationController.text.isNotEmpty
                            ? int.tryParse(durationController.text) ?? 0
                            : 0;
                        
                        Navigator.pop(context);
                        _addService(service, price, duration);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00C977),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Adicionar',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addService(Map<String, dynamic> masterService, double price, int duration) async {
    setState(() => _isSaving = true);
    
    try {
      final response = await _apiService.addService(
        title: masterService['title'],
        price: price,
        durationMinutes: duration,
        description: masterService['description'],
        thumbnail: masterService['image_url'],
      );
      
      if (response['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Serviço adicionado com sucesso!'),
            backgroundColor: Color(0xFF00C977),
          ),
        );
        await _loadServices(); // Recarregar lista
        // Marcar que houve mudança para a home recarregar
        _hasChanges = true;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: ${response['error']}'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Retornar true se houve mudanças para a home recarregar
        Navigator.pop(context, _hasChanges);
        return false;
      },
      child: Scaffold(
        backgroundColor: ThemeService.getBackgroundColor(Provider.of<ThemeService>(context, listen: false).isDarkMode),
        appBar: AppBar(
          title: const Text('Serviços'),
          backgroundColor: ThemeService.getBackgroundColor(Provider.of<ThemeService>(context, listen: false).isDarkMode),
          elevation: 0,
          foregroundColor: ThemeService.getTextColor(Provider.of<ThemeService>(context, listen: false).isDarkMode),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, _hasChanges),
          ),
          actions: [
            const ThemeSwitchButton(),
            if (!_isLoading)
              TextButton(
                onPressed: _isSaving ? null : _loadServices,
                child: const Icon(
                  Icons.refresh,
                  color: Color(0xFF00C977),
                ),
              ),
          ],
        ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00C977)),
              ),
            )
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Meus Serviços',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: ThemeService.getTextColor(Provider.of<ThemeService>(context, listen: false).isDarkMode),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Gerencie os serviços oferecidos pela sua oficina',
                          style: TextStyle(
                            fontSize: 16,
                            color: ThemeService.getSecondaryTextColor(Provider.of<ThemeService>(context, listen: false).isDarkMode),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Stats
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF1A1A1A),
                                Color(0xFF2A2A2A),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF333333),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildStatItem(
                                  icon: Icons.build,
                                  value: '${_myServices.length}',
                                  label: 'Ativos',
                                  color: const Color(0xFF00C977),
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 40,
                                color: const Color(0xFF333333),
                              ),
                              Expanded(
                                child: _buildStatItem(
                                  icon: Icons.add,
                                  value: '${_masterServices.length}',
                                  label: 'Disponíveis',
                                  color: const Color(0xFF3B82F6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // My services
                if (_myServices.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'Serviços Ativos',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: ThemeService.getTextColor(Provider.of<ThemeService>(context, listen: false).isDarkMode),
                        ),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final service = _myServices[index];
                        return _buildMyServiceCard(service);
                      },
                      childCount: _myServices.length,
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                ],
                
                // Available services
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Serviços Disponíveis',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: ThemeService.getTextColor(Provider.of<ThemeService>(context, listen: false).isDarkMode),
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                
                // Master services grid
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.8,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final service = _masterServices[index];
                        final isAlreadyAdded = _myServices.any((s) => s['title'] == service['title']);
                        return _buildMasterServiceCard(service, isAlreadyAdded);
                      },
                      childCount: _masterServices.length,
                    ),
                  ),
                ),
                
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: ThemeService.getTextColor(Provider.of<ThemeService>(context, listen: false).isDarkMode),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: ThemeService.getSecondaryTextColor(Provider.of<ThemeService>(context, listen: false).isDarkMode),
          ),
        ),
      ],
    );
  }

  Widget _buildMyServiceCard(Map<String, dynamic> service) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16, left: 24, right: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A1A1A),
            Color(0xFF2A2A2A),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF333333),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Service image
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF00C977).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: service['thumbnail'] != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                          Uri.dataFromString(service['thumbnail']).data?.contentAsBytes() ?? Uint8List(0),
                      fit: BoxFit.cover,
                    ),
                  )
                : const Icon(
                    Icons.build,
                    color: Color(0xFF00C977),
                    size: 24,
                  ),
          ),
          const SizedBox(width: 16),
          
          // Service info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service['title'] ?? 'Serviço',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  service['description'] ?? '',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8B8B8B),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00C977).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'R\$ ${(service['price'] as num).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF00C977),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${service['duration_minutes']} min',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF3B82F6),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Status indicator
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF00C977),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMasterServiceCard(Map<String, dynamic> service, bool isAlreadyAdded) {
    final category = service['category'] as String? ?? 'Geral';
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A1A1A),
            const Color(0xFF2A2A2A),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAlreadyAdded ? const Color(0xFF00C977) : const Color(0xFF333333),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: isAlreadyAdded ? null : () => _showAddServiceDialog(service),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Service image
              Container(
                width: double.infinity,
                height: 60,
                decoration: BoxDecoration(
                  color: _getCategoryColor(category).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getCategoryIcon(category),
                  color: _getCategoryColor(category),
                  size: 24,
                ),
              ),
              const SizedBox(height: 8),
              
              // Service info
              Text(
                service['title'] ?? 'Serviço',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                category,
                style: TextStyle(
                  fontSize: 9,
                  color: _getCategoryColor(category),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              
              // Description
              Expanded(
                child: Text(
                  service['description'] ?? 'Serviço de qualidade',
                  style: const TextStyle(
                    fontSize: 9,
                    color: Color(0xFF8B8B8B),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 8),
              
              // Add button
              SizedBox(
                width: double.infinity,
                height: 32,
                child: ElevatedButton(
                  onPressed: isAlreadyAdded ? null : () => _showAddServiceDialog(service),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isAlreadyAdded 
                        ? const Color(0xFF00C977) 
                        : const Color(0xFF3B82F6),
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: Text(
                    isAlreadyAdded ? 'Adicionado' : 'Adicionar',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'manutenção':
        return const Color(0xFF00C977);
      case 'pneus':
        return const Color(0xFF374151);
      case 'freios':
        return const Color(0xFFEF4444);
      case 'eletrônica':
        return const Color(0xFF3B82F6);
      case 'climatização':
        return const Color(0xFF06B6A7);
      case 'suspensão':
        return const Color(0xFF8B5CF6);
      case 'transmissão':
        return const Color(0xFFF59E0B);
      case 'estética':
        return const Color(0xFFEC4899);
      default:
        return const Color(0xFF8B8B8B);
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'manutenção':
        return Icons.build;
      case 'pneus':
        return Icons.tire_repair;
      case 'freios':
        return Icons.stop_circle;
      case 'eletrônica':
        return Icons.electrical_services;
      case 'climatização':
        return Icons.ac_unit;
      case 'suspensão':
        return Icons.settings;
      case 'transmissão':
        return Icons.settings_applications;
      case 'estética':
        return Icons.cleaning_services;
      default:
        return Icons.build;
    }
  }
}

import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../../services/storage_service.dart';
import '../../services/api_service.dart';
import '../../widgets/image_picker_widget.dart';
import '../../widgets/theme_switch_widget.dart';

class ServicesConfigScreen extends StatefulWidget {
  const ServicesConfigScreen({Key? key}) : super(key: key);

  @override
  State<ServicesConfigScreen> createState() => _ServicesConfigScreenState();
}

class _ServicesConfigScreenState extends State<ServicesConfigScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  List<Map<String, dynamic>> _myServices = [];
  List<Map<String, dynamic>> _masterServices = [];
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    setState(() => _isLoading = true);
    
    try {
      final token = await StorageService.getToken();
      if (token == null) {
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      await _apiService.loadToken();
      
      // Carregar serviços da oficina
      final myServicesResponse = await _apiService.getMyServices();
      if (myServicesResponse['success']) {
        setState(() {
          _myServices = List<Map<String, dynamic>>.from(myServicesResponse['data']['services'] ?? []);
        });
      }

      // Carregar serviços master disponíveis
      final masterServicesResponse = await _apiService.getMasterServices();
      if (masterServicesResponse['success']) {
        setState(() {
          _masterServices = List<Map<String, dynamic>>.from(masterServicesResponse['data']['services'] ?? []);
        });
      }
      
    } catch (e) {
      print('Erro ao carregar serviços: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showAddServiceDialog(Map<String, dynamic> service) {
    final priceController = TextEditingController();
    final durationController = TextEditingController();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF00C977).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00C977).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.add_circle_outline,
                      color: Color(0xFF00C977),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Adicionar Serviço',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          service['title'] ?? 'Serviço',
                          style: const TextStyle(
                            color: Color(0xFF8B8B8B),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close,
                      color: Color(0xFF8B8B8B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Description
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  service['description'] ?? 'Serviço de qualidade',
                  style: const TextStyle(
                    color: Color(0xFFB8B8B8),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Price field
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Preço (R\$) - Opcional',
                  labelStyle: const TextStyle(color: Color(0xFF8B8B8B)),
                  prefixIcon: const Icon(Icons.attach_money, color: Color(0xFF00C977)),
                  filled: true,
                  fillColor: const Color(0xFF2A2A2A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF444444)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF00C977), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Duration field
              TextField(
                controller: durationController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Duração (minutos) - Opcional',
                  labelStyle: const TextStyle(color: Color(0xFF8B8B8B)),
                  prefixIcon: const Icon(Icons.access_time, color: Color(0xFF00C977)),
                  filled: true,
                  fillColor: const Color(0xFF2A2A2A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF444444)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF00C977), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(
                          color: Color(0xFF8B8B8B),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final price = priceController.text.isNotEmpty 
                            ? double.tryParse(priceController.text) ?? 0.0
                            : 0.0;
                        final duration = durationController.text.isNotEmpty
                            ? int.tryParse(durationController.text) ?? 0
                            : 0;
                        
                        Navigator.pop(context);
                        _addService(service, price, duration);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00C977),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Adicionar',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addService(Map<String, dynamic> masterService, double price, int duration) async {
    setState(() => _isSaving = true);
    
    try {
      final response = await _apiService.addService(
        title: masterService['title'],
        price: price,
        durationMinutes: duration,
        description: masterService['description'],
        thumbnail: masterService['image_url'],
      );
      
      if (response['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Serviço adicionado com sucesso!'),
            backgroundColor: Color(0xFF00C977),
          ),
        );
        _loadServices(); // Recarregar lista
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: ${response['error']}'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text('Serviços'),
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          const ThemeSwitchButton(),
          if (!_isLoading)
            TextButton(
              onPressed: _isSaving ? null : _loadServices,
              child: const Icon(
                Icons.refresh,
                color: Color(0xFF00C977),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00C977)),
              ),
            )
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Meus Serviços',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Gerencie os serviços oferecidos pela sua oficina',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF8B8B8B),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Stats
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF1A1A1A),
                                Color(0xFF2A2A2A),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF333333),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildStatItem(
                                  icon: Icons.build,
                                  value: '${_myServices.length}',
                                  label: 'Ativos',
                                  color: const Color(0xFF00C977),
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 40,
                                color: const Color(0xFF333333),
                              ),
                              Expanded(
                                child: _buildStatItem(
                                  icon: Icons.add,
                                  value: '${_masterServices.length}',
                                  label: 'Disponíveis',
                                  color: const Color(0xFF3B82F6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // My services
                if (_myServices.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'Serviços Ativos',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final service = _myServices[index];
                        return _buildMyServiceCard(service);
                      },
                      childCount: _myServices.length,
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                ],
                
                // Available services
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Serviços Disponíveis',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                
                // Master services grid
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.8,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final service = _masterServices[index];
                        final isAlreadyAdded = _myServices.any((s) => s['title'] == service['title']);
                        return _buildMasterServiceCard(service, isAlreadyAdded);
                      },
                      childCount: _masterServices.length,
                    ),
                  ),
                ),
                
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF8B8B8B),
          ),
        ),
      ],
    );
  }

  Widget _buildMyServiceCard(Map<String, dynamic> service) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16, left: 24, right: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A1A1A),
            Color(0xFF2A2A2A),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF333333),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Service image
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF00C977).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: service['thumbnail'] != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                          Uri.dataFromString(service['thumbnail']).data?.contentAsBytes() ?? Uint8List(0),
                      fit: BoxFit.cover,
                    ),
                  )
                : const Icon(
                    Icons.build,
                    color: Color(0xFF00C977),
                    size: 24,
                  ),
          ),
          const SizedBox(width: 16),
          
          // Service info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service['title'] ?? 'Serviço',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  service['description'] ?? '',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8B8B8B),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00C977).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'R\$ ${(service['price'] as num).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF00C977),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${service['duration_minutes']} min',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF3B82F6),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Status indicator
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF00C977),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMasterServiceCard(Map<String, dynamic> service, bool isAlreadyAdded) {
    final category = service['category'] as String? ?? 'Geral';
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A1A1A),
            const Color(0xFF2A2A2A),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAlreadyAdded ? const Color(0xFF00C977) : const Color(0xFF333333),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: isAlreadyAdded ? null : () => _showAddServiceDialog(service),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Service image
              Container(
                width: double.infinity,
                height: 60,
                decoration: BoxDecoration(
                  color: _getCategoryColor(category).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getCategoryIcon(category),
                  color: _getCategoryColor(category),
                  size: 24,
                ),
              ),
              const SizedBox(height: 8),
              
              // Service info
              Text(
                service['title'] ?? 'Serviço',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                category,
                style: TextStyle(
                  fontSize: 9,
                  color: _getCategoryColor(category),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              
              // Description
              Expanded(
                child: Text(
                  service['description'] ?? 'Serviço de qualidade',
                  style: const TextStyle(
                    fontSize: 9,
                    color: Color(0xFF8B8B8B),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 8),
              
              // Add button
              SizedBox(
                width: double.infinity,
                height: 32,
                child: ElevatedButton(
                  onPressed: isAlreadyAdded ? null : () => _showAddServiceDialog(service),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isAlreadyAdded 
                        ? const Color(0xFF00C977) 
                        : const Color(0xFF3B82F6),
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: Text(
                    isAlreadyAdded ? 'Adicionado' : 'Adicionar',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'manutenção':
        return const Color(0xFF00C977);
      case 'pneus':
        return const Color(0xFF374151);
      case 'freios':
        return const Color(0xFFEF4444);
      case 'eletrônica':
        return const Color(0xFF3B82F6);
      case 'climatização':
        return const Color(0xFF06B6A7);
      case 'suspensão':
        return const Color(0xFF8B5CF6);
      case 'transmissão':
        return const Color(0xFFF59E0B);
      case 'estética':
        return const Color(0xFFEC4899);
      default:
        return const Color(0xFF8B8B8B);
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'manutenção':
        return Icons.build;
      case 'pneus':
        return Icons.tire_repair;
      case 'freios':
        return Icons.stop_circle;
      case 'eletrônica':
        return Icons.electrical_services;
      case 'climatização':
        return Icons.ac_unit;
      case 'suspensão':
        return Icons.settings;
      case 'transmissão':
        return Icons.settings_applications;
      case 'estética':
        return Icons.cleaning_services;
      default:
        return Icons.build;
    }
  }
}
      case 'freios':
        return Icons.stop_circle;
      case 'eletrônica':
        return Icons.electrical_services;
      case 'climatização':
        return Icons.ac_unit;
      case 'suspensão':
        return Icons.settings;
      case 'transmissão':
        return Icons.settings_applications;
      case 'estética':
        return Icons.cleaning_services;
      default:
        return Icons.build;
    }
  }
}

import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../../services/storage_service.dart';
import '../../services/api_service.dart';
import '../../widgets/image_picker_widget.dart';
import '../../widgets/theme_switch_widget.dart';

class ServicesConfigScreen extends StatefulWidget {
  const ServicesConfigScreen({Key? key}) : super(key: key);

  @override
  State<ServicesConfigScreen> createState() => _ServicesConfigScreenState();
}

class _ServicesConfigScreenState extends State<ServicesConfigScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  List<Map<String, dynamic>> _myServices = [];
  List<Map<String, dynamic>> _masterServices = [];
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    setState(() => _isLoading = true);
    
    try {
      final token = await StorageService.getToken();
      if (token == null) {
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      await _apiService.loadToken();
      
      // Carregar serviços da oficina
      final myServicesResponse = await _apiService.getMyServices();
      if (myServicesResponse['success']) {
        setState(() {
          _myServices = List<Map<String, dynamic>>.from(myServicesResponse['data']['services'] ?? []);
        });
      }

      // Carregar serviços master disponíveis
      final masterServicesResponse = await _apiService.getMasterServices();
      if (masterServicesResponse['success']) {
        setState(() {
          _masterServices = List<Map<String, dynamic>>.from(masterServicesResponse['data']['services'] ?? []);
        });
      }
      
    } catch (e) {
      print('Erro ao carregar serviços: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showAddServiceDialog(Map<String, dynamic> service) {
    final priceController = TextEditingController();
    final durationController = TextEditingController();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF00C977).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00C977).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.add_circle_outline,
                      color: Color(0xFF00C977),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Adicionar Serviço',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          service['title'] ?? 'Serviço',
                          style: const TextStyle(
                            color: Color(0xFF8B8B8B),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close,
                      color: Color(0xFF8B8B8B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Description
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  service['description'] ?? 'Serviço de qualidade',
                  style: const TextStyle(
                    color: Color(0xFFB8B8B8),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Price field
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Preço (R\$) - Opcional',
                  labelStyle: const TextStyle(color: Color(0xFF8B8B8B)),
                  prefixIcon: const Icon(Icons.attach_money, color: Color(0xFF00C977)),
                  filled: true,
                  fillColor: const Color(0xFF2A2A2A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF444444)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF00C977), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Duration field
              TextField(
                controller: durationController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Duração (minutos) - Opcional',
                  labelStyle: const TextStyle(color: Color(0xFF8B8B8B)),
                  prefixIcon: const Icon(Icons.access_time, color: Color(0xFF00C977)),
                  filled: true,
                  fillColor: const Color(0xFF2A2A2A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF444444)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF00C977), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(
                          color: Color(0xFF8B8B8B),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final price = priceController.text.isNotEmpty 
                            ? double.tryParse(priceController.text) ?? 0.0
                            : 0.0;
                        final duration = durationController.text.isNotEmpty
                            ? int.tryParse(durationController.text) ?? 0
                            : 0;
                        
                        Navigator.pop(context);
                        _addService(service, price, duration);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00C977),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Adicionar',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addService(Map<String, dynamic> masterService, double price, int duration) async {
    setState(() => _isSaving = true);
    
    try {
      final response = await _apiService.addService(
        title: masterService['title'],
        price: price,
        durationMinutes: duration,
        description: masterService['description'],
        thumbnail: masterService['image_url'],
      );
      
      if (response['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Serviço adicionado com sucesso!'),
            backgroundColor: Color(0xFF00C977),
          ),
        );
        _loadServices(); // Recarregar lista
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: ${response['error']}'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text('Serviços'),
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          const ThemeSwitchButton(),
          if (!_isLoading)
            TextButton(
              onPressed: _isSaving ? null : _loadServices,
              child: const Icon(
                Icons.refresh,
                color: Color(0xFF00C977),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00C977)),
              ),
            )
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Meus Serviços',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Gerencie os serviços oferecidos pela sua oficina',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF8B8B8B),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Stats
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF1A1A1A),
                                Color(0xFF2A2A2A),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF333333),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildStatItem(
                                  icon: Icons.build,
                                  value: '${_myServices.length}',
                                  label: 'Ativos',
                                  color: const Color(0xFF00C977),
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 40,
                                color: const Color(0xFF333333),
                              ),
                              Expanded(
                                child: _buildStatItem(
                                  icon: Icons.add,
                                  value: '${_masterServices.length}',
                                  label: 'Disponíveis',
                                  color: const Color(0xFF3B82F6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // My services
                if (_myServices.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'Serviços Ativos',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final service = _myServices[index];
                        return _buildMyServiceCard(service);
                      },
                      childCount: _myServices.length,
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                ],
                
                // Available services
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Serviços Disponíveis',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                
                // Master services grid
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.8,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final service = _masterServices[index];
                        final isAlreadyAdded = _myServices.any((s) => s['title'] == service['title']);
                        return _buildMasterServiceCard(service, isAlreadyAdded);
                      },
                      childCount: _masterServices.length,
                    ),
                  ),
                ),
                
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF8B8B8B),
          ),
        ),
      ],
    );
  }

  Widget _buildMyServiceCard(Map<String, dynamic> service) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16, left: 24, right: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A1A1A),
            Color(0xFF2A2A2A),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF333333),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Service image
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF00C977).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: service['thumbnail'] != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                          Uri.dataFromString(service['thumbnail']).data?.contentAsBytes() ?? Uint8List(0),
                      fit: BoxFit.cover,
                    ),
                  )
                : const Icon(
                    Icons.build,
                    color: Color(0xFF00C977),
                    size: 24,
                  ),
          ),
          const SizedBox(width: 16),
          
          // Service info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service['title'] ?? 'Serviço',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  service['description'] ?? '',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8B8B8B),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00C977).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'R\$ ${(service['price'] as num).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF00C977),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${service['duration_minutes']} min',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF3B82F6),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Status indicator
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF00C977),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMasterServiceCard(Map<String, dynamic> service, bool isAlreadyAdded) {
    final category = service['category'] as String? ?? 'Geral';
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A1A1A),
            const Color(0xFF2A2A2A),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAlreadyAdded ? const Color(0xFF00C977) : const Color(0xFF333333),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: isAlreadyAdded ? null : () => _showAddServiceDialog(service),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Service image
              Container(
                width: double.infinity,
                height: 60,
                decoration: BoxDecoration(
                  color: _getCategoryColor(category).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getCategoryIcon(category),
                  color: _getCategoryColor(category),
                  size: 24,
                ),
              ),
              const SizedBox(height: 8),
              
              // Service info
              Text(
                service['title'] ?? 'Serviço',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                category,
                style: TextStyle(
                  fontSize: 9,
                  color: _getCategoryColor(category),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              
              // Description
              Expanded(
                child: Text(
                  service['description'] ?? 'Serviço de qualidade',
                  style: const TextStyle(
                    fontSize: 9,
                    color: Color(0xFF8B8B8B),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 8),
              
              // Add button
              SizedBox(
                width: double.infinity,
                height: 32,
                child: ElevatedButton(
                  onPressed: isAlreadyAdded ? null : () => _showAddServiceDialog(service),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isAlreadyAdded 
                        ? const Color(0xFF00C977) 
                        : const Color(0xFF3B82F6),
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: Text(
                    isAlreadyAdded ? 'Adicionado' : 'Adicionar',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'manutenção':
        return const Color(0xFF00C977);
      case 'pneus':
        return const Color(0xFF374151);
      case 'freios':
        return const Color(0xFFEF4444);
      case 'eletrônica':
        return const Color(0xFF3B82F6);
      case 'climatização':
        return const Color(0xFF06B6A7);
      case 'suspensão':
        return const Color(0xFF8B5CF6);
      case 'transmissão':
        return const Color(0xFFF59E0B);
      case 'estética':
        return const Color(0xFFEC4899);
      default:
        return const Color(0xFF8B8B8B);
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'manutenção':
        return Icons.build;
      case 'pneus':
        return Icons.tire_repair;
      case 'freios':
        return Icons.stop_circle;
      case 'eletrônica':
        return Icons.electrical_services;
      case 'climatização':
        return Icons.ac_unit;
      case 'suspensão':
        return Icons.settings;
      case 'transmissão':
        return Icons.settings_applications;
      case 'estética':
        return Icons.cleaning_services;
      default:
        return Icons.build;
    }
  }
}
      case 'freios':
        return Icons.stop_circle;
      case 'eletrônica':
        return Icons.electrical_services;
      case 'climatização':
        return Icons.ac_unit;
      case 'suspensão':
        return Icons.settings;
      case 'transmissão':
        return Icons.settings_applications;
      case 'estética':
        return Icons.cleaning_services;
      default:
        return Icons.build;
    }
  }
}

import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../../services/storage_service.dart';
import '../../services/api_service.dart';
import '../../widgets/image_picker_widget.dart';
import '../../widgets/theme_switch_widget.dart';

class ServicesConfigScreen extends StatefulWidget {
  const ServicesConfigScreen({Key? key}) : super(key: key);

  @override
  State<ServicesConfigScreen> createState() => _ServicesConfigScreenState();
}

class _ServicesConfigScreenState extends State<ServicesConfigScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  List<Map<String, dynamic>> _myServices = [];
  List<Map<String, dynamic>> _masterServices = [];
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    setState(() => _isLoading = true);
    
    try {
      final token = await StorageService.getToken();
      if (token == null) {
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      await _apiService.loadToken();
      
      // Carregar serviços da oficina
      final myServicesResponse = await _apiService.getMyServices();
      if (myServicesResponse['success']) {
        setState(() {
          _myServices = List<Map<String, dynamic>>.from(myServicesResponse['data']['services'] ?? []);
        });
      }

      // Carregar serviços master disponíveis
      final masterServicesResponse = await _apiService.getMasterServices();
      if (masterServicesResponse['success']) {
        setState(() {
          _masterServices = List<Map<String, dynamic>>.from(masterServicesResponse['data']['services'] ?? []);
        });
      }
      
    } catch (e) {
      print('Erro ao carregar serviços: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showAddServiceDialog(Map<String, dynamic> service) {
    final priceController = TextEditingController();
    final durationController = TextEditingController();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF00C977).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00C977).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.add_circle_outline,
                      color: Color(0xFF00C977),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Adicionar Serviço',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          service['title'] ?? 'Serviço',
                          style: const TextStyle(
                            color: Color(0xFF8B8B8B),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close,
                      color: Color(0xFF8B8B8B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Description
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  service['description'] ?? 'Serviço de qualidade',
                  style: const TextStyle(
                    color: Color(0xFFB8B8B8),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Price field
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Preço (R\$) - Opcional',
                  labelStyle: const TextStyle(color: Color(0xFF8B8B8B)),
                  prefixIcon: const Icon(Icons.attach_money, color: Color(0xFF00C977)),
                  filled: true,
                  fillColor: const Color(0xFF2A2A2A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF444444)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF00C977), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Duration field
              TextField(
                controller: durationController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Duração (minutos) - Opcional',
                  labelStyle: const TextStyle(color: Color(0xFF8B8B8B)),
                  prefixIcon: const Icon(Icons.access_time, color: Color(0xFF00C977)),
                  filled: true,
                  fillColor: const Color(0xFF2A2A2A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF444444)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF00C977), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(
                          color: Color(0xFF8B8B8B),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final price = priceController.text.isNotEmpty 
                            ? double.tryParse(priceController.text) ?? 0.0
                            : 0.0;
                        final duration = durationController.text.isNotEmpty
                            ? int.tryParse(durationController.text) ?? 0
                            : 0;
                        
                        Navigator.pop(context);
                        _addService(service, price, duration);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00C977),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Adicionar',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addService(Map<String, dynamic> masterService, double price, int duration) async {
    setState(() => _isSaving = true);
    
    try {
      final response = await _apiService.addService(
        title: masterService['title'],
        price: price,
        durationMinutes: duration,
        description: masterService['description'],
        thumbnail: masterService['image_url'],
      );
      
      if (response['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Serviço adicionado com sucesso!'),
            backgroundColor: Color(0xFF00C977),
          ),
        );
        _loadServices(); // Recarregar lista
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: ${response['error']}'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text('Serviços'),
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          const ThemeSwitchButton(),
          if (!_isLoading)
            TextButton(
              onPressed: _isSaving ? null : _loadServices,
              child: const Icon(
                Icons.refresh,
                color: Color(0xFF00C977),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00C977)),
              ),
            )
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Meus Serviços',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Gerencie os serviços oferecidos pela sua oficina',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF8B8B8B),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Stats
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF1A1A1A),
                                Color(0xFF2A2A2A),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF333333),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildStatItem(
                                  icon: Icons.build,
                                  value: '${_myServices.length}',
                                  label: 'Ativos',
                                  color: const Color(0xFF00C977),
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 40,
                                color: const Color(0xFF333333),
                              ),
                              Expanded(
                                child: _buildStatItem(
                                  icon: Icons.add,
                                  value: '${_masterServices.length}',
                                  label: 'Disponíveis',
                                  color: const Color(0xFF3B82F6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // My services
                if (_myServices.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'Serviços Ativos',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final service = _myServices[index];
                        return _buildMyServiceCard(service);
                      },
                      childCount: _myServices.length,
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                ],
                
                // Available services
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Serviços Disponíveis',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                
                // Master services grid
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.8,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final service = _masterServices[index];
                        final isAlreadyAdded = _myServices.any((s) => s['title'] == service['title']);
                        return _buildMasterServiceCard(service, isAlreadyAdded);
                      },
                      childCount: _masterServices.length,
                    ),
                  ),
                ),
                
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF8B8B8B),
          ),
        ),
      ],
    );
  }

  Widget _buildMyServiceCard(Map<String, dynamic> service) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16, left: 24, right: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A1A1A),
            Color(0xFF2A2A2A),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF333333),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Service image
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF00C977).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: service['thumbnail'] != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                          Uri.dataFromString(service['thumbnail']).data?.contentAsBytes() ?? Uint8List(0),
                      fit: BoxFit.cover,
                    ),
                  )
                : const Icon(
                    Icons.build,
                    color: Color(0xFF00C977),
                    size: 24,
                  ),
          ),
          const SizedBox(width: 16),
          
          // Service info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service['title'] ?? 'Serviço',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  service['description'] ?? '',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8B8B8B),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00C977).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'R\$ ${(service['price'] as num).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF00C977),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${service['duration_minutes']} min',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF3B82F6),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Status indicator
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF00C977),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMasterServiceCard(Map<String, dynamic> service, bool isAlreadyAdded) {
    final category = service['category'] as String? ?? 'Geral';
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A1A1A),
            const Color(0xFF2A2A2A),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAlreadyAdded ? const Color(0xFF00C977) : const Color(0xFF333333),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: isAlreadyAdded ? null : () => _showAddServiceDialog(service),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Service image
              Container(
                width: double.infinity,
                height: 60,
                decoration: BoxDecoration(
                  color: _getCategoryColor(category).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getCategoryIcon(category),
                  color: _getCategoryColor(category),
                  size: 24,
                ),
              ),
              const SizedBox(height: 8),
              
              // Service info
              Text(
                service['title'] ?? 'Serviço',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                category,
                style: TextStyle(
                  fontSize: 9,
                  color: _getCategoryColor(category),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              
              // Description
              Expanded(
                child: Text(
                  service['description'] ?? 'Serviço de qualidade',
                  style: const TextStyle(
                    fontSize: 9,
                    color: Color(0xFF8B8B8B),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 8),
              
              // Add button
              SizedBox(
                width: double.infinity,
                height: 32,
                child: ElevatedButton(
                  onPressed: isAlreadyAdded ? null : () => _showAddServiceDialog(service),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isAlreadyAdded 
                        ? const Color(0xFF00C977) 
                        : const Color(0xFF3B82F6),
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: Text(
                    isAlreadyAdded ? 'Adicionado' : 'Adicionar',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'manutenção':
        return const Color(0xFF00C977);
      case 'pneus':
        return const Color(0xFF374151);
      case 'freios':
        return const Color(0xFFEF4444);
      case 'eletrônica':
        return const Color(0xFF3B82F6);
      case 'climatização':
        return const Color(0xFF06B6A7);
      case 'suspensão':
        return const Color(0xFF8B5CF6);
      case 'transmissão':
        return const Color(0xFFF59E0B);
      case 'estética':
        return const Color(0xFFEC4899);
      default:
        return const Color(0xFF8B8B8B);
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'manutenção':
        return Icons.build;
      case 'pneus':
        return Icons.tire_repair;
      case 'freios':
        return Icons.stop_circle;
      case 'eletrônica':
        return Icons.electrical_services;
      case 'climatização':
        return Icons.ac_unit;
      case 'suspensão':
        return Icons.settings;
      case 'transmissão':
        return Icons.settings_applications;
      case 'estética':
        return Icons.cleaning_services;
      default:
        return Icons.build;
    }
  }
}
      case 'freios':
        return Icons.stop_circle;
      case 'eletrônica':
        return Icons.electrical_services;
      case 'climatização':
        return Icons.ac_unit;
      case 'suspensão':
        return Icons.settings;
      case 'transmissão':
        return Icons.settings_applications;
      case 'estética':
        return Icons.cleaning_services;
      default:
        return Icons.build;
    }
  }
}

import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../../services/storage_service.dart';
import '../../services/api_service.dart';
import '../../widgets/image_picker_widget.dart';
import '../../widgets/theme_switch_widget.dart';

class ServicesConfigScreen extends StatefulWidget {
  const ServicesConfigScreen({Key? key}) : super(key: key);

  @override
  State<ServicesConfigScreen> createState() => _ServicesConfigScreenState();
}

class _ServicesConfigScreenState extends State<ServicesConfigScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  List<Map<String, dynamic>> _myServices = [];
  List<Map<String, dynamic>> _masterServices = [];
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    setState(() => _isLoading = true);
    
    try {
      final token = await StorageService.getToken();
      if (token == null) {
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      await _apiService.loadToken();
      
      // Carregar serviços da oficina
      final myServicesResponse = await _apiService.getMyServices();
      if (myServicesResponse['success']) {
        setState(() {
          _myServices = List<Map<String, dynamic>>.from(myServicesResponse['data']['services'] ?? []);
        });
      }

      // Carregar serviços master disponíveis
      final masterServicesResponse = await _apiService.getMasterServices();
      if (masterServicesResponse['success']) {
        setState(() {
          _masterServices = List<Map<String, dynamic>>.from(masterServicesResponse['data']['services'] ?? []);
        });
      }
      
    } catch (e) {
      print('Erro ao carregar serviços: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showAddServiceDialog(Map<String, dynamic> service) {
    final priceController = TextEditingController();
    final durationController = TextEditingController();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF00C977).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00C977).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.add_circle_outline,
                      color: Color(0xFF00C977),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Adicionar Serviço',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          service['title'] ?? 'Serviço',
                          style: const TextStyle(
                            color: Color(0xFF8B8B8B),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close,
                      color: Color(0xFF8B8B8B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Description
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  service['description'] ?? 'Serviço de qualidade',
                  style: const TextStyle(
                    color: Color(0xFFB8B8B8),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Price field
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Preço (R\$) - Opcional',
                  labelStyle: const TextStyle(color: Color(0xFF8B8B8B)),
                  prefixIcon: const Icon(Icons.attach_money, color: Color(0xFF00C977)),
                  filled: true,
                  fillColor: const Color(0xFF2A2A2A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF444444)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF00C977), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Duration field
              TextField(
                controller: durationController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Duração (minutos) - Opcional',
                  labelStyle: const TextStyle(color: Color(0xFF8B8B8B)),
                  prefixIcon: const Icon(Icons.access_time, color: Color(0xFF00C977)),
                  filled: true,
                  fillColor: const Color(0xFF2A2A2A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF444444)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF00C977), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(
                          color: Color(0xFF8B8B8B),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final price = priceController.text.isNotEmpty 
                            ? double.tryParse(priceController.text) ?? 0.0
                            : 0.0;
                        final duration = durationController.text.isNotEmpty
                            ? int.tryParse(durationController.text) ?? 0
                            : 0;
                        
                        Navigator.pop(context);
                        _addService(service, price, duration);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00C977),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Adicionar',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addService(Map<String, dynamic> masterService, double price, int duration) async {
    setState(() => _isSaving = true);
    
    try {
      final response = await _apiService.addService(
        title: masterService['title'],
        price: price,
        durationMinutes: duration,
        description: masterService['description'],
        thumbnail: masterService['image_url'],
      );
      
      if (response['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Serviço adicionado com sucesso!'),
            backgroundColor: Color(0xFF00C977),
          ),
        );
        _loadServices(); // Recarregar lista
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: ${response['error']}'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text('Serviços'),
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          const ThemeSwitchButton(),
          if (!_isLoading)
            TextButton(
              onPressed: _isSaving ? null : _loadServices,
              child: const Icon(
                Icons.refresh,
                color: Color(0xFF00C977),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00C977)),
              ),
            )
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Meus Serviços',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Gerencie os serviços oferecidos pela sua oficina',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF8B8B8B),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Stats
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF1A1A1A),
                                Color(0xFF2A2A2A),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF333333),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildStatItem(
                                  icon: Icons.build,
                                  value: '${_myServices.length}',
                                  label: 'Ativos',
                                  color: const Color(0xFF00C977),
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 40,
                                color: const Color(0xFF333333),
                              ),
                              Expanded(
                                child: _buildStatItem(
                                  icon: Icons.add,
                                  value: '${_masterServices.length}',
                                  label: 'Disponíveis',
                                  color: const Color(0xFF3B82F6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // My services
                if (_myServices.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'Serviços Ativos',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final service = _myServices[index];
                        return _buildMyServiceCard(service);
                      },
                      childCount: _myServices.length,
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                ],
                
                // Available services
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Serviços Disponíveis',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                
                // Master services grid
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.8,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final service = _masterServices[index];
                        final isAlreadyAdded = _myServices.any((s) => s['title'] == service['title']);
                        return _buildMasterServiceCard(service, isAlreadyAdded);
                      },
                      childCount: _masterServices.length,
                    ),
                  ),
                ),
                
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF8B8B8B),
          ),
        ),
      ],
    );
  }

  Widget _buildMyServiceCard(Map<String, dynamic> service) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16, left: 24, right: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A1A1A),
            Color(0xFF2A2A2A),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF333333),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Service image
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF00C977).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: service['thumbnail'] != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                          Uri.dataFromString(service['thumbnail']).data?.contentAsBytes() ?? Uint8List(0),
                      fit: BoxFit.cover,
                    ),
                  )
                : const Icon(
                    Icons.build,
                    color: Color(0xFF00C977),
                    size: 24,
                  ),
          ),
          const SizedBox(width: 16),
          
          // Service info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service['title'] ?? 'Serviço',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  service['description'] ?? '',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8B8B8B),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00C977).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'R\$ ${(service['price'] as num).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF00C977),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${service['duration_minutes']} min',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF3B82F6),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Status indicator
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF00C977),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMasterServiceCard(Map<String, dynamic> service, bool isAlreadyAdded) {
    final category = service['category'] as String? ?? 'Geral';
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A1A1A),
            const Color(0xFF2A2A2A),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAlreadyAdded ? const Color(0xFF00C977) : const Color(0xFF333333),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: isAlreadyAdded ? null : () => _showAddServiceDialog(service),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Service image
              Container(
                width: double.infinity,
                height: 60,
                decoration: BoxDecoration(
                  color: _getCategoryColor(category).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getCategoryIcon(category),
                  color: _getCategoryColor(category),
                  size: 24,
                ),
              ),
              const SizedBox(height: 8),
              
              // Service info
              Text(
                service['title'] ?? 'Serviço',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                category,
                style: TextStyle(
                  fontSize: 9,
                  color: _getCategoryColor(category),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              
              // Description
              Expanded(
                child: Text(
                  service['description'] ?? 'Serviço de qualidade',
                  style: const TextStyle(
                    fontSize: 9,
                    color: Color(0xFF8B8B8B),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 8),
              
              // Add button
              SizedBox(
                width: double.infinity,
                height: 32,
                child: ElevatedButton(
                  onPressed: isAlreadyAdded ? null : () => _showAddServiceDialog(service),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isAlreadyAdded 
                        ? const Color(0xFF00C977) 
                        : const Color(0xFF3B82F6),
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: Text(
                    isAlreadyAdded ? 'Adicionado' : 'Adicionar',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'manutenção':
        return const Color(0xFF00C977);
      case 'pneus':
        return const Color(0xFF374151);
      case 'freios':
        return const Color(0xFFEF4444);
      case 'eletrônica':
        return const Color(0xFF3B82F6);
      case 'climatização':
        return const Color(0xFF06B6A7);
      case 'suspensão':
        return const Color(0xFF8B5CF6);
      case 'transmissão':
        return const Color(0xFFF59E0B);
      case 'estética':
        return const Color(0xFFEC4899);
      default:
        return const Color(0xFF8B8B8B);
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'manutenção':
        return Icons.build;
      case 'pneus':
        return Icons.tire_repair;
      case 'freios':
        return Icons.stop_circle;
      case 'eletrônica':
        return Icons.electrical_services;
      case 'climatização':
        return Icons.ac_unit;
      case 'suspensão':
        return Icons.settings;
      case 'transmissão':
        return Icons.settings_applications;
      case 'estética':
        return Icons.cleaning_services;
      default:
        return Icons.build;
    }
  }
}
      case 'freios':
        return Icons.stop_circle;
      case 'eletrônica':
        return Icons.electrical_services;
      case 'climatização':
        return Icons.ac_unit;
      case 'suspensão':
        return Icons.settings;
      case 'transmissão':
        return Icons.settings_applications;
      case 'estética':
        return Icons.cleaning_services;
      default:
        return Icons.build;
    }
  }
}

import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../../services/storage_service.dart';
import '../../services/api_service.dart';
import '../../widgets/image_picker_widget.dart';
import '../../widgets/theme_switch_widget.dart';

class ServicesConfigScreen extends StatefulWidget {
  const ServicesConfigScreen({Key? key}) : super(key: key);

  @override
  State<ServicesConfigScreen> createState() => _ServicesConfigScreenState();
}

class _ServicesConfigScreenState extends State<ServicesConfigScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  List<Map<String, dynamic>> _myServices = [];
  List<Map<String, dynamic>> _masterServices = [];
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    setState(() => _isLoading = true);
    
    try {
      final token = await StorageService.getToken();
      if (token == null) {
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      await _apiService.loadToken();
      
      // Carregar serviços da oficina
      final myServicesResponse = await _apiService.getMyServices();
      if (myServicesResponse['success']) {
        setState(() {
          _myServices = List<Map<String, dynamic>>.from(myServicesResponse['data']['services'] ?? []);
        });
      }

      // Carregar serviços master disponíveis
      final masterServicesResponse = await _apiService.getMasterServices();
      if (masterServicesResponse['success']) {
        setState(() {
          _masterServices = List<Map<String, dynamic>>.from(masterServicesResponse['data']['services'] ?? []);
        });
      }
      
    } catch (e) {
      print('Erro ao carregar serviços: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showAddServiceDialog(Map<String, dynamic> service) {
    final priceController = TextEditingController();
    final durationController = TextEditingController();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF00C977).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00C977).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.add_circle_outline,
                      color: Color(0xFF00C977),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Adicionar Serviço',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          service['title'] ?? 'Serviço',
                          style: const TextStyle(
                            color: Color(0xFF8B8B8B),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close,
                      color: Color(0xFF8B8B8B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Description
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  service['description'] ?? 'Serviço de qualidade',
                  style: const TextStyle(
                    color: Color(0xFFB8B8B8),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Price field
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Preço (R\$) - Opcional',
                  labelStyle: const TextStyle(color: Color(0xFF8B8B8B)),
                  prefixIcon: const Icon(Icons.attach_money, color: Color(0xFF00C977)),
                  filled: true,
                  fillColor: const Color(0xFF2A2A2A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF444444)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF00C977), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Duration field
              TextField(
                controller: durationController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Duração (minutos) - Opcional',
                  labelStyle: const TextStyle(color: Color(0xFF8B8B8B)),
                  prefixIcon: const Icon(Icons.access_time, color: Color(0xFF00C977)),
                  filled: true,
                  fillColor: const Color(0xFF2A2A2A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF444444)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF00C977), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(
                          color: Color(0xFF8B8B8B),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final price = priceController.text.isNotEmpty 
                            ? double.tryParse(priceController.text) ?? 0.0
                            : 0.0;
                        final duration = durationController.text.isNotEmpty
                            ? int.tryParse(durationController.text) ?? 0
                            : 0;
                        
                        Navigator.pop(context);
                        _addService(service, price, duration);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00C977),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Adicionar',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addService(Map<String, dynamic> masterService, double price, int duration) async {
    setState(() => _isSaving = true);
    
    try {
      final response = await _apiService.addService(
        title: masterService['title'],
        price: price,
        durationMinutes: duration,
        description: masterService['description'],
        thumbnail: masterService['image_url'],
      );
      
      if (response['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Serviço adicionado com sucesso!'),
            backgroundColor: Color(0xFF00C977),
          ),
        );
        _loadServices(); // Recarregar lista
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: ${response['error']}'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text('Serviços'),
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          const ThemeSwitchButton(),
          if (!_isLoading)
            TextButton(
              onPressed: _isSaving ? null : _loadServices,
              child: const Icon(
                Icons.refresh,
                color: Color(0xFF00C977),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00C977)),
              ),
            )
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Meus Serviços',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Gerencie os serviços oferecidos pela sua oficina',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF8B8B8B),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Stats
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF1A1A1A),
                                Color(0xFF2A2A2A),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF333333),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildStatItem(
                                  icon: Icons.build,
                                  value: '${_myServices.length}',
                                  label: 'Ativos',
                                  color: const Color(0xFF00C977),
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 40,
                                color: const Color(0xFF333333),
                              ),
                              Expanded(
                                child: _buildStatItem(
                                  icon: Icons.add,
                                  value: '${_masterServices.length}',
                                  label: 'Disponíveis',
                                  color: const Color(0xFF3B82F6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // My services
                if (_myServices.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'Serviços Ativos',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final service = _myServices[index];
                        return _buildMyServiceCard(service);
                      },
                      childCount: _myServices.length,
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                ],
                
                // Available services
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Serviços Disponíveis',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                
                // Master services grid
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.8,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final service = _masterServices[index];
                        final isAlreadyAdded = _myServices.any((s) => s['title'] == service['title']);
                        return _buildMasterServiceCard(service, isAlreadyAdded);
                      },
                      childCount: _masterServices.length,
                    ),
                  ),
                ),
                
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF8B8B8B),
          ),
        ),
      ],
    );
  }

  Widget _buildMyServiceCard(Map<String, dynamic> service) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16, left: 24, right: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A1A1A),
            Color(0xFF2A2A2A),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF333333),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Service image
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF00C977).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: service['thumbnail'] != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                          Uri.dataFromString(service['thumbnail']).data?.contentAsBytes() ?? Uint8List(0),
                      fit: BoxFit.cover,
                    ),
                  )
                : const Icon(
                    Icons.build,
                    color: Color(0xFF00C977),
                    size: 24,
                  ),
          ),
          const SizedBox(width: 16),
          
          // Service info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service['title'] ?? 'Serviço',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  service['description'] ?? '',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8B8B8B),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00C977).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'R\$ ${(service['price'] as num).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF00C977),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${service['duration_minutes']} min',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF3B82F6),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Status indicator
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF00C977),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMasterServiceCard(Map<String, dynamic> service, bool isAlreadyAdded) {
    final category = service['category'] as String? ?? 'Geral';
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A1A1A),
            const Color(0xFF2A2A2A),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAlreadyAdded ? const Color(0xFF00C977) : const Color(0xFF333333),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: isAlreadyAdded ? null : () => _showAddServiceDialog(service),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Service image
              Container(
                width: double.infinity,
                height: 60,
                decoration: BoxDecoration(
                  color: _getCategoryColor(category).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getCategoryIcon(category),
                  color: _getCategoryColor(category),
                  size: 24,
                ),
              ),
              const SizedBox(height: 8),
              
              // Service info
              Text(
                service['title'] ?? 'Serviço',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                category,
                style: TextStyle(
                  fontSize: 9,
                  color: _getCategoryColor(category),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              
              // Description
              Expanded(
                child: Text(
                  service['description'] ?? 'Serviço de qualidade',
                  style: const TextStyle(
                    fontSize: 9,
                    color: Color(0xFF8B8B8B),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 8),
              
              // Add button
              SizedBox(
                width: double.infinity,
                height: 32,
                child: ElevatedButton(
                  onPressed: isAlreadyAdded ? null : () => _showAddServiceDialog(service),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isAlreadyAdded 
                        ? const Color(0xFF00C977) 
                        : const Color(0xFF3B82F6),
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: Text(
                    isAlreadyAdded ? 'Adicionado' : 'Adicionar',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'manutenção':
        return const Color(0xFF00C977);
      case 'pneus':
        return const Color(0xFF374151);
      case 'freios':
        return const Color(0xFFEF4444);
      case 'eletrônica':
        return const Color(0xFF3B82F6);
      case 'climatização':
        return const Color(0xFF06B6A7);
      case 'suspensão':
        return const Color(0xFF8B5CF6);
      case 'transmissão':
        return const Color(0xFFF59E0B);
      case 'estética':
        return const Color(0xFFEC4899);
      default:
        return const Color(0xFF8B8B8B);
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'manutenção':
        return Icons.build;
      case 'pneus':
        return Icons.tire_repair;
      case 'freios':
        return Icons.stop_circle;
      case 'eletrônica':
        return Icons.electrical_services;
      case 'climatização':
        return Icons.ac_unit;
      case 'suspensão':
        return Icons.settings;
      case 'transmissão':
        return Icons.settings_applications;
      case 'estética':
        return Icons.cleaning_services;
      default:
        return Icons.build;
    }
  }
}
      case 'freios':
        return Icons.stop_circle;
      case 'eletrônica':
        return Icons.electrical_services;
      case 'climatização':
        return Icons.ac_unit;
      case 'suspensão':
        return Icons.settings;
      case 'transmissão':
        return Icons.settings_applications;
      case 'estética':
        return Icons.cleaning_services;
      default:
        return Icons.build;
    }
  }
}

import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../../services/storage_service.dart';
import '../../services/api_service.dart';
import '../../widgets/image_picker_widget.dart';
import '../../widgets/theme_switch_widget.dart';

class ServicesConfigScreen extends StatefulWidget {
  const ServicesConfigScreen({Key? key}) : super(key: key);

  @override
  State<ServicesConfigScreen> createState() => _ServicesConfigScreenState();
}

class _ServicesConfigScreenState extends State<ServicesConfigScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  List<Map<String, dynamic>> _myServices = [];
  List<Map<String, dynamic>> _masterServices = [];
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    setState(() => _isLoading = true);
    
    try {
      final token = await StorageService.getToken();
      if (token == null) {
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      await _apiService.loadToken();
      
      // Carregar serviços da oficina
      final myServicesResponse = await _apiService.getMyServices();
      if (myServicesResponse['success']) {
        setState(() {
          _myServices = List<Map<String, dynamic>>.from(myServicesResponse['data']['services'] ?? []);
        });
      }

      // Carregar serviços master disponíveis
      final masterServicesResponse = await _apiService.getMasterServices();
      if (masterServicesResponse['success']) {
        setState(() {
          _masterServices = List<Map<String, dynamic>>.from(masterServicesResponse['data']['services'] ?? []);
        });
      }
      
    } catch (e) {
      print('Erro ao carregar serviços: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showAddServiceDialog(Map<String, dynamic> service) {
    final priceController = TextEditingController();
    final durationController = TextEditingController();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF00C977).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00C977).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.add_circle_outline,
                      color: Color(0xFF00C977),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Adicionar Serviço',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          service['title'] ?? 'Serviço',
                          style: const TextStyle(
                            color: Color(0xFF8B8B8B),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close,
                      color: Color(0xFF8B8B8B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Description
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  service['description'] ?? 'Serviço de qualidade',
                  style: const TextStyle(
                    color: Color(0xFFB8B8B8),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Price field
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Preço (R\$) - Opcional',
                  labelStyle: const TextStyle(color: Color(0xFF8B8B8B)),
                  prefixIcon: const Icon(Icons.attach_money, color: Color(0xFF00C977)),
                  filled: true,
                  fillColor: const Color(0xFF2A2A2A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF444444)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF00C977), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Duration field
              TextField(
                controller: durationController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Duração (minutos) - Opcional',
                  labelStyle: const TextStyle(color: Color(0xFF8B8B8B)),
                  prefixIcon: const Icon(Icons.access_time, color: Color(0xFF00C977)),
                  filled: true,
                  fillColor: const Color(0xFF2A2A2A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF444444)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF00C977), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(
                          color: Color(0xFF8B8B8B),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final price = priceController.text.isNotEmpty 
                            ? double.tryParse(priceController.text) ?? 0.0
                            : 0.0;
                        final duration = durationController.text.isNotEmpty
                            ? int.tryParse(durationController.text) ?? 0
                            : 0;
                        
                        Navigator.pop(context);
                        _addService(service, price, duration);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00C977),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Adicionar',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addService(Map<String, dynamic> masterService, double price, int duration) async {
    setState(() => _isSaving = true);
    
    try {
      final response = await _apiService.addService(
        title: masterService['title'],
        price: price,
        durationMinutes: duration,
        description: masterService['description'],
        thumbnail: masterService['image_url'],
      );
      
      if (response['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Serviço adicionado com sucesso!'),
            backgroundColor: Color(0xFF00C977),
          ),
        );
        _loadServices(); // Recarregar lista
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: ${response['error']}'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text('Serviços'),
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          const ThemeSwitchButton(),
          if (!_isLoading)
            TextButton(
              onPressed: _isSaving ? null : _loadServices,
              child: const Icon(
                Icons.refresh,
                color: Color(0xFF00C977),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00C977)),
              ),
            )
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Meus Serviços',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Gerencie os serviços oferecidos pela sua oficina',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF8B8B8B),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Stats
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF1A1A1A),
                                Color(0xFF2A2A2A),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF333333),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildStatItem(
                                  icon: Icons.build,
                                  value: '${_myServices.length}',
                                  label: 'Ativos',
                                  color: const Color(0xFF00C977),
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 40,
                                color: const Color(0xFF333333),
                              ),
                              Expanded(
                                child: _buildStatItem(
                                  icon: Icons.add,
                                  value: '${_masterServices.length}',
                                  label: 'Disponíveis',
                                  color: const Color(0xFF3B82F6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // My services
                if (_myServices.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'Serviços Ativos',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final service = _myServices[index];
                        return _buildMyServiceCard(service);
                      },
                      childCount: _myServices.length,
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                ],
                
                // Available services
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Serviços Disponíveis',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                
                // Master services grid
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.8,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final service = _masterServices[index];
                        final isAlreadyAdded = _myServices.any((s) => s['title'] == service['title']);
                        return _buildMasterServiceCard(service, isAlreadyAdded);
                      },
                      childCount: _masterServices.length,
                    ),
                  ),
                ),
                
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF8B8B8B),
          ),
        ),
      ],
    );
  }

  Widget _buildMyServiceCard(Map<String, dynamic> service) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16, left: 24, right: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A1A1A),
            Color(0xFF2A2A2A),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF333333),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Service image
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF00C977).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: service['thumbnail'] != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                          Uri.dataFromString(service['thumbnail']).data?.contentAsBytes() ?? Uint8List(0),
                      fit: BoxFit.cover,
                    ),
                  )
                : const Icon(
                    Icons.build,
                    color: Color(0xFF00C977),
                    size: 24,
                  ),
          ),
          const SizedBox(width: 16),
          
          // Service info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service['title'] ?? 'Serviço',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  service['description'] ?? '',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8B8B8B),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00C977).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'R\$ ${(service['price'] as num).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF00C977),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${service['duration_minutes']} min',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF3B82F6),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Status indicator
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF00C977),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMasterServiceCard(Map<String, dynamic> service, bool isAlreadyAdded) {
    final category = service['category'] as String? ?? 'Geral';
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A1A1A),
            const Color(0xFF2A2A2A),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAlreadyAdded ? const Color(0xFF00C977) : const Color(0xFF333333),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: isAlreadyAdded ? null : () => _showAddServiceDialog(service),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Service image
              Container(
                width: double.infinity,
                height: 60,
                decoration: BoxDecoration(
                  color: _getCategoryColor(category).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getCategoryIcon(category),
                  color: _getCategoryColor(category),
                  size: 24,
                ),
              ),
              const SizedBox(height: 8),
              
              // Service info
              Text(
                service['title'] ?? 'Serviço',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                category,
                style: TextStyle(
                  fontSize: 9,
                  color: _getCategoryColor(category),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              
              // Description
              Expanded(
                child: Text(
                  service['description'] ?? 'Serviço de qualidade',
                  style: const TextStyle(
                    fontSize: 9,
                    color: Color(0xFF8B8B8B),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 8),
              
              // Add button
              SizedBox(
                width: double.infinity,
                height: 32,
                child: ElevatedButton(
                  onPressed: isAlreadyAdded ? null : () => _showAddServiceDialog(service),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isAlreadyAdded 
                        ? const Color(0xFF00C977) 
                        : const Color(0xFF3B82F6),
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: Text(
                    isAlreadyAdded ? 'Adicionado' : 'Adicionar',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'manutenção':
        return const Color(0xFF00C977);
      case 'pneus':
        return const Color(0xFF374151);
      case 'freios':
        return const Color(0xFFEF4444);
      case 'eletrônica':
        return const Color(0xFF3B82F6);
      case 'climatização':
        return const Color(0xFF06B6A7);
      case 'suspensão':
        return const Color(0xFF8B5CF6);
      case 'transmissão':
        return const Color(0xFFF59E0B);
      case 'estética':
        return const Color(0xFFEC4899);
      default:
        return const Color(0xFF8B8B8B);
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'manutenção':
        return Icons.build;
      case 'pneus':
        return Icons.tire_repair;
      case 'freios':
        return Icons.stop_circle;
      case 'eletrônica':
        return Icons.electrical_services;
      case 'climatização':
        return Icons.ac_unit;
      case 'suspensão':
        return Icons.settings;
      case 'transmissão':
        return Icons.settings_applications;
      case 'estética':
        return Icons.cleaning_services;
      default:
        return Icons.build;
    }
  }
}
      case 'freios':
        return Icons.stop_circle;
      case 'eletrônica':
        return Icons.electrical_services;
      case 'climatização':
        return Icons.ac_unit;
      case 'suspensão':
        return Icons.settings;
      case 'transmissão':
        return Icons.settings_applications;
      case 'estética':
        return Icons.cleaning_services;
      default:
        return Icons.build;
    }
  }
}

import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../../services/storage_service.dart';
import '../../services/api_service.dart';
import '../../widgets/image_picker_widget.dart';
import '../../widgets/theme_switch_widget.dart';

class ServicesConfigScreen extends StatefulWidget {
  const ServicesConfigScreen({Key? key}) : super(key: key);

  @override
  State<ServicesConfigScreen> createState() => _ServicesConfigScreenState();
}

class _ServicesConfigScreenState extends State<ServicesConfigScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  List<Map<String, dynamic>> _myServices = [];
  List<Map<String, dynamic>> _masterServices = [];
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    setState(() => _isLoading = true);
    
    try {
      final token = await StorageService.getToken();
      if (token == null) {
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      await _apiService.loadToken();
      
      // Carregar serviços da oficina
      final myServicesResponse = await _apiService.getMyServices();
      if (myServicesResponse['success']) {
        setState(() {
          _myServices = List<Map<String, dynamic>>.from(myServicesResponse['data']['services'] ?? []);
        });
      }

      // Carregar serviços master disponíveis
      final masterServicesResponse = await _apiService.getMasterServices();
      if (masterServicesResponse['success']) {
        setState(() {
          _masterServices = List<Map<String, dynamic>>.from(masterServicesResponse['data']['services'] ?? []);
        });
      }
      
    } catch (e) {
      print('Erro ao carregar serviços: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showAddServiceDialog(Map<String, dynamic> service) {
    final priceController = TextEditingController();
    final durationController = TextEditingController();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF00C977).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00C977).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.add_circle_outline,
                      color: Color(0xFF00C977),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Adicionar Serviço',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          service['title'] ?? 'Serviço',
                          style: const TextStyle(
                            color: Color(0xFF8B8B8B),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close,
                      color: Color(0xFF8B8B8B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Description
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  service['description'] ?? 'Serviço de qualidade',
                  style: const TextStyle(
                    color: Color(0xFFB8B8B8),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Price field
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Preço (R\$) - Opcional',
                  labelStyle: const TextStyle(color: Color(0xFF8B8B8B)),
                  prefixIcon: const Icon(Icons.attach_money, color: Color(0xFF00C977)),
                  filled: true,
                  fillColor: const Color(0xFF2A2A2A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF444444)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF00C977), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Duration field
              TextField(
                controller: durationController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Duração (minutos) - Opcional',
                  labelStyle: const TextStyle(color: Color(0xFF8B8B8B)),
                  prefixIcon: const Icon(Icons.access_time, color: Color(0xFF00C977)),
                  filled: true,
                  fillColor: const Color(0xFF2A2A2A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF444444)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF00C977), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(
                          color: Color(0xFF8B8B8B),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final price = priceController.text.isNotEmpty 
                            ? double.tryParse(priceController.text) ?? 0.0
                            : 0.0;
                        final duration = durationController.text.isNotEmpty
                            ? int.tryParse(durationController.text) ?? 0
                            : 0;
                        
                        Navigator.pop(context);
                        _addService(service, price, duration);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00C977),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Adicionar',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addService(Map<String, dynamic> masterService, double price, int duration) async {
    setState(() => _isSaving = true);
    
    try {
      final response = await _apiService.addService(
        title: masterService['title'],
        price: price,
        durationMinutes: duration,
        description: masterService['description'],
        thumbnail: masterService['image_url'],
      );
      
      if (response['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Serviço adicionado com sucesso!'),
            backgroundColor: Color(0xFF00C977),
          ),
        );
        _loadServices(); // Recarregar lista
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: ${response['error']}'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text('Serviços'),
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          const ThemeSwitchButton(),
          if (!_isLoading)
            TextButton(
              onPressed: _isSaving ? null : _loadServices,
              child: const Icon(
                Icons.refresh,
                color: Color(0xFF00C977),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00C977)),
              ),
            )
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Meus Serviços',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Gerencie os serviços oferecidos pela sua oficina',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF8B8B8B),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Stats
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF1A1A1A),
                                Color(0xFF2A2A2A),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF333333),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildStatItem(
                                  icon: Icons.build,
                                  value: '${_myServices.length}',
                                  label: 'Ativos',
                                  color: const Color(0xFF00C977),
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 40,
                                color: const Color(0xFF333333),
                              ),
                              Expanded(
                                child: _buildStatItem(
                                  icon: Icons.add,
                                  value: '${_masterServices.length}',
                                  label: 'Disponíveis',
                                  color: const Color(0xFF3B82F6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // My services
                if (_myServices.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'Serviços Ativos',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final service = _myServices[index];
                        return _buildMyServiceCard(service);
                      },
                      childCount: _myServices.length,
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                ],
                
                // Available services
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Serviços Disponíveis',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                
                // Master services grid
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.8,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final service = _masterServices[index];
                        final isAlreadyAdded = _myServices.any((s) => s['title'] == service['title']);
                        return _buildMasterServiceCard(service, isAlreadyAdded);
                      },
                      childCount: _masterServices.length,
                    ),
                  ),
                ),
                
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF8B8B8B),
          ),
        ),
      ],
    );
  }

  Widget _buildMyServiceCard(Map<String, dynamic> service) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16, left: 24, right: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A1A1A),
            Color(0xFF2A2A2A),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF333333),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Service image
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF00C977).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: service['thumbnail'] != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                          Uri.dataFromString(service['thumbnail']).data?.contentAsBytes() ?? Uint8List(0),
                      fit: BoxFit.cover,
                    ),
                  )
                : const Icon(
                    Icons.build,
                    color: Color(0xFF00C977),
                    size: 24,
                  ),
          ),
          const SizedBox(width: 16),
          
          // Service info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service['title'] ?? 'Serviço',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  service['description'] ?? '',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8B8B8B),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00C977).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'R\$ ${(service['price'] as num).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF00C977),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${service['duration_minutes']} min',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF3B82F6),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Status indicator
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF00C977),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMasterServiceCard(Map<String, dynamic> service, bool isAlreadyAdded) {
    final category = service['category'] as String? ?? 'Geral';
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A1A1A),
            const Color(0xFF2A2A2A),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAlreadyAdded ? const Color(0xFF00C977) : const Color(0xFF333333),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: isAlreadyAdded ? null : () => _showAddServiceDialog(service),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Service image
              Container(
                width: double.infinity,
                height: 60,
                decoration: BoxDecoration(
                  color: _getCategoryColor(category).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getCategoryIcon(category),
                  color: _getCategoryColor(category),
                  size: 24,
                ),
              ),
              const SizedBox(height: 8),
              
              // Service info
              Text(
                service['title'] ?? 'Serviço',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                category,
                style: TextStyle(
                  fontSize: 9,
                  color: _getCategoryColor(category),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              
              // Description
              Expanded(
                child: Text(
                  service['description'] ?? 'Serviço de qualidade',
                  style: const TextStyle(
                    fontSize: 9,
                    color: Color(0xFF8B8B8B),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 8),
              
              // Add button
              SizedBox(
                width: double.infinity,
                height: 32,
                child: ElevatedButton(
                  onPressed: isAlreadyAdded ? null : () => _showAddServiceDialog(service),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isAlreadyAdded 
                        ? const Color(0xFF00C977) 
                        : const Color(0xFF3B82F6),
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: Text(
                    isAlreadyAdded ? 'Adicionado' : 'Adicionar',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'manutenção':
        return const Color(0xFF00C977);
      case 'pneus':
        return const Color(0xFF374151);
      case 'freios':
        return const Color(0xFFEF4444);
      case 'eletrônica':
        return const Color(0xFF3B82F6);
      case 'climatização':
        return const Color(0xFF06B6A7);
      case 'suspensão':
        return const Color(0xFF8B5CF6);
      case 'transmissão':
        return const Color(0xFFF59E0B);
      case 'estética':
        return const Color(0xFFEC4899);
      default:
        return const Color(0xFF8B8B8B);
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'manutenção':
        return Icons.build;
      case 'pneus':
        return Icons.tire_repair;
      case 'freios':
        return Icons.stop_circle;
      case 'eletrônica':
        return Icons.electrical_services;
      case 'climatização':
        return Icons.ac_unit;
      case 'suspensão':
        return Icons.settings;
      case 'transmissão':
        return Icons.settings_applications;
      case 'estética':
        return Icons.cleaning_services;
      default:
        return Icons.build;
    }
  }
}
      case 'freios':
        return Icons.stop_circle;
      case 'eletrônica':
        return Icons.electrical_services;
      case 'climatização':
        return Icons.ac_unit;
      case 'suspensão':
        return Icons.settings;
      case 'transmissão':
        return Icons.settings_applications;
      case 'estética':
        return Icons.cleaning_services;
      default:
        return Icons.build;
    }
  }
}

import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../../services/storage_service.dart';
import '../../services/api_service.dart';
import '../../widgets/image_picker_widget.dart';
import '../../widgets/theme_switch_widget.dart';

class ServicesConfigScreen extends StatefulWidget {
  const ServicesConfigScreen({Key? key}) : super(key: key);

  @override
  State<ServicesConfigScreen> createState() => _ServicesConfigScreenState();
}

class _ServicesConfigScreenState extends State<ServicesConfigScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  List<Map<String, dynamic>> _myServices = [];
  List<Map<String, dynamic>> _masterServices = [];
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    setState(() => _isLoading = true);
    
    try {
      final token = await StorageService.getToken();
      if (token == null) {
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      await _apiService.loadToken();
      
      // Carregar serviços da oficina
      final myServicesResponse = await _apiService.getMyServices();
      if (myServicesResponse['success']) {
        setState(() {
          _myServices = List<Map<String, dynamic>>.from(myServicesResponse['data']['services'] ?? []);
        });
      }

      // Carregar serviços master disponíveis
      final masterServicesResponse = await _apiService.getMasterServices();
      if (masterServicesResponse['success']) {
        setState(() {
          _masterServices = List<Map<String, dynamic>>.from(masterServicesResponse['data']['services'] ?? []);
        });
      }
      
    } catch (e) {
      print('Erro ao carregar serviços: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showAddServiceDialog(Map<String, dynamic> service) {
    final priceController = TextEditingController();
    final durationController = TextEditingController();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF00C977).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00C977).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.add_circle_outline,
                      color: Color(0xFF00C977),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Adicionar Serviço',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          service['title'] ?? 'Serviço',
                          style: const TextStyle(
                            color: Color(0xFF8B8B8B),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close,
                      color: Color(0xFF8B8B8B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Description
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  service['description'] ?? 'Serviço de qualidade',
                  style: const TextStyle(
                    color: Color(0xFFB8B8B8),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Price field
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Preço (R\$) - Opcional',
                  labelStyle: const TextStyle(color: Color(0xFF8B8B8B)),
                  prefixIcon: const Icon(Icons.attach_money, color: Color(0xFF00C977)),
                  filled: true,
                  fillColor: const Color(0xFF2A2A2A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF444444)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF00C977), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Duration field
              TextField(
                controller: durationController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Duração (minutos) - Opcional',
                  labelStyle: const TextStyle(color: Color(0xFF8B8B8B)),
                  prefixIcon: const Icon(Icons.access_time, color: Color(0xFF00C977)),
                  filled: true,
                  fillColor: const Color(0xFF2A2A2A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF444444)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF00C977), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(
                          color: Color(0xFF8B8B8B),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final price = priceController.text.isNotEmpty 
                            ? double.tryParse(priceController.text) ?? 0.0
                            : 0.0;
                        final duration = durationController.text.isNotEmpty
                            ? int.tryParse(durationController.text) ?? 0
                            : 0;
                        
                        Navigator.pop(context);
                        _addService(service, price, duration);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00C977),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Adicionar',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addService(Map<String, dynamic> masterService, double price, int duration) async {
    setState(() => _isSaving = true);
    
    try {
      final response = await _apiService.addService(
        title: masterService['title'],
        price: price,
        durationMinutes: duration,
        description: masterService['description'],
        thumbnail: masterService['image_url'],
      );
      
      if (response['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Serviço adicionado com sucesso!'),
            backgroundColor: Color(0xFF00C977),
          ),
        );
        _loadServices(); // Recarregar lista
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: ${response['error']}'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text('Serviços'),
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          const ThemeSwitchButton(),
          if (!_isLoading)
            TextButton(
              onPressed: _isSaving ? null : _loadServices,
              child: const Icon(
                Icons.refresh,
                color: Color(0xFF00C977),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00C977)),
              ),
            )
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Meus Serviços',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Gerencie os serviços oferecidos pela sua oficina',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF8B8B8B),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Stats
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF1A1A1A),
                                Color(0xFF2A2A2A),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF333333),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildStatItem(
                                  icon: Icons.build,
                                  value: '${_myServices.length}',
                                  label: 'Ativos',
                                  color: const Color(0xFF00C977),
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 40,
                                color: const Color(0xFF333333),
                              ),
                              Expanded(
                                child: _buildStatItem(
                                  icon: Icons.add,
                                  value: '${_masterServices.length}',
                                  label: 'Disponíveis',
                                  color: const Color(0xFF3B82F6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // My services
                if (_myServices.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'Serviços Ativos',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final service = _myServices[index];
                        return _buildMyServiceCard(service);
                      },
                      childCount: _myServices.length,
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                ],
                
                // Available services
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Serviços Disponíveis',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                
                // Master services grid
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.8,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final service = _masterServices[index];
                        final isAlreadyAdded = _myServices.any((s) => s['title'] == service['title']);
                        return _buildMasterServiceCard(service, isAlreadyAdded);
                      },
                      childCount: _masterServices.length,
                    ),
                  ),
                ),
                
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF8B8B8B),
          ),
        ),
      ],
    );
  }

  Widget _buildMyServiceCard(Map<String, dynamic> service) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16, left: 24, right: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A1A1A),
            Color(0xFF2A2A2A),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF333333),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Service image
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF00C977).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: service['thumbnail'] != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                          Uri.dataFromString(service['thumbnail']).data?.contentAsBytes() ?? Uint8List(0),
                      fit: BoxFit.cover,
                    ),
                  )
                : const Icon(
                    Icons.build,
                    color: Color(0xFF00C977),
                    size: 24,
                  ),
          ),
          const SizedBox(width: 16),
          
          // Service info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service['title'] ?? 'Serviço',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  service['description'] ?? '',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8B8B8B),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00C977).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'R\$ ${(service['price'] as num).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF00C977),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${service['duration_minutes']} min',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF3B82F6),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Status indicator
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF00C977),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMasterServiceCard(Map<String, dynamic> service, bool isAlreadyAdded) {
    final category = service['category'] as String? ?? 'Geral';
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A1A1A),
            const Color(0xFF2A2A2A),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAlreadyAdded ? const Color(0xFF00C977) : const Color(0xFF333333),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: isAlreadyAdded ? null : () => _showAddServiceDialog(service),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Service image
              Container(
                width: double.infinity,
                height: 60,
                decoration: BoxDecoration(
                  color: _getCategoryColor(category).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getCategoryIcon(category),
                  color: _getCategoryColor(category),
                  size: 24,
                ),
              ),
              const SizedBox(height: 8),
              
              // Service info
              Text(
                service['title'] ?? 'Serviço',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                category,
                style: TextStyle(
                  fontSize: 9,
                  color: _getCategoryColor(category),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              
              // Description
              Expanded(
                child: Text(
                  service['description'] ?? 'Serviço de qualidade',
                  style: const TextStyle(
                    fontSize: 9,
                    color: Color(0xFF8B8B8B),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 8),
              
              // Add button
              SizedBox(
                width: double.infinity,
                height: 32,
                child: ElevatedButton(
                  onPressed: isAlreadyAdded ? null : () => _showAddServiceDialog(service),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isAlreadyAdded 
                        ? const Color(0xFF00C977) 
                        : const Color(0xFF3B82F6),
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: Text(
                    isAlreadyAdded ? 'Adicionado' : 'Adicionar',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'manutenção':
        return const Color(0xFF00C977);
      case 'pneus':
        return const Color(0xFF374151);
      case 'freios':
        return const Color(0xFFEF4444);
      case 'eletrônica':
        return const Color(0xFF3B82F6);
      case 'climatização':
        return const Color(0xFF06B6A7);
      case 'suspensão':
        return const Color(0xFF8B5CF6);
      case 'transmissão':
        return const Color(0xFFF59E0B);
      case 'estética':
        return const Color(0xFFEC4899);
      default:
        return const Color(0xFF8B8B8B);
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'manutenção':
        return Icons.build;
      case 'pneus':
        return Icons.tire_repair;
      case 'freios':
        return Icons.stop_circle;
      case 'eletrônica':
        return Icons.electrical_services;
      case 'climatização':
        return Icons.ac_unit;
      case 'suspensão':
        return Icons.settings;
      case 'transmissão':
        return Icons.settings_applications;
      case 'estética':
        return Icons.cleaning_services;
      default:
        return Icons.build;
    }
  }
}
import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../../services/storage_service.dart';
import '../../services/api_service.dart';
import '../../widgets/image_picker_widget.dart';
import '../../widgets/theme_switch_widget.dart';

class ServicesConfigScreen extends StatefulWidget {
  const ServicesConfigScreen({Key? key}) : super(key: key);

  @override
  State<ServicesConfigScreen> createState() => _ServicesConfigScreenState();
}

class _ServicesConfigScreenState extends State<ServicesConfigScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  List<Map<String, dynamic>> _myServices = [];
  List<Map<String, dynamic>> _masterServices = [];
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    setState(() => _isLoading = true);
    
    try {
      final token = await StorageService.getToken();
      if (token == null) {
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      await _apiService.loadToken();
      
      // Carregar serviços da oficina
      final myServicesResponse = await _apiService.getMyServices();
      if (myServicesResponse['success']) {
        setState(() {
          _myServices = List<Map<String, dynamic>>.from(myServicesResponse['data']['services'] ?? []);
        });
      }

      // Carregar serviços master disponíveis
      final masterServicesResponse = await _apiService.getMasterServices();
      if (masterServicesResponse['success']) {
        setState(() {
          _masterServices = List<Map<String, dynamic>>.from(masterServicesResponse['data']['services'] ?? []);
        });
      }
      
    } catch (e) {
      print('Erro ao carregar serviços: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showAddServiceDialog(Map<String, dynamic> service) {
    final priceController = TextEditingController();
    final durationController = TextEditingController();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF00C977).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00C977).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.add_circle_outline,
                      color: Color(0xFF00C977),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Adicionar Serviço',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          service['title'] ?? 'Serviço',
                          style: const TextStyle(
                            color: Color(0xFF8B8B8B),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close,
                      color: Color(0xFF8B8B8B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Description
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  service['description'] ?? 'Serviço de qualidade',
                  style: const TextStyle(
                    color: Color(0xFFB8B8B8),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Price field
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Preço (R\$) - Opcional',
                  labelStyle: const TextStyle(color: Color(0xFF8B8B8B)),
                  prefixIcon: const Icon(Icons.attach_money, color: Color(0xFF00C977)),
                  filled: true,
                  fillColor: const Color(0xFF2A2A2A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF444444)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF00C977), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Duration field
              TextField(
                controller: durationController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Duração (minutos) - Opcional',
                  labelStyle: const TextStyle(color: Color(0xFF8B8B8B)),
                  prefixIcon: const Icon(Icons.access_time, color: Color(0xFF00C977)),
                  filled: true,
                  fillColor: const Color(0xFF2A2A2A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF444444)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF00C977), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(
                          color: Color(0xFF8B8B8B),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final price = priceController.text.isNotEmpty 
                            ? double.tryParse(priceController.text) ?? 0.0
                            : 0.0;
                        final duration = durationController.text.isNotEmpty
                            ? int.tryParse(durationController.text) ?? 0
                            : 0;
                        
                        Navigator.pop(context);
                        _addService(service, price, duration);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00C977),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Adicionar',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addService(Map<String, dynamic> masterService, double price, int duration) async {
    setState(() => _isSaving = true);
    
    try {
      final response = await _apiService.addService(
        title: masterService['title'],
        price: price,
        durationMinutes: duration,
        description: masterService['description'],
        thumbnail: masterService['image_url'],
      );
      
      if (response['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Serviço adicionado com sucesso!'),
            backgroundColor: Color(0xFF00C977),
          ),
        );
        _loadServices(); // Recarregar lista
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: ${response['error']}'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text('Serviços'),
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          const ThemeSwitchButton(),
          if (!_isLoading)
            TextButton(
              onPressed: _isSaving ? null : _loadServices,
              child: const Icon(
                Icons.refresh,
                color: Color(0xFF00C977),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00C977)),
              ),
            )
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Meus Serviços',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Gerencie os serviços oferecidos pela sua oficina',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF8B8B8B),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Stats
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF1A1A1A),
                                Color(0xFF2A2A2A),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF333333),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildStatItem(
                                  icon: Icons.build,
                                  value: '${_myServices.length}',
                                  label: 'Ativos',
                                  color: const Color(0xFF00C977),
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 40,
                                color: const Color(0xFF333333),
                              ),
                              Expanded(
                                child: _buildStatItem(
                                  icon: Icons.add,
                                  value: '${_masterServices.length}',
                                  label: 'Disponíveis',
                                  color: const Color(0xFF3B82F6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // My services
                if (_myServices.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'Serviços Ativos',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final service = _myServices[index];
                        return _buildMyServiceCard(service);
                      },
                      childCount: _myServices.length,
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                ],
                
                // Available services
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Serviços Disponíveis',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                
                // Master services grid
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.8,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final service = _masterServices[index];
                        final isAlreadyAdded = _myServices.any((s) => s['title'] == service['title']);
                        return _buildMasterServiceCard(service, isAlreadyAdded);
                      },
                      childCount: _masterServices.length,
                    ),
                  ),
                ),
                
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF8B8B8B),
          ),
        ),
      ],
    );
  }

  Widget _buildMyServiceCard(Map<String, dynamic> service) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16, left: 24, right: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A1A1A),
            Color(0xFF2A2A2A),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF333333),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Service image
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF00C977).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: service['thumbnail'] != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                          Uri.dataFromString(service['thumbnail']).data?.contentAsBytes() ?? Uint8List(0),
                      fit: BoxFit.cover,
                    ),
                  )
                : const Icon(
                    Icons.build,
                    color: Color(0xFF00C977),
                    size: 24,
                  ),
          ),
          const SizedBox(width: 16),
          
          // Service info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service['title'] ?? 'Serviço',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  service['description'] ?? '',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8B8B8B),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00C977).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'R\$ ${(service['price'] as num).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF00C977),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${service['duration_minutes']} min',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF3B82F6),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Status indicator
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF00C977),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMasterServiceCard(Map<String, dynamic> service, bool isAlreadyAdded) {
    final category = service['category'] as String? ?? 'Geral';
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A1A1A),
            const Color(0xFF2A2A2A),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAlreadyAdded ? const Color(0xFF00C977) : const Color(0xFF333333),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: isAlreadyAdded ? null : () => _showAddServiceDialog(service),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Service image
              Container(
                width: double.infinity,
                height: 60,
                decoration: BoxDecoration(
                  color: _getCategoryColor(category).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getCategoryIcon(category),
                  color: _getCategoryColor(category),
                  size: 24,
                ),
              ),
              const SizedBox(height: 8),
              
              // Service info
              Text(
                service['title'] ?? 'Serviço',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                category,
                style: TextStyle(
                  fontSize: 9,
                  color: _getCategoryColor(category),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              
              // Description
              Expanded(
                child: Text(
                  service['description'] ?? 'Serviço de qualidade',
                  style: const TextStyle(
                    fontSize: 9,
                    color: Color(0xFF8B8B8B),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 8),
              
              // Add button
              SizedBox(
                width: double.infinity,
                height: 32,
                child: ElevatedButton(
                  onPressed: isAlreadyAdded ? null : () => _showAddServiceDialog(service),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isAlreadyAdded 
                        ? const Color(0xFF00C977) 
                        : const Color(0xFF3B82F6),
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: Text(
                    isAlreadyAdded ? 'Adicionado' : 'Adicionar',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'manutenção':
        return const Color(0xFF00C977);
      case 'pneus':
        return const Color(0xFF374151);
      case 'freios':
        return const Color(0xFFEF4444);
      case 'eletrônica':
        return const Color(0xFF3B82F6);
      case 'climatização':
        return const Color(0xFF06B6A7);
      case 'suspensão':
        return const Color(0xFF8B5CF6);
      case 'transmissão':
        return const Color(0xFFF59E0B);
      case 'estética':
        return const Color(0xFFEC4899);
      default:
        return const Color(0xFF8B8B8B);
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'manutenção':
        return Icons.build;
      case 'pneus':
        return Icons.tire_repair;
      case 'freios':
        return Icons.stop_circle;
      case 'eletrônica':
        return Icons.electrical_services;
      case 'climatização':
        return Icons.ac_unit;
      case 'suspensão':
        return Icons.settings;
      case 'transmissão':
        return Icons.settings_applications;
      case 'estética':
        return Icons.cleaning_services;
      default:
        return Icons.build;
    }
  }
}