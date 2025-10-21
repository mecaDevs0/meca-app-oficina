import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../../services/theme_service.dart';

class PagBankConfigScreen extends StatefulWidget {
  const PagBankConfigScreen({Key? key}) : super(key: key);

  @override
  State<PagBankConfigScreen> createState() => _PagBankConfigScreenState();
}

class _PagBankConfigScreenState extends State<PagBankConfigScreen> {
  bool _isLoading = true;
  bool _isTesting = false;
  bool _isCreating = false;
  Map<String, dynamic>? _pagbankData;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadPagBankData();
  }

  Future<void> _loadPagBankData() async {
    setState(() => _isLoading = true);
    
    try {
      final token = await StorageService.getToken();
      if (token == null) {
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      await _apiService.loadToken();
      
      final response = await _apiService.getPagBankAccount();
      if (response['success']) {
        setState(() {
          _pagbankData = response['data'];
        });
      }
      
    } catch (e) {
      print('Erro ao carregar dados PagBank: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testConnection() async {
    setState(() => _isTesting = true);
    
    try {
      final response = await _apiService.testPagBankConnection();
      
      if (response['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['data']['message'] ?? 'Conexão testada com sucesso!'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
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
      setState(() => _isTesting = false);
    }
  }

  Future<void> _createAccount() async {
    setState(() => _isCreating = true);
    
    try {
      // Dados de exemplo para criar conta
      final response = await _apiService.createPagBankAccount(
        name: 'Oficina Teste',
        email: 'teste@oficina.com',
        document: '12345678000199',
        type: 'company',
        address: {
          'street': 'Rua Teste',
          'number': '123',
          'neighborhood': 'Centro',
          'city': 'São Paulo',
          'state': 'SP',
          'zip_code': '01234567',
          'country': 'BR'
        },
        phone: {
          'country': '55',
          'area': '11',
          'number': '999999999'
        }
      );
      
      if (response['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Conta PagBank criada com sucesso!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        _loadPagBankData(); // Recarregar dados
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
      setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final isDark = themeService.isDarkMode;
    final bgColor = ThemeService.getBackgroundColor(isDark);
    final cardColor = ThemeService.getCardColor(isDark);
    final textColor = ThemeService.getTextColor(isDark);
    final secondaryTextColor = ThemeService.getSecondaryTextColor(isDark);
    
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          'PagBank',
          style: TextStyle(color: textColor),
        ),
        backgroundColor: cardColor,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _testConnection,
            icon: _isTesting 
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.wifi_protected_setup),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadPagBankData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Text(
                      'Integração PagBank',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Configure sua conta PagBank para receber pagamentos',
                      style: TextStyle(
                        fontSize: 16,
                        color: secondaryTextColor,
                      ),
                    ),
                    SizedBox(height: 24),
                    
                    // Status da conta
                    _buildAccountStatus(cardColor, textColor, secondaryTextColor),
                    SizedBox(height: 24),
                    
                    // Informações da conta
                    if (_pagbankData?['has_account'] == true)
                      _buildAccountInfo(cardColor, textColor, secondaryTextColor),
                    
                    SizedBox(height: 24),
                    
                    // Contas bancárias
                    if (_pagbankData?['has_account'] == true)
                      _buildBankAccounts(cardColor, textColor, secondaryTextColor),
                    
                    SizedBox(height: 24),
                    
                    // Ações
                    _buildActions(cardColor, textColor),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildAccountStatus(Color cardColor, Color textColor, Color secondaryTextColor) {
    final hasAccount = _pagbankData?['has_account'] == true;
    final account = _pagbankData?['account'];
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: hasAccount 
                      ? const Color(0xFF10B981).withOpacity(0.1)
                      : const Color(0xFFF59E0B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  hasAccount ? Icons.check_circle : Icons.warning,
                  color: hasAccount 
                      ? const Color(0xFF10B981)
                      : const Color(0xFFF59E0B),
                  size: 24,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasAccount ? 'Conta PagBank Ativa' : 'Conta PagBank Não Configurada',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    Text(
                      hasAccount 
                          ? 'Sua conta está configurada e pronta para receber pagamentos'
                          : 'Configure sua conta para começar a receber pagamentos',
                      style: TextStyle(
                        fontSize: 14,
                        color: secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          if (hasAccount && account != null) ...[
            SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _buildInfoRow('Nome', account['name'] ?? 'N/A', textColor, secondaryTextColor),
                  _buildInfoRow('Email', account['email'] ?? 'N/A', textColor, secondaryTextColor),
                  _buildInfoRow('Documento', account['document'] ?? 'N/A', textColor, secondaryTextColor),
                  _buildInfoRow('Status', account['status'] ?? 'N/A', textColor, secondaryTextColor),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAccountInfo(Color cardColor, Color textColor, Color secondaryTextColor) {
    final account = _pagbankData?['account'];
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informações da Conta',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          SizedBox(height: 16),
          if (account != null) ...[
            _buildInfoRow('ID da Conta', account['id'] ?? 'N/A', textColor, secondaryTextColor),
            _buildInfoRow('Tipo', account['type'] ?? 'N/A', textColor, secondaryTextColor),
            _buildInfoRow('Criado em', _formatDate(account['created_at']), textColor, secondaryTextColor),
            _buildInfoRow('Atualizado em', _formatDate(account['updated_at']), textColor, secondaryTextColor),
          ],
        ],
      ),
    );
  }

  Widget _buildBankAccounts(Color cardColor, Color textColor, Color secondaryTextColor) {
    final bankAccounts = _pagbankData?['bank_accounts'] as List<dynamic>? ?? [];
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Contas Bancárias',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const Spacer(),
              Text(
                '${bankAccounts.length} conta(s)',
                style: TextStyle(
                  fontSize: 14,
                  color: secondaryTextColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          
          if (bankAccounts.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Nenhuma conta bancária configurada',
                  style: TextStyle(
                    fontSize: 16,
                    color: secondaryTextColor,
                  ),
                ),
              ),
            )
          else
            ...bankAccounts.map((account) => _buildBankAccountCard(account, textColor, secondaryTextColor)),
        ],
      ),
    );
  }

  Widget _buildBankAccountCard(Map<String, dynamic> account, Color textColor, Color secondaryTextColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getStatusColor(account['status']).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.account_balance,
                  color: _getStatusColor(account['status']),
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account['holder_name'] ?? 'N/A',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    Text(
                      '${account['bank_code']} - ${account['agency_number']} / ${account['account_number']}',
                      style: TextStyle(
                        fontSize: 14,
                        color: secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(account['status']).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getStatusText(account['status']),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _getStatusColor(account['status']),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActions(Color cardColor, Color textColor) {
    final hasAccount = _pagbankData?['has_account'] == true;
    
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isTesting ? null : _testConnection,
            icon: _isTesting 
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(cardColor),
                    ),
                  )
                : Icon(Icons.wifi_protected_setup),
            label: Text(_isTesting ? 'Testando...' : 'Testar Conexão'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        
        if (!hasAccount) ...[
          SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isCreating ? null : _createAccount,
              icon: _isCreating 
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(cardColor),
                      ),
                    )
                  : Icon(Icons.add),
              label: Text(_isCreating ? 'Criando...' : 'Criar Conta PagBank'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF252940),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, Color textColor, Color secondaryTextColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: secondaryTextColor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'approved':
        return const Color(0xFF10B981);
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'rejected':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF6B7280);
    }
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'approved':
        return 'Aprovado';
      case 'pending':
        return 'Pendente';
      case 'rejected':
        return 'Rejeitado';
      default:
        return 'Desconhecido';
    }
  }

  String _formatDate(String? date) {
    if (date == null) return 'N/A';
    
    try {
      final dateTime = DateTime.parse(date);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return date;
    }
  }
}


















import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../../services/theme_service.dart';

class PagBankConfigScreen extends StatefulWidget {
  const PagBankConfigScreen({Key? key}) : super(key: key);

  @override
  State<PagBankConfigScreen> createState() => _PagBankConfigScreenState();
}

class _PagBankConfigScreenState extends State<PagBankConfigScreen> {
  bool _isLoading = true;
  bool _isTesting = false;
  bool _isCreating = false;
  Map<String, dynamic>? _pagbankData;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadPagBankData();
  }

  Future<void> _loadPagBankData() async {
    setState(() => _isLoading = true);
    
    try {
      final token = await StorageService.getToken();
      if (token == null) {
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      await _apiService.loadToken();
      
      final response = await _apiService.getPagBankAccount();
      if (response['success']) {
        setState(() {
          _pagbankData = response['data'];
        });
      }
      
    } catch (e) {
      print('Erro ao carregar dados PagBank: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testConnection() async {
    setState(() => _isTesting = true);
    
    try {
      final response = await _apiService.testPagBankConnection();
      
      if (response['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['data']['message'] ?? 'Conexão testada com sucesso!'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
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
      setState(() => _isTesting = false);
    }
  }

  Future<void> _createAccount() async {
    setState(() => _isCreating = true);
    
    try {
      // Dados de exemplo para criar conta
      final response = await _apiService.createPagBankAccount(
        name: 'Oficina Teste',
        email: 'teste@oficina.com',
        document: '12345678000199',
        type: 'company',
        address: {
          'street': 'Rua Teste',
          'number': '123',
          'neighborhood': 'Centro',
          'city': 'São Paulo',
          'state': 'SP',
          'zip_code': '01234567',
          'country': 'BR'
        },
        phone: {
          'country': '55',
          'area': '11',
          'number': '999999999'
        }
      );
      
      if (response['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Conta PagBank criada com sucesso!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        _loadPagBankData(); // Recarregar dados
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
      setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final isDark = themeService.isDarkMode;
    final bgColor = ThemeService.getBackgroundColor(isDark);
    final cardColor = ThemeService.getCardColor(isDark);
    final textColor = ThemeService.getTextColor(isDark);
    final secondaryTextColor = ThemeService.getSecondaryTextColor(isDark);
    
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          'PagBank',
          style: TextStyle(color: textColor),
        ),
        backgroundColor: cardColor,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _testConnection,
            icon: _isTesting 
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.wifi_protected_setup),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadPagBankData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Text(
                      'Integração PagBank',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Configure sua conta PagBank para receber pagamentos',
                      style: TextStyle(
                        fontSize: 16,
                        color: secondaryTextColor,
                      ),
                    ),
                    SizedBox(height: 24),
                    
                    // Status da conta
                    _buildAccountStatus(cardColor, textColor, secondaryTextColor),
                    SizedBox(height: 24),
                    
                    // Informações da conta
                    if (_pagbankData?['has_account'] == true)
                      _buildAccountInfo(cardColor, textColor, secondaryTextColor),
                    
                    SizedBox(height: 24),
                    
                    // Contas bancárias
                    if (_pagbankData?['has_account'] == true)
                      _buildBankAccounts(cardColor, textColor, secondaryTextColor),
                    
                    SizedBox(height: 24),
                    
                    // Ações
                    _buildActions(cardColor, textColor),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildAccountStatus(Color cardColor, Color textColor, Color secondaryTextColor) {
    final hasAccount = _pagbankData?['has_account'] == true;
    final account = _pagbankData?['account'];
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: hasAccount 
                      ? const Color(0xFF10B981).withOpacity(0.1)
                      : const Color(0xFFF59E0B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  hasAccount ? Icons.check_circle : Icons.warning,
                  color: hasAccount 
                      ? const Color(0xFF10B981)
                      : const Color(0xFFF59E0B),
                  size: 24,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasAccount ? 'Conta PagBank Ativa' : 'Conta PagBank Não Configurada',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    Text(
                      hasAccount 
                          ? 'Sua conta está configurada e pronta para receber pagamentos'
                          : 'Configure sua conta para começar a receber pagamentos',
                      style: TextStyle(
                        fontSize: 14,
                        color: secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          if (hasAccount && account != null) ...[
            SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _buildInfoRow('Nome', account['name'] ?? 'N/A', textColor, secondaryTextColor),
                  _buildInfoRow('Email', account['email'] ?? 'N/A', textColor, secondaryTextColor),
                  _buildInfoRow('Documento', account['document'] ?? 'N/A', textColor, secondaryTextColor),
                  _buildInfoRow('Status', account['status'] ?? 'N/A', textColor, secondaryTextColor),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAccountInfo(Color cardColor, Color textColor, Color secondaryTextColor) {
    final account = _pagbankData?['account'];
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informações da Conta',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          SizedBox(height: 16),
          if (account != null) ...[
            _buildInfoRow('ID da Conta', account['id'] ?? 'N/A', textColor, secondaryTextColor),
            _buildInfoRow('Tipo', account['type'] ?? 'N/A', textColor, secondaryTextColor),
            _buildInfoRow('Criado em', _formatDate(account['created_at']), textColor, secondaryTextColor),
            _buildInfoRow('Atualizado em', _formatDate(account['updated_at']), textColor, secondaryTextColor),
          ],
        ],
      ),
    );
  }

  Widget _buildBankAccounts(Color cardColor, Color textColor, Color secondaryTextColor) {
    final bankAccounts = _pagbankData?['bank_accounts'] as List<dynamic>? ?? [];
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Contas Bancárias',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const Spacer(),
              Text(
                '${bankAccounts.length} conta(s)',
                style: TextStyle(
                  fontSize: 14,
                  color: secondaryTextColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          
          if (bankAccounts.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Nenhuma conta bancária configurada',
                  style: TextStyle(
                    fontSize: 16,
                    color: secondaryTextColor,
                  ),
                ),
              ),
            )
          else
            ...bankAccounts.map((account) => _buildBankAccountCard(account, textColor, secondaryTextColor)),
        ],
      ),
    );
  }

  Widget _buildBankAccountCard(Map<String, dynamic> account, Color textColor, Color secondaryTextColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getStatusColor(account['status']).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.account_balance,
                  color: _getStatusColor(account['status']),
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account['holder_name'] ?? 'N/A',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    Text(
                      '${account['bank_code']} - ${account['agency_number']} / ${account['account_number']}',
                      style: TextStyle(
                        fontSize: 14,
                        color: secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(account['status']).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getStatusText(account['status']),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _getStatusColor(account['status']),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActions(Color cardColor, Color textColor) {
    final hasAccount = _pagbankData?['has_account'] == true;
    
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isTesting ? null : _testConnection,
            icon: _isTesting 
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(cardColor),
                    ),
                  )
                : Icon(Icons.wifi_protected_setup),
            label: Text(_isTesting ? 'Testando...' : 'Testar Conexão'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        
        if (!hasAccount) ...[
          SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isCreating ? null : _createAccount,
              icon: _isCreating 
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(cardColor),
                      ),
                    )
                  : Icon(Icons.add),
              label: Text(_isCreating ? 'Criando...' : 'Criar Conta PagBank'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF252940),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, Color textColor, Color secondaryTextColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: secondaryTextColor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'approved':
        return const Color(0xFF10B981);
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'rejected':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF6B7280);
    }
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'approved':
        return 'Aprovado';
      case 'pending':
        return 'Pendente';
      case 'rejected':
        return 'Rejeitado';
      default:
        return 'Desconhecido';
    }
  }

  String _formatDate(String? date) {
    if (date == null) return 'N/A';
    
    try {
      final dateTime = DateTime.parse(date);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return date;
    }
  }
}
















