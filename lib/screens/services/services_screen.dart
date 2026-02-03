import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({Key? key}) : super(key: key);

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _myServices = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    setState(() => _loading = true);
    
    final result = await _apiService.getMyServices();
    
    if (result['success']) {
      setState(() {
        _myServices = (result['data']['services'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Meus Serviços',
          style: TextStyle(
            color: Color(0xFF252940),
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, color: Color(0xFF00C977), size: 28),
            onPressed: () {
              Navigator.pushNamed(context, '/add-service').then((_) => _loadServices());
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00C977)))
          : _myServices.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.build_circle, size: 80, color: Colors.grey[300]),
                      const SizedBox(height: 20),
                      const Text(
                        'Nenhum serviço cadastrado',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(context, '/add-service').then((_) => _loadServices());
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Adicionar Serviço'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00C977),
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: const Color(0xFF00C977),
                  onRefresh: _loadServices,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(15),
                    itemCount: _myServices.length,
                    itemBuilder: (context, index) {
                      final service = _myServices[index];
                      return _buildServiceCard(service);
                    },
                  ),
                ),
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> service) {
    final isActive = service['is_active'] ?? true;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive ? const Color(0xFF00C977) : Colors.grey[300]!,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    service['title'] ?? 'Serviço',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF252940),
                    ),
                  ),
                ),
                Switch(
                  value: isActive,
                  onChanged: (value) async {
                    await _apiService.updateService(
                      serviceId: service['id'],
                      isActive: value,
                    );
                    _loadServices();
                  },
                  thumbColor: MaterialStateProperty.all(const Color(0xFF00C977)),
                ),
              ],
            ),
            if (service['description'] != null) ...[
              const SizedBox(height: 10),
              Text(
                service['description'],
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 5),
                    Text(
                      '${service['duration_minutes'] ?? 60} min',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                ),
                Text(
                  'R\$ ${(service['price'] ?? 0) / 100}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00C977),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/edit-service',
                        arguments: service,
                      ).then((_) => _loadServices());
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Editar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF00C977),
                      side: const BorderSide(color: Color(0xFF00C977)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
