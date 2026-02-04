import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/api_service.dart';
import '../../services/theme_service.dart';

class PagBankConfigScreen extends StatefulWidget {
  const PagBankConfigScreen({super.key});

  @override
  State<PagBankConfigScreen> createState() => _PagBankConfigScreenState();
}

class _PagBankConfigScreenState extends State<PagBankConfigScreen> with WidgetsBindingObserver {
  final ApiService _apiService = ApiService();
  final TextEditingController _accountIdController = TextEditingController();
  bool _isLoading = true;
  bool _isConnecting = false;
  Map<String, dynamic>? _pagbankData;
  String? _errorMessage;
  bool _refreshOnResume = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Aguardar o próximo frame antes de carregar dados
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadPagBankData();
      }
    });
  }

  void _safeSetState(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

  @override
  void dispose() {
    _accountIdController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    if (state == AppLifecycleState.resumed && _refreshOnResume) {
      _refreshOnResume = false;
      _loadPagBankData();
    }
  }

  Future<void> _loadPagBankData() async {
    if (!mounted) return;
    
    _safeSetState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Garantir que o token está carregado antes de fazer a chamada
      await _apiService.loadToken();
      
      if (!mounted) return;
      
      // Verificar se tem workshopId antes de fazer a chamada
      final workshopId = await _apiService.getWorkshopId();
      if (workshopId == null) {
        _safeSetState(() {
          _errorMessage = 'Token inválido ou workshopId não encontrado. Faça login novamente.';
          _isLoading = false;
        });
        return;
      }
      
      if (!mounted) return;
      
      final response = await _apiService.getPagBankAccount();
      if (!mounted) return;
      
      if (response['success'] == true) {
        final data = response['data'] as Map<String, dynamic>?;
        _safeSetState(() => _pagbankData = data);
      } else {
        _safeSetState(() => _errorMessage = response['error']?.toString() ?? 'Erro ao carregar dados PagBank.');
      }
    } catch (e) {
      if (mounted) {
        _safeSetState(() => _errorMessage = 'Erro ao carregar dados PagBank: $e');
      }
    } finally {
      if (mounted) {
        _safeSetState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleConnectPagBank() async {
    if (_isConnecting) return;
    
    if (!mounted) return;
    
    _safeSetState(() => _isConnecting = true);
    
    String? feedback;
    bool shouldReload = false;

    try {
      // Garantir que o token está carregado antes de fazer a chamada
      await _apiService.loadToken();
      
      if (!mounted) {
        _safeSetState(() => _isConnecting = false);
        return;
      }
      
      // Verificar se tem workshopId antes de fazer a chamada
      final workshopId = await _apiService.getWorkshopId();
      if (workshopId == null) {
        feedback = 'Token inválido ou workshopId não encontrado. Faça login novamente.';
        if (mounted) {
          _safeSetState(() => _isConnecting = false);
          try {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(feedback),
              backgroundColor: Colors.red,
            ));
          } catch (e) {
            print('Erro ao mostrar snackbar: $e');
          }
        }
        return;
      }
      
      if (!mounted) {
        _safeSetState(() => _isConnecting = false);
        return;
      }
      
      final response = await _apiService.startPagBankConnect();
      
      if (!mounted) {
        _safeSetState(() => _isConnecting = false);
        return;
      }
      
      if (response['success'] == true) {
        final data = Map<String, dynamic>.from(response['data'] ?? {});
        final authorizeUrl = (data['authorize_url'] ?? data['url'] ?? data['redirect_url'])?.toString();
        final expiresIn = data['expires_in_minutes'];

        if (authorizeUrl != null && authorizeUrl.isNotEmpty) {
          try {
            final uri = Uri.parse(authorizeUrl);
            final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);

            if (!launched) {
              feedback = 'Não foi possível abrir a página de autorização do PagBank.';
            } else {
              feedback = expiresIn != null
                  ? 'Autorização PagBank aberta. Conclua o processo em até $expiresIn minutos.'
                  : 'Autorização PagBank aberta em uma nova janela.';
              // Ao voltar do navegador, atualizamos automaticamente.
              _refreshOnResume = true;
              shouldReload = true;
            }
          } catch (e) {
            feedback = 'Erro ao abrir URL de autorização: $e';
          }
        } else {
          feedback = 'A API não retornou a URL de autorização do PagBank.';
        }
      } else {
        feedback = response['error']?.toString() ?? 'Falha ao iniciar o fluxo PagBank Connect.';
      }
    } catch (e) {
      feedback = 'Erro ao iniciar PagBank Connect: $e';
      print('Erro detalhado ao conectar PagBank: $e');
    } finally {
      if (mounted) {
        _safeSetState(() => _isConnecting = false);
        
        if (feedback != null && feedback.isNotEmpty) {
          // Usar um pequeno delay para garantir que o estado foi atualizado
          await Future.delayed(const Duration(milliseconds: 150));
          if (mounted) {
            try {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(feedback),
                backgroundColor: feedback.contains('Erro') || feedback.contains('não foi possível') 
                    ? Colors.red 
                    : Colors.green,
                duration: const Duration(seconds: 4),
              ));
            } catch (e) {
              print('Erro ao mostrar snackbar: $e');
            }
          }
        }
        
        // Recarregar dados apenas se a autorização foi aberta com sucesso
        if (shouldReload) {
          await Future.delayed(const Duration(milliseconds: 800));
          if (mounted) {
            await _loadPagBankData();
          }
        }
      }
    }
  }

  bool _isPagBankConnected() {
    final d = _pagbankData;
    if (d == null) return false;
    return d['connected'] == true;
  }

  Future<void> _handleLinkByAccountId(String accountId) async {
    final id = accountId.trim().toUpperCase();
    if (id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe o Account ID (começa com ACCO_)'), backgroundColor: Colors.orange),
      );
      return;
    }
    if (!id.startsWith('ACCO_')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account ID deve começar com ACCO_'), backgroundColor: Colors.orange),
      );
      return;
    }
    _safeSetState(() => _isConnecting = true);
    try {
      final res = await _apiService.updatePagBankAccountId(id);
      if (!mounted) return;
      if (res['success'] == true) {
        final message = res['message']?.toString().trim() ?? 'Account ID vinculado. Toque em "Reautorizar PagBank" acima para autorizar e poder receber pagamentos.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.green, duration: const Duration(seconds: 5)),
        );
        await _loadPagBankData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['error']?.toString() ?? 'Erro ao vincular'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) _safeSetState(() => _isConnecting = false);
    }
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
              'PagBank',
              style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: IconThemeData(color: textColor),
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _loadPagBankData,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                    children: [
                      _buildStatusCard(isDark, textColor, secondaryText),
                      const SizedBox(height: 24),
                      _buildInfoCard(isDark, textColor, secondaryText),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        icon: Icon(_pagbankData == null ? Icons.link : Icons.refresh),
                        label: Text(_isPagBankConnected()
                            ? 'Reautorizar PagBank'
                            : 'Conectar PagBank'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00C977),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: _isConnecting ? null : _handleConnectPagBank,
                      ),
                      const SizedBox(height: 24),
                      _buildLinkByAccountIdSection(isDark, textColor, secondaryText),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildStatusCard(bool isDark, Color textColor, Color secondaryText) {
    final hasAccountId = _pagbankData?['has_account_id'] == true ||
        (_pagbankData?['pagbank_account_id'] ?? '').toString().trim().isNotEmpty;
    final connected = _pagbankData?['connected'] == true;
    final connectionPending = _pagbankData?['connection_pending'] == true;
    final linkedByAccountId = _pagbankData?['linked_by_account_id'] == true;
    final verified = _pagbankData?['pagbank_verified'] == true || _pagbankData?['approved_by_workshop'] == true;
    final status = (_pagbankData?['status'] ?? 'pending').toString();
    final statusLabel = !connected
        ? (connectionPending || hasAccountId ? 'Conexão pendente' : 'Não conectado')
        : (verified ? 'Conectado e verificado' : _statusLabel(status));
    final cardColor = isDark ? const Color(0xFF101826) : Colors.white;

    final shadowColor = isDark
        ? const Color.fromRGBO(0, 0, 0, 0.3)
        : const Color.fromRGBO(158, 158, 158, 0.2);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(0, 201, 119, 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.account_balance_wallet_outlined, color: Color(0xFF00C977)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status da conta PagBank',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        color: _statusColor(status),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (connectionPending)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF97316).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Para receber pagamentos: toque em "Reautorizar PagBank" abaixo e autorize no navegador. Depois volte ao app.',
                            style: TextStyle(
                              fontSize: 12,
                              color: secondaryText,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ),
                    if (linkedByAccountId || hasAccountId)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          linkedByAccountId
                              ? 'Vinculado por Account ID (informado manualmente)'
                              : 'Account ID vinculado',
                          style: TextStyle(
                            fontSize: 12,
                            color: secondaryText,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    if (connected && !linkedByAccountId && hasAccountId == false)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'Vinculado por OAuth (autorização no PagBank)',
                          style: TextStyle(
                            fontSize: 12,
                            color: secondaryText,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLinkByAccountIdSection(bool isDark, Color textColor, Color secondaryText) {
    final cardColor = isDark ? const Color(0xFF101826) : Colors.white;
    final borderColor = secondaryText.withOpacity(0.2);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 20, color: secondaryText),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Opcional: já tem o Account ID?',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Não é um ou outro: para receber pagamentos você sempre precisa tocar em "Conectar PagBank" (botão verde acima) e autorizar no navegador. Se você já tem o Account ID (começa com ACCO_), pode informá-lo abaixo antes — mas ainda é obrigatório tocar em "Conectar PagBank" para concluir.',
            style: TextStyle(fontSize: 13, color: secondaryText, height: 1.4),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _accountIdController,
            decoration: InputDecoration(
              hintText: 'ACCO_68F4577A-FFD6-4C11-B98D-C6E08C51441E',
              labelText: 'Account ID PagBank',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.account_balance_wallet_outlined, size: 20),
            ),
            textCapitalization: TextCapitalization.characters,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: _isConnecting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.link),
              label: const Text('Vincular Account ID'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF00C977),
                side: const BorderSide(color: Color(0xFF00C977)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _isConnecting ? null : () => _handleLinkByAccountId(_accountIdController.text),
            ),
          ),
        ],
      ),
    );
  }

  String _formatValue(dynamic value) {
    if (value == null) return '-';
    
    // Se for um Map, formatar como campos individuais
    if (value is Map) {
      final entries = value.entries
          .where((e) => e.value != null && e.value.toString().isNotEmpty)
          .map((e) => '${_formatFieldName(e.key.toString())}: ${_formatValue(e.value)}')
          .join('\n');
      return entries.isEmpty ? '-' : entries;
    }
    
    // Se for uma List, formatar como lista
    if (value is List) {
      if (value.isEmpty) return '-';
      return value.map((item) => _formatValue(item)).join(', ');
    }
    
    // Se for bool, traduzir
    if (value is bool) {
      return value ? 'Sim' : 'Não';
    }
    
    // Se for string vazia
    if (value.toString().trim().isEmpty) {
      return '-';
    }
    
    return value.toString();
  }

  String _formatFieldName(String key) {
    final fieldNames = {
      'id': 'ID',
      'status': 'Status',
      'name': 'Nome',
      'document': 'Documento',
      'type': 'Tipo',
      'account_name': 'Nome da Conta',
      'account_document': 'CPF/CNPJ',
      'bank_name': 'Banco',
      'agency': 'Agência',
      'account': 'Conta',
      'pix_key': 'Chave PIX',
      'updated_at': 'Atualizado em',
    };
    
    return fieldNames[key.toLowerCase()] ?? key;
  }

  Widget _buildInfoCard(bool isDark, Color textColor, Color secondaryText) {
    final cardColor = isDark ? const Color(0xFF101826) : Colors.white;

    final shadowColor = isDark
        ? const Color.fromRGBO(0, 0, 0, 0.3)
        : const Color.fromRGBO(158, 158, 158, 0.15);

    // Dados principais
    final accountData = _pagbankData;
    final hasAccountId = accountData?['has_account_id'] == true ||
        (accountData?['pagbank_account_id'] ?? '').toString().trim().isNotEmpty;
    final connected = accountData?['connected'] == true;
    final linkedByAccountId = accountData?['linked_by_account_id'] == true;
    
    // Lista de campos para exibir, com prioridade
    final fieldsToShow = <MapEntry<String, dynamic>>[];
    
    if (accountData != null) {
      // Account ID (sempre mostrar quando existir - transparência total)
      if (accountData['pagbank_account_id'] != null &&
          accountData['pagbank_account_id'].toString().trim().isNotEmpty) {
        fieldsToShow.add(MapEntry('Account ID PagBank', accountData['pagbank_account_id']));
      }
      // Campos diretos (não objetos)
      if (accountData['account_name'] != null) {
        fieldsToShow.add(MapEntry('Nome', accountData['account_name']));
      }
      if (accountData['account_document'] != null) {
        fieldsToShow.add(MapEntry('CPF/CNPJ', accountData['account_document']));
      }
      if (accountData['bank_name'] != null) {
        fieldsToShow.add(MapEntry('Banco', accountData['bank_name']));
      }
      if (accountData['agency'] != null) {
        fieldsToShow.add(MapEntry('Agência', accountData['agency']));
      }
      if (accountData['pix_key'] != null) {
        fieldsToShow.add(MapEntry('Chave PIX', accountData['pix_key']));
      }
      
      // Se account é um objeto, extrair campos dele (não adicionar o objeto inteiro)
      if (accountData['account'] is Map) {
        final accountObj = accountData['account'] as Map;
        if (accountObj['id'] != null) {
          fieldsToShow.add(MapEntry('ID da Conta', accountObj['id']));
        }
        if (accountObj['status'] != null) {
          final status = accountObj['status'].toString();
          fieldsToShow.add(MapEntry('Status da Conta', _statusLabel(status)));
        }
        if (accountObj['name'] != null && accountObj['name'].toString().trim().isNotEmpty) {
          fieldsToShow.add(MapEntry('Nome', accountObj['name']));
        }
        if (accountObj['document'] != null && accountObj['document'].toString().trim().isNotEmpty) {
          fieldsToShow.add(MapEntry('Documento', accountObj['document']));
        }
        if (accountObj['type'] != null) {
          final type = accountObj['type'].toString();
          fieldsToShow.add(MapEntry('Tipo de Conta', _formatAccountType(type)));
        }
      } else if (accountData['account'] != null && accountData['account'] is! Map) {
        // Se account não é um objeto, adicionar como string simples
        fieldsToShow.add(MapEntry('Conta', accountData['account']));
      }
      
      // Campos de data
      if (accountData['updated_at'] != null) {
        fieldsToShow.add(MapEntry('Atualizado em', _formatDate(accountData['updated_at'])));
      }
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Como vincular sua conta',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Para receber pagamentos há um único fluxo: autorizar no PagBank. O passo 1 é obrigatório.',
            style: TextStyle(fontSize: 13, color: secondaryText, height: 1.35),
          ),
          const SizedBox(height: 14),
          _buildGuideStep(
            number: '1',
            title: 'Toque em “Conectar PagBank” (obrigatório)',
            description: 'Abre a página do PagBank para você autorizar a integração. Sem isso não é possível receber pagamentos.',
            isDark: isDark,
            textColor: textColor,
            secondaryText: secondaryText,
          ),
          const SizedBox(height: 12),
          _buildGuideStep(
            number: '2',
            title: 'Faça login e autorize',
            description: 'A aprovação é feita no ambiente do PagBank e pode levar alguns instantes.',
            isDark: isDark,
            textColor: textColor,
            secondaryText: secondaryText,
          ),
          const SizedBox(height: 12),
          _buildGuideStep(
            number: '3',
            title: 'Volte para o MECA',
            description: 'Assim que você voltar para o app, o status atualiza automaticamente.',
            isDark: isDark,
            textColor: textColor,
            secondaryText: secondaryText,
          ),
          if (connected == false) ...[
            const SizedBox(height: 16),
            Text(
              'Dica: se você já autorizou no PagBank e não atualizou, puxe a tela para atualizar.',
              style: TextStyle(color: secondaryText, fontSize: 12),
            ),
          ],
          if (accountData == null || fieldsToShow.isEmpty)
            Text(
              'Conecte sua conta PagBank para receber pagamentos automaticamente.',
              style: TextStyle(color: secondaryText),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: fieldsToShow
                  .where((entry) => entry.value != null && _formatValue(entry.value) != '-')
                  .map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.key,
                            style: TextStyle(
                              color: secondaryText,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _formatValue(entry.value),
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  String _formatAccountType(String type) {
    final types = {
      'checking': 'Conta Corrente',
      'savings': 'Conta Poupança',
      'payment': 'Conta Pagamento',
    };
    return types[type.toLowerCase()] ?? type;
  }

  String _formatDate(dynamic date) {
    if (date == null) return '-';
    try {
      final dateStr = date.toString();
      // Se já está formatado, retornar
      if (dateStr.contains('/') || dateStr.contains('-')) {
        return dateStr;
      }
      // Tentar parsear como DateTime
      final dt = DateTime.parse(dateStr);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (e) {
      return date.toString();
    }
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'active':
        return 'Conta conectada';
      case 'pending':
        return 'Conexão pendente';
      case 'rejected':
      case 'inactive':
        return 'Conexão inativa';
      default:
        return status;
    }
  }

  Widget _buildGuideStep({
    required String number,
    required String title,
    required String description,
    required bool isDark,
    required Color textColor,
    required Color secondaryText,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: const Color(0xFF00C977).withOpacity(0.15),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFF00C977).withOpacity(0.35)),
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Color(0xFF00C977),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(color: textColor, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(color: secondaryText, height: 1.25),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'active':
        return const Color(0xFF22C55E);
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'rejected':
      case 'inactive':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF94A3B8);
    }
  }
}

