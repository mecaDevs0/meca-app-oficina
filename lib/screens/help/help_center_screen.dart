import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({Key? key}) : super(key: key);

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final _faqItems = <_FaqSection>[
    _FaqSection(
      title: 'Pagamentos e PagBank',
      icon: Icons.payment_rounded,
      items: [
        _FaqItem(
          'Como conectar o PagBank?',
          'No Perfil, toque em "PagBank" e depois em "Conectar PagBank". Siga o fluxo no navegador para autorizar o MECA. Depois, no app, toque em "Reautorizar PagBank" se precisar atualizar a conexão.',
        ),
        _FaqItem(
          'Taxas PagBank',
          'As taxas são definidas pelo PagBank e podem variar por meio (PIX/cartão) e parcelamento. Consulte no app ou site do PagBank.',
        ),
        _FaqItem(
          'O que é a taxa MECA?',
          'O MECA cobra 12% em cada pagamento (split automático). O MECA arca com 100% das taxas PagBank; você opera normalmente e recebe 88% do valor. Não há desconto de taxas do gateway para a oficina.',
        ),
        _FaqItem(
          'PagBank conectado mas não atualizou',
          'Puxe a tela do perfil para atualizar ou toque em "Reautorizar PagBank" e conclua a autorização. Isso garante que o Account ID esteja sincronizado para receber pagamentos.',
        ),
      ],
    ),
    _FaqSection(
      title: 'Agendamentos e orçamento',
      icon: Icons.calendar_today_rounded,
      items: [
        _FaqItem(
          'Como aprovar um agendamento?',
          'Na tela do agendamento, use "Aprovar" para confirmar, "Recusar" para cancelar ou "Sugerir Outro Horário" para enviar uma nova data/hora ao cliente.',
        ),
        _FaqItem(
          'Como enviar o orçamento?',
          'Com o agendamento confirmado, no dia do serviço você pode "Montar orçamento" antes de iniciar ou "Iniciar serviço" e enviar o orçamento ao finalizar. O cliente aprova no app.',
        ),
        _FaqItem(
          'Como enviar evidências do serviço?',
          'Com o serviço em andamento, toque em "Upload de Evidências" na tela do agendamento. Escolha câmera ou galeria e envie as fotos. O cliente vê as evidências no app.',
        ),
        _FaqItem(
          'Cliente não aprovou o orçamento',
          'O cliente recebe notificação. Enquanto aguarda, você pode editar o orçamento se precisar. Após aprovação, o status muda e o cliente pode pagar.',
        ),
      ],
    ),
    _FaqSection(
      title: 'Conta e configurações',
      icon: Icons.settings_rounded,
      items: [
        _FaqItem(
          'Como alterar minha senha?',
          'No Perfil, toque em "Alterar senha". Informe a senha atual e a nova (mínimo 6 caracteres).',
        ),
        _FaqItem(
          'Como configurar horários de atendimento?',
          'Em Configurações ou na agenda, você pode definir os dias e horários em que a oficina atende. O cliente só vê horários disponíveis nessa janela.',
        ),
        _FaqItem(
          'Como adicionar ou editar serviços?',
          'Em Configurações ou "Serviços", você pode cadastrar os serviços oferecidos, com nome e valor. Eles aparecem para o cliente na hora do agendamento.',
        ),
      ],
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_FaqSection> get _filteredSections {
    if (_searchQuery.trim().isEmpty) return _faqItems;
    final q = _searchQuery.trim().toLowerCase();
    return _faqItems.map((section) {
      final filtered = section.items
          .where((item) =>
              item.question.toLowerCase().contains(q) ||
              item.answer.toLowerCase().contains(q))
          .toList();
      if (filtered.isEmpty) return null;
      return _FaqSection(title: section.title, icon: section.icon, items: filtered);
    }).whereType<_FaqSection>().toList();
  }

  Future<void> _launchEmail() async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'contato@mecabr.com',
      query: 'subject=Suporte MECA - App Oficina',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o e-mail.'), backgroundColor: Colors.redAccent),
      );
    }
  }

  Future<void> _launchPhone() async {
    final uri = Uri(scheme: 'tel', path: '+551130000000');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o telefone.'), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0B0F14) : const Color(0xFFF5F6F8);
    final surface = isDark ? const Color(0xFF151B23) : Colors.white;
    final primaryText = isDark ? Colors.white : const Color(0xFF1A1D24);
    final secondaryText = isDark ? Colors.white70 : Colors.black54;
    const green = Color(0xFF00C977);

    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            backgroundColor: isDark ? const Color(0xFF0B0F14) : Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, color: primaryText),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
              title: Text(
                'Central de Ajuda',
                style: TextStyle(
                  color: primaryText,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [green.withOpacity(0.12), green.withOpacity(0.04)]
                        : [green.withOpacity(0.08), green.withOpacity(0.02)],
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 52, right: 16),
                      child: Icon(Icons.build_circle_rounded, size: 64, color: green.withOpacity(0.4)),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: 'Buscar dúvidas...',
                  hintStyle: TextStyle(color: secondaryText),
                  prefixIcon: Icon(Icons.search_rounded, color: secondaryText),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear_rounded, color: secondaryText),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
                style: TextStyle(color: primaryText, fontSize: 16),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Text(
                'Perguntas frequentes',
                style: TextStyle(
                  color: primaryText,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final section = _filteredSections[index];
                return _SectionCard(
                  section: section,
                  isDark: isDark,
                  surface: surface,
                  primaryText: primaryText,
                  secondaryText: secondaryText,
                  green: green,
                );
              },
              childCount: _filteredSections.length,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Fale conosco',
                style: TextStyle(
                  color: primaryText,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              child: Column(
                children: [
                  _ContactCard(
                    icon: Icons.email_outlined,
                    title: 'E-mail',
                    subtitle: 'contato@mecabr.com',
                    onTap: _launchEmail,
                    isDark: isDark,
                    surface: surface,
                    primaryText: primaryText,
                    secondaryText: secondaryText,
                    green: green,
                  ),
                  const SizedBox(height: 12),
                  _ContactCard(
                    icon: Icons.phone_outlined,
                    title: 'Telefone',
                    subtitle: '(11) 3000-0000',
                    onTap: _launchPhone,
                    isDark: isDark,
                    surface: surface,
                    primaryText: primaryText,
                    secondaryText: secondaryText,
                    green: green,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqSection {
  final String title;
  final IconData icon;
  final List<_FaqItem> items;
  _FaqSection({required this.title, required this.icon, required this.items});
}

class _FaqItem {
  final String question;
  final String answer;
  _FaqItem(this.question, this.answer);
}

class _SectionCard extends StatelessWidget {
  final _FaqSection section;
  final bool isDark;
  final Color surface;
  final Color primaryText;
  final Color secondaryText;
  final Color green;

  const _SectionCard({
    required this.section,
    required this.isDark,
    required this.surface,
    required this.primaryText,
    required this.secondaryText,
    required this.green,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: green.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(section.icon, color: green, size: 22),
                ),
                const SizedBox(width: 12),
                Text(
                  section.title,
                  style: TextStyle(
                    color: primaryText,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          ...section.items.map(
            (item) => _FaqItemBlock(
              question: item.question,
              answer: item.answer,
              primaryText: primaryText,
              secondaryText: secondaryText,
              isLast: item == section.items.last,
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqItemBlock extends StatelessWidget {
  final String question;
  final String answer;
  final Color primaryText;
  final Color secondaryText;
  final bool isLast;

  const _FaqItemBlock({
    required this.question,
    required this.answer,
    required this.primaryText,
    required this.secondaryText,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isLast)
          Divider(height: 1, indent: 20, endIndent: 20, color: primaryText.withOpacity(0.08)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                question,
                style: TextStyle(
                  color: primaryText,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                answer,
                style: TextStyle(
                  color: secondaryText,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ContactCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDark;
  final Color surface;
  final Color primaryText;
  final Color secondaryText;
  final Color green;

  const _ContactCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.isDark,
    required this.surface,
    required this.primaryText,
    required this.secondaryText,
    required this.green,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: green.withOpacity(0.2), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.15 : 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: green.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: green, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: primaryText,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(color: secondaryText, fontSize: 14),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 14, color: secondaryText),
            ],
          ),
        ),
      ),
    );
  }
}
