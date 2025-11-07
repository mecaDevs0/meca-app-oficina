import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../../services/api_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cnpjController = TextEditingController();
  final _addressController = TextEditingController();
  final _numberController = TextEditingController();
  final _complementController = TextEditingController();
  final _neighborhoodController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _cepController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isFetchingCep = false;
  bool _isFetchingLocation = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    
    try {
      final response = await _apiService.getProfile();
      if (response['success']) {
        final profile = response['data'] ?? {};
        final addressMap = _extractAddress(profile['address']);

        setState(() {
          _nameController.text = profile['name'] ?? '';
          _emailController.text = profile['email'] ?? '';
          _phoneController.text = profile['phone'] ?? '';
          _cnpjController.text = profile['cnpj'] ?? '';
          _addressController.text = addressMap['logradouro'] ?? '';
          _numberController.text = addressMap['numero'] ?? '';
          _complementController.text = addressMap['complemento'] ?? '';
          _neighborhoodController.text = addressMap['bairro'] ?? '';
          _cityController.text = addressMap['cidade'] ?? profile['city'] ?? '';
          _stateController.text = addressMap['estado'] ?? profile['state'] ?? '';
          _cepController.text = addressMap['cep'] ?? profile['cep'] ?? '';
          _latitudeController.text = _stringOrEmpty(profile['latitude']);
          _longitudeController.text = _stringOrEmpty(profile['longitude']);
        });
      }
    } catch (e) {
      print('Erro ao carregar perfil: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final latitude = double.tryParse(_latitudeController.text.replaceAll(',', '.'));
      final longitude = double.tryParse(_longitudeController.text.replaceAll(',', '.'));

      final address = {
        'cep': _cepController.text,
        'logradouro': _addressController.text,
        'numero': _numberController.text,
        'bairro': _neighborhoodController.text,
        'complemento': _complementController.text,
        'cidade': _cityController.text,
        'estado': _stateController.text,
      }..removeWhere((key, value) => value == null || value.toString().trim().isEmpty);

      final data = {
        'name': _nameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'cnpj': _cnpjController.text,
        if (address.isNotEmpty) 'address': address,
        'city': _cityController.text,
        'state': _stateController.text,
        'cep': _cepController.text,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      };

      final response = await _apiService.updateProfile(data);
      
      if (response['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil atualizado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        if (mounted) {
          Navigator.pop(context);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['error'] ?? 'Erro ao atualizar perfil'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF1A1A1A) : Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Editar Perfil',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        backgroundColor: const Color(0xFF00C977),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Salvar',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00C977)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Informações básicas
                    _buildSectionCard(
                      'Informações Básicas',
                      [
                        _buildTextField(
                          controller: _nameController,
                          label: 'Nome da Oficina',
                          icon: Icons.business,
                          validator: (value) {
                            if (value?.isEmpty ?? true) return 'Campo obrigatório';
                            return null;
                          },
                          isDarkMode: isDarkMode,
                        ),
                        _buildTextField(
                          controller: _emailController,
                          label: 'Email',
                          icon: Icons.email,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value?.isEmpty ?? true) return 'Campo obrigatório';
                            if (!value!.contains('@')) return 'Email inválido';
                            return null;
                          },
                          isDarkMode: isDarkMode,
                        ),
                        _buildTextField(
                          controller: _phoneController,
                          label: 'Telefone',
                          icon: Icons.phone,
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value?.isEmpty ?? true) return 'Campo obrigatório';
                            return null;
                          },
                          isDarkMode: isDarkMode,
                        ),
                        _buildTextField(
                          controller: _cnpjController,
                          label: 'CNPJ',
                          icon: Icons.badge,
                          validator: (value) {
                            if (value?.isEmpty ?? true) return 'Campo obrigatório';
                            return null;
                          },
                          isDarkMode: isDarkMode,
                        ),
                      ],
                      isDarkMode,
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Endereço
                    _buildSectionCard(
                      'Endereço',
                      [
                        Text(
                          'Busque pelo CEP ou utilize sua localização atual para preencher automaticamente.',
                          style: TextStyle(
                            color: isDarkMode ? Colors.white70 : Colors.grey[700],
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _cepController,
                          label: 'CEP',
                          icon: Icons.pin_drop,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.search,
                          validator: (value) {
                            if (value?.isEmpty ?? true) return 'Campo obrigatório';
                            return null;
                          },
                          onEditingComplete: _isFetchingCep ? null : _fetchAddressFromCep,
                          suffix: _isFetchingCep
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : IconButton(
                                  icon: const Icon(Icons.search),
                                  onPressed: _isFetchingCep ? null : _fetchAddressFromCep,
                                ),
                          isDarkMode: isDarkMode,
                        ),
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: _buildTextField(
                                controller: _addressController,
                                label: 'Logradouro',
                                icon: Icons.location_on,
                                validator: (value) {
                                  if (value?.isEmpty ?? true) return 'Campo obrigatório';
                                  return null;
                                },
                                onEditingComplete: _geocodeCurrentAddress,
                                isDarkMode: isDarkMode,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTextField(
                                controller: _numberController,
                                label: 'Número',
                                icon: Icons.tag,
                                onEditingComplete: _geocodeCurrentAddress,
                                isDarkMode: isDarkMode,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _complementController,
                                label: 'Complemento',
                                icon: Icons.add_location_alt_outlined,
                                isDarkMode: isDarkMode,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTextField(
                                controller: _neighborhoodController,
                                label: 'Bairro',
                                icon: Icons.apartment,
                                onEditingComplete: _geocodeCurrentAddress,
                                isDarkMode: isDarkMode,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: _buildTextField(
                                controller: _cityController,
                                label: 'Cidade',
                                icon: Icons.location_city,
                                validator: (value) {
                                  if (value?.isEmpty ?? true) return 'Campo obrigatório';
                                  return null;
                                },
                                onEditingComplete: _geocodeCurrentAddress,
                                isDarkMode: isDarkMode,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTextField(
                                controller: _stateController,
                                label: 'Estado',
                                icon: Icons.map,
                                validator: (value) {
                                  if (value?.isEmpty ?? true) return 'Campo obrigatório';
                                  return null;
                                },
                                onEditingComplete: _geocodeCurrentAddress,
                                isDarkMode: isDarkMode,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _latitudeController,
                                label: 'Latitude',
                                icon: Icons.my_location,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: false),
                                isDarkMode: isDarkMode,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTextField(
                                controller: _longitudeController,
                                label: 'Longitude',
                                icon: Icons.my_location_outlined,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: false),
                                isDarkMode: isDarkMode,
                              ),
                            ),
                          ],
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedButton.icon(
                            onPressed: _isFetchingLocation ? null : _useCurrentLocation,
                            icon: _isFetchingLocation
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.near_me, size: 18),
                            label: Text(
                              _isFetchingLocation ? 'Obtendo localização...' : 'Usar localização atual',
                            ),
                          ),
                        ),
                      ],
                      isDarkMode,
                    ),
                    
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionCard(String title, List<Widget> children, bool isDarkMode) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Map<String, dynamic> _extractAddress(dynamic raw) {
    if (raw == null) return {};

    if (raw is Map<String, dynamic>) {
      return Map<String, dynamic>.from(raw);
    }

    if (raw is String) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          return Map<String, dynamic>.from(decoded);
        }
      } catch (_) {
        return {'raw': raw};
      }
    }

    return {'raw': raw.toString()};
  }

  String _stringOrEmpty(dynamic value) {
    if (value == null) return '';
    final stringValue = value.toString();
    if (stringValue.toLowerCase() == 'null') return '';
    return stringValue;
  }

  Future<void> _fetchAddressFromCep() async {
    final cep = _cepController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cep.length != 8) {
      _showSnack('Informe um CEP com 8 dígitos.', Colors.orange);
      return;
    }

    setState(() => _isFetchingCep = true);
    try {
      final response = await http.get(Uri.parse('https://viacep.com.br/ws/$cep/json/'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic> && data['erro'] != true) {
          setState(() {
            _addressController.text = data['logradouro'] ?? _addressController.text;
            _neighborhoodController.text = data['bairro'] ?? _neighborhoodController.text;
            _cityController.text = data['localidade'] ?? _cityController.text;
            _stateController.text = data['uf'] ?? _stateController.text;
          });
          await _geocodeCurrentAddress();
        } else {
          _showSnack('CEP não encontrado.', Colors.orange);
        }
      } else {
        _showSnack('Não foi possível buscar o CEP agora.', Colors.red);
      }
    } catch (e) {
      _showSnack('Erro ao buscar CEP: $e', Colors.red);
    } finally {
      if (mounted) {
        setState(() => _isFetchingCep = false);
      }
    }
  }

  Future<void> _geocodeCurrentAddress() async {
    final components = [
      _addressController.text,
      _numberController.text,
      _neighborhoodController.text,
      _cityController.text,
      _stateController.text,
      _cepController.text,
      'Brasil',
    ].where((value) => value.trim().isNotEmpty).join(', ');

    if (components.isEmpty) return;

    try {
      final locations = await locationFromAddress(components);
      if (locations.isNotEmpty && mounted) {
        final location = locations.first;
        setState(() {
          _latitudeController.text = location.latitude.toStringAsFixed(6);
          _longitudeController.text = location.longitude.toStringAsFixed(6);
        });
      }
    } catch (_) {
      // Ignorar erros silenciosamente para não atrapalhar fluxo
    }
  }

  Future<void> _useCurrentLocation() async {
    if (!mounted) return;
    setState(() => _isFetchingLocation = true);
    try {
      final permissionGranted = await _ensureLocationPermission();
      if (!permissionGranted) {
        _showSnack('Permissão de localização negada.', Colors.orange);
        return;
      }

      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      if (mounted) {
        setState(() {
          _latitudeController.text = position.latitude.toStringAsFixed(6);
          _longitudeController.text = position.longitude.toStringAsFixed(6);
        });
      }

      final placemarks = await placemarkFromCoordinates(position.latitude, position.longitude, localeIdentifier: 'pt_BR');
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        if (mounted) {
          setState(() {
            _addressController.text = place.thoroughfare ?? _addressController.text;
            _numberController.text = place.subThoroughfare ?? _numberController.text;
            _neighborhoodController.text = place.subLocality ?? _neighborhoodController.text;
            _cityController.text = place.subAdministrativeArea ?? place.locality ?? _cityController.text;
            _stateController.text = place.administrativeArea ?? _stateController.text;
            _cepController.text = place.postalCode?.replaceAll('-', '') ?? _cepController.text;
          });
        }
      }
    } catch (e) {
      _showSnack('Erro ao obter localização: $e', Colors.red);
    } finally {
      if (mounted) {
        setState(() => _isFetchingLocation = false);
      }
    }
  }

  Future<bool> _ensureLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showSnack('Habilite os serviços de localização.', Colors.orange);
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showSnack('Permissão de localização permanentemente negada nas configurações.', Colors.orange);
      return false;
    }

    return true;
  }

  void _showSnack(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    required bool isDarkMode,
    Widget? suffix,
    TextInputAction? textInputAction,
    VoidCallback? onEditingComplete,
    bool readOnly = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        textInputAction: textInputAction,
        onEditingComplete: onEditingComplete,
        readOnly: readOnly,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF00C977)),
          suffixIcon: suffix,
          filled: true,
          fillColor: isDarkMode ? const Color(0xFF1A1A1A) : Colors.grey[50],
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
          labelStyle: TextStyle(
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        style: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black87,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cnpjController.dispose();
    _addressController.dispose();
    _numberController.dispose();
    _complementController.dispose();
    _neighborhoodController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _cepController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }
}








