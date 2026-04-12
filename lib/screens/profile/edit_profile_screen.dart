import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../services/api_service.dart';
import '../../services/image_service.dart';
import '../../services/theme_service.dart';
import '../../utils/form_styles.dart';
import '../../utils/phone_formatter.dart';
import '../../utils/cep_formatter.dart';
import '../../core/app_colors.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final ApiService _apiService = ApiService();
  final ImagePicker _imagePicker = ImagePicker();
  bool _isSaving = false;
  bool _isUploadingLogo = false;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _cepController = TextEditingController();
  String? _logoUrl;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final response = await _apiService.getProfile();
      if (response['success'] == true) {
        final data = response['data'] as Map<String, dynamic>? ?? {};
        _nameController.text = data['name']?.toString() ?? '';
        // Formatar email ao carregar
        final emailValue = data['email']?.toString() ?? '';
        _emailController.text = emailValue.trim().toLowerCase();
        // Formatar telefone ao carregar
        final phoneValue = data['phone']?.toString() ?? '';
        if (phoneValue.isNotEmpty) {
          final phoneDigits = phoneValue.replaceAll(RegExp(r'\D'), '');
          if (phoneDigits.isNotEmpty) {
            _phoneController.text = PhoneInputFormatter().formatEditUpdate(
              const TextEditingValue(),
              TextEditingValue(text: phoneDigits),
            ).text;
          } else {
            _phoneController.text = phoneValue;
          }
        }
        _logoUrl = data['logo_url'] ?? data['logo'];
        // Endereço: formato plano (address, city, state, cep) ou objeto
        final addr = data['address'];
        if (addr is String && addr.trim().isNotEmpty) {
          _addressController.text = addr.trim();
        } else if (addr is Map<String, dynamic>) {
          final logradouro = addr['logradouro'] ?? addr['street'] ?? '';
          final numero = addr['numero'] ?? addr['number'] ?? '';
          _addressController.text = [logradouro, numero].where((s) => s.toString().trim().isNotEmpty).join(', ');
        }
        _cityController.text = data['city']?.toString().trim() ?? '';
        _stateController.text = data['state']?.toString().trim() ?? '';
        _cepController.text = data['cep']?.toString().trim() ?? '';
      }
    } catch (_) {
      // Mantém silencioso: tela simplificada apenas para edição básica.
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final payload = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'cep': _cepController.text.trim().replaceAll(RegExp(r'\D'), ''),
      };
      final response = await _apiService.updateProfile(payload);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response['success'] == true
                  ? 'Perfil atualizado com sucesso!'
                  : response['error']?.toString() ?? 'Erro ao atualizar perfil.',
            ),
            backgroundColor: response['success'] == true ? const Color(0xFF00C977) : Colors.redAccent,
          ),
        );
        if (response['success'] == true) {
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao atualizar perfil. Tente novamente.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _cepController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        final isDark = themeService.isDarkMode;
        final backgroundColor = isDark ? const Color(0xFF0B1120) : const Color(0xFFF5F7FA);
        final textColor = ThemeService.getTextColor(isDark);
        final secondaryText = ThemeService.getSecondaryTextColor(isDark);

        return Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(
            title: Text(
              'Editar Perfil',
              style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: IconThemeData(color: textColor),
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              children: [
                Text(
                  'Atualize as informações básicas da sua oficina.',
                  style: TextStyle(color: secondaryText),
                ),
                const SizedBox(height: 24),
                _buildTextField(
                  label: 'Nome da oficina',
                  controller: _nameController,
                  keyboardType: TextInputType.name,
                  validator: (value) => value == null || value.trim().isEmpty ? 'Informe o nome da oficina.' : null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  label: 'Email',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Informe o email.';
                    if (!value.contains('@')) return 'Informe um email válido.';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  label: 'Celular/WhatsApp',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Informe o celular.';
                    final digits = value.replaceAll(RegExp(r'[^\d]'), '');
                    if (digits.length != 11 || digits[2] != '9') {
                      return 'Celular inválido — use DDD + 9 + 8 dígitos (ex: 11987654321)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  label: 'Endereço',
                  controller: _addressController,
                  keyboardType: TextInputType.streetAddress,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  label: 'Cidade',
                  controller: _cityController,
                  keyboardType: TextInputType.text,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildTextField(
                        label: 'Estado',
                        controller: _stateController,
                        keyboardType: TextInputType.text,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _cepController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [CepFormatter()],
                        style: FormStyles.inputTextStyle(context),
                        cursorColor: AppColors.primaryColor,
                        decoration: FormStyles.decorate(
                          context,
                          const InputDecoration(
                            labelText: 'CEP',
                            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                _buildLogoSection(),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C977),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Salvar alterações'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: FormStyles.inputTextStyle(context),
      cursorColor: AppColors.primaryColor,
      decoration: FormStyles.decorate(
        context,
        InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  Widget _buildLogoSection() {
    final isDark = Provider.of<ThemeService>(context).isDarkMode;
    final textColor = ThemeService.getTextColor(isDark);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Logo da Oficina',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1F2E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF2D3441) : const Color(0xFFE5E7EB),
            ),
          ),
          child: Column(
            children: [
              // Logo atual
              if (_logoUrl != null && _logoUrl!.isNotEmpty && _logoUrl!.startsWith('http'))
                Column(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? const Color(0xFF2D3441) : const Color(0xFFE5E7EB),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          _logoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: isDark ? const Color(0xFF2D3441) : const Color(0xFFF5F7FA),
                              child: const Icon(
                                Icons.build,
                                color: Color(0xFF00C977),
                                size: 50,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              
              // Botões de ação
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isUploadingLogo ? null : _showLogoPicker,
                      icon: _isUploadingLogo
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.upload, size: 18),
                      label: Text(_logoUrl != null ? 'Alterar Logo' : 'Adicionar Logo'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF00C977),
                        side: const BorderSide(color: Color(0xFF00C977)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  if (_logoUrl != null && _logoUrl!.isNotEmpty)
                    ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isUploadingLogo ? null : _removeLogo,
                          icon: const Icon(Icons.delete_outline, size: 18),
                          label: const Text('Remover'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.redAccent,
                            side: const BorderSide(color: Colors.redAccent),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showLogoPicker() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Provider.of<ThemeService>(context).isDarkMode
              ? const Color(0xFF1A1F2E)
              : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
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
                    'Escolher Logo',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
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
                    title: const Text('Galeria'),
                    subtitle: const Text('Escolher da galeria'),
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00C977).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Color(0xFF00C977),
                        size: 24,
                      ),
                    ),
                    title: const Text('Câmera'),
                    subtitle: const Text('Tirar uma foto'),
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
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
        imageQuality: 85,
      );

      if (image != null) {
        await _uploadLogo(image);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao selecionar imagem: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _uploadLogo(XFile imageFile) async {
    setState(() => _isUploadingLogo = true);

    try {
      // Validar tipo de arquivo
      if (!ImageService.validateImageType(imageFile.path)) {
        throw 'Tipo de arquivo não suportado. Use JPG, PNG ou WebP';
      }

      // Validar tamanho
      if (!(await ImageService.validateImageSize(imageFile, 'logo'))) {
        throw 'Arquivo muito grande. Tamanho máximo: 2MB';
      }

      // Ler bytes da imagem
      final imageBytes = await imageFile.readAsBytes();
      
      // Comprimir imagem
      final compressedBytes = await ImageService.compressImageByType(imageBytes, 'logo');
      
      // Obter MIME type
      final extension = imageFile.path.toLowerCase().split('.').last;
      final mimeType = extension == 'png' 
          ? 'image/png' 
          : extension == 'webp' 
              ? 'image/webp' 
              : 'image/jpeg';
      
      // Converter para base64
      final finalBase64String = 'data:$mimeType;base64,${base64Encode(compressedBytes)}';

      // Upload via API
      final result = await _apiService.uploadLogo(finalBase64String);

      if (mounted) {
        if (result['success'] == true) {
          setState(() {
            _logoUrl = result['data']?['logo_url'] ?? result['data']?['logo'];
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Logo atualizado com sucesso!'),
              backgroundColor: Color(0xFF00C977),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error']?.toString() ?? 'Erro ao fazer upload do logo'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao fazer upload: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingLogo = false);
      }
    }
  }

  Future<void> _removeLogo() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover Logo'),
        content: const Text('Tem certeza que deseja remover o logo da oficina?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Remover'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isUploadingLogo = true);

    try {
      final result = await _apiService.removeLogo();

      if (mounted) {
        if (result['success'] == true) {
          // Remover logo localmente
          setState(() {
            _logoUrl = null;
          });
          
          // Recarregar dados completos do perfil para garantir sincronização
          await _loadProfile();
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Logo removido com sucesso!'),
              backgroundColor: Color(0xFF00C977),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error']?.toString() ?? 'Erro ao remover logo'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao remover logo: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingLogo = false);
      }
    }
  }
}


