import 'package:flutter/material.dart';

class ServiceDetailsScreen extends StatefulWidget {
  final String serviceId;

  const ServiceDetailsScreen({
    Key? key,
    required this.serviceId,
  }) : super(key: key);

  @override
  State<ServiceDetailsScreen> createState() => _ServiceDetailsScreenState();
}

class _ServiceDetailsScreenState extends State<ServiceDetailsScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _serviceData;

  @override
  void initState() {
    super.initState();
    _loadServiceData();
  }

  Future<void> _loadServiceData() async {
    setState(() => _isLoading = true);
    
    // Simular carregamento de dados do serviço
    await Future.delayed(const Duration(seconds: 1));
    
    setState(() {
      _serviceData = {
        'id': widget.serviceId,
        'title': 'Troca de Óleo',
        'description': 'Troca completa de óleo do motor com filtro de óleo incluído.',
        'price': 12000, // em centavos
        'duration_minutes': 30,
        'images': [
          'https://via.placeholder.com/300x200',
          'https://via.placeholder.com/300x200',
        ],
        'requirements': [
          'Veículo deve estar com motor frio',
          'Trazer manual do proprietário',
          'Verificar nível de óleo atual',
        ],
        'includes': [
          'Óleo do motor',
          'Filtro de óleo',
          'Mão de obra',
          'Garantia de 30 dias',
        ],
      };
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('Detalhes do Serviço'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Service Images
                  _buildServiceImages(),
                  
                  // Service Info
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title and Price
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                _serviceData?['title'] ?? 'Serviço',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                            ),
                            Text(
                              'R\$ ${(_serviceData?['price'] / 100).toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF252940),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Duration
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              size: 16,
                              color: Color(0xFF6B7280),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${_serviceData?['duration_minutes']} minutos',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Description
                        Text(
                          _serviceData?['description'] ?? '',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF1F2937),
                            height: 1.5,
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // What's Included
                        _buildSection(
                          title: 'O que está incluído',
                          items: _serviceData?['includes'] ?? [],
                          icon: Icons.check_circle,
                          color: const Color(0xFF10B981),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Requirements
                        _buildSection(
                          title: 'Requisitos',
                          items: _serviceData?['requirements'] ?? [],
                          icon: Icons.info,
                          color: const Color(0xFFF59E0B),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _editService(),
                                icon: const Icon(Icons.edit, size: 16),
                                label: const Text('Editar'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF252940),
                                  side: const BorderSide(color: Color(0xFF252940)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _deleteService(),
                                icon: const Icon(Icons.delete, size: 16),
                                label: const Text('Excluir'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFEF4444),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
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
    );
  }

  Widget _buildServiceImages() {
    final images = _serviceData?['images'] as List<dynamic>? ?? [];
    
    if (images.isEmpty) {
      return Container(
        height: 200,
        color: const Color(0xFFE5E7EB),
        child: const Center(
          child: Icon(
            Icons.image,
            size: 64,
            color: Color(0xFF9CA3AF),
          ),
        ),
      );
    }

    return SizedBox(
      height: 200,
      child: PageView.builder(
        itemCount: images.length,
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(images[index]),
                fit: BoxFit.cover,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<dynamic> items,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...items.map((item) => _buildListItem(item, color)),
      ],
    );
  }

  Widget _buildListItem(String item, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              item,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF1F2937),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _editService() {
    // TODO: Implementar edição de serviço
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidade de edição em desenvolvimento!'),
        backgroundColor: Color(0xFFF59E0B),
      ),
    );
  }

  void _deleteService() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Serviço'),
        content: const Text('Tem certeza que deseja excluir este serviço? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implementar exclusão
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Serviço excluído com sucesso!'),
                  backgroundColor: Color(0xFF10B981),
                ),
              );
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }
}






















