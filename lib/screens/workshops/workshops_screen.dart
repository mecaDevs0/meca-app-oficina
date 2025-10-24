import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import 'workshop_detail_screen.dart';

class WorkshopsScreen extends StatefulWidget {
  const WorkshopsScreen({Key? key}) : super(key: key);

  @override
  State<WorkshopsScreen> createState() => _WorkshopsScreenState();
}

class _WorkshopsScreenState extends State<WorkshopsScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _workshops = [];
  bool _loading = true;
  String _searchQuery = '';
  String _selectedService = 'all';
  String _selectedDistance = 'all';
  String _selectedRating = 'all';
  String _selectedInstallment = 'all';
  String _sortBy = 'distance';

  @override
  void initState() {
    super.initState();
    _loadWorkshops();
  }

  Future<void> _loadWorkshops() async {
    setState(() => _loading = true);
    
    try {
      final response = await _apiService.getNearbyWorkshops(-23.5505, -46.6333);
      if (response['success']) {
        setState(() {
          _workshops = List<Map<String, dynamic>>.from(response['data']['workshops'] ?? []);
        });
      }
    } catch (e) {
      print('Erro ao carregar oficinas: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF1A1A1A) : Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Oficinas Próximas',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.white,
            fontSize: 16,
          ),
        ),
        backgroundColor: const Color(0xFF00C977),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onPressed: _showFilterModal,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00C977)))
          : Column(
              children: [
                // Barra de pesquisa
                Container(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                    },
                    decoration: InputDecoration(
                      hintText: 'Buscar por nome ou bairro...',
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF00C977)),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF00C977), width: 2),
                      ),
                    ),
                  ),
                ),
                
                // Lista de oficinas
                Expanded(
                  child: _buildWorkshopsList(),
                ),
              ],
            ),
    );
  }

  Widget _buildWorkshopsList() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final filteredWorkshops = _getFilteredWorkshops();
    
    if (filteredWorkshops.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.build,
              size: 80,
              color: isDarkMode ? Colors.grey[600] : Colors.grey[300],
            ),
            const SizedBox(height: 20),
            Text(
              'Nenhuma oficina encontrada',
              style: TextStyle(
                fontSize: 18,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredWorkshops.length,
      itemBuilder: (context, index) {
        return _buildWorkshopCard(filteredWorkshops[index], isDarkMode);
      },
    );
  }

  Widget _buildWorkshopCard(Map<String, dynamic> workshop, bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WorkshopDetailScreen(workshop: workshop),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Logo da oficina
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF00C977).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.build,
                  color: Color(0xFF00C977),
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              
              // Informações da oficina
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workshop['name'] ?? 'Oficina',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      workshop['address'] ?? 'Endereço não informado',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Distância e avaliação
                    Row(
                      children: [
                        if (workshop['distance'] != null) ...[
                          const Icon(
                            Icons.navigation,
                            size: 16,
                            color: Color(0xFF00C977),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${workshop['distance'].toStringAsFixed(1)} km',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF00C977),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 16),
                        ],
                        if (workshop['rating'] != null) ...[
                          const Icon(
                            Icons.star,
                            size: 16,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            workshop['rating'].toString(),
                            style: TextStyle(
                              fontSize: 12,
                              color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              
              // Indicador de parcelamento
              if (workshop['aceita_parcelamento'] == true)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C977).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Parcelamento',
                    style: TextStyle(
                      fontSize: 10,
                      color: Color(0xFF00C977),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getFilteredWorkshops() {
    var filtered = _workshops.where((workshop) {
      // Filtro por pesquisa
      if (_searchQuery.isNotEmpty) {
        final name = (workshop['name'] ?? '').toLowerCase();
        final address = (workshop['address'] ?? '').toLowerCase();
        final query = _searchQuery.toLowerCase();
        if (!name.contains(query) && !address.contains(query)) {
          return false;
        }
      }
      
      // Filtro por serviço
      if (_selectedService != 'all') {
        // Implementar filtro por serviço se necessário
      }
      
      // Filtro por distância
      if (_selectedDistance != 'all') {
        final distance = workshop['distance'] ?? 0.0;
        switch (_selectedDistance) {
          case '0-5':
            if (distance > 5) return false;
            break;
          case '5-10':
            if (distance < 5 || distance > 10) return false;
            break;
          case '10+':
            if (distance < 10) return false;
            break;
        }
      }
      
      // Filtro por avaliação
      if (_selectedRating != 'all') {
        final rating = workshop['rating'] ?? 0.0;
        switch (_selectedRating) {
          case '4+':
            if (rating < 4) return false;
            break;
          case '3-4':
            if (rating < 3 || rating >= 4) return false;
            break;
          case '3-':
            if (rating >= 3) return false;
            break;
        }
      }
      
      // Filtro por parcelamento
      if (_selectedInstallment != 'all') {
        final aceitaParcelamento = workshop['aceita_parcelamento'] ?? false;
        if (_selectedInstallment == 'yes' && !aceitaParcelamento) return false;
        if (_selectedInstallment == 'no' && aceitaParcelamento) return false;
      }
      
      return true;
    }).toList();
    
    // Ordenação
    switch (_sortBy) {
      case 'distance':
        filtered.sort((a, b) {
          final distanceA = a['distance'] ?? 999.0;
          final distanceB = b['distance'] ?? 999.0;
          return distanceA.compareTo(distanceB);
        });
        break;
      case 'rating':
        filtered.sort((a, b) {
          final ratingA = a['rating'] ?? 0.0;
          final ratingB = b['rating'] ?? 0.0;
          return ratingB.compareTo(ratingA);
        });
        break;
      case 'name':
        filtered.sort((a, b) {
          final nameA = a['name'] ?? '';
          final nameB = b['name'] ?? '';
          return nameA.compareTo(nameB);
        });
        break;
    }
    
    return filtered;
  }

  void _showFilterModal() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[600] : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filtros e Ordenação',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedService = 'all';
                        _selectedDistance = 'all';
                        _selectedRating = 'all';
                        _selectedInstallment = 'all';
                        _sortBy = 'distance';
                      });
                    },
                    child: const Text(
                      'Limpar',
                      style: TextStyle(color: Color(0xFF00C977)),
                    ),
                  ),
                ],
              ),
            ),
            
            // Conteúdo
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ordenação
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle('Ordenar por', isDarkMode),
                          const SizedBox(height: 12),
                          _buildSortOption('Distância', 'distance', isDarkMode),
                          _buildSortOption('Avaliação', 'rating', isDarkMode),
                          _buildSortOption('Nome', 'name', isDarkMode),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Filtros
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle('Filtrar por', isDarkMode),
                          const SizedBox(height: 16),
                          
                          // Distância
                          _buildFilterTitle('Distância', isDarkMode),
                          _buildFilterOption('Todas', 'all', _selectedDistance, (value) {
                            setState(() => _selectedDistance = value);
                          }, isDarkMode),
                          _buildFilterOption('0-5 km', '0-5', _selectedDistance, (value) {
                            setState(() => _selectedDistance = value);
                          }, isDarkMode),
                          _buildFilterOption('5-10 km', '5-10', _selectedDistance, (value) {
                            setState(() => _selectedDistance = value);
                          }, isDarkMode),
                          _buildFilterOption('10+ km', '10+', _selectedDistance, (value) {
                            setState(() => _selectedDistance = value);
                          }, isDarkMode),
                          
                          const SizedBox(height: 16),
                          
                          // Avaliação
                          _buildFilterTitle('Avaliação', isDarkMode),
                          _buildFilterOption('Todas', 'all', _selectedRating, (value) {
                            setState(() => _selectedRating = value);
                          }, isDarkMode),
                          _buildFilterOption('4+ estrelas', '4+', _selectedRating, (value) {
                            setState(() => _selectedRating = value);
                          }, isDarkMode),
                          _buildFilterOption('3-4 estrelas', '3-4', _selectedRating, (value) {
                            setState(() => _selectedRating = value);
                          }, isDarkMode),
                          _buildFilterOption('Menos de 3', '3-', _selectedRating, (value) {
                            setState(() => _selectedRating = value);
                          }, isDarkMode),
                          
                          const SizedBox(height: 16),
                          
                          // Parcelamento
                          _buildFilterTitle('Parcelamento', isDarkMode),
                          _buildFilterOption('Todas', 'all', _selectedInstallment, (value) {
                            setState(() => _selectedInstallment = value);
                          }, isDarkMode),
                          _buildFilterOption('Aceita parcelamento', 'yes', _selectedInstallment, (value) {
                            setState(() => _selectedInstallment = value);
                          }, isDarkMode),
                          _buildFilterOption('Não aceita parcelamento', 'no', _selectedInstallment, (value) {
                            setState(() => _selectedInstallment = value);
                          }, isDarkMode),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            
            // Botão aplicar
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C977),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Aplicar Filtros',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDarkMode) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: isDarkMode ? Colors.white : Colors.black87,
      ),
    );
  }

  Widget _buildFilterTitle(String title, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
        ),
      ),
    );
  }

  Widget _buildSortOption(String title, String value, bool isDarkMode) {
    return RadioListTile<String>(
      title: Text(
        title,
        style: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black87,
        ),
      ),
      value: value,
      groupValue: _sortBy,
      onChanged: (value) {
        setState(() => _sortBy = value!);
      },
      activeColor: const Color(0xFF00C977),
    );
  }

  Widget _buildFilterOption(String title, String value, String selectedValue, Function(String) onChanged, bool isDarkMode) {
    return RadioListTile<String>(
      title: Text(
        title,
        style: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black87,
        ),
      ),
      value: value,
      groupValue: selectedValue,
      onChanged: (value) => onChanged(value!),
      activeColor: const Color(0xFF00C977),
    );
  }
}
