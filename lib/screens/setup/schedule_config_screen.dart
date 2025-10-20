import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/colors.dart';
import '../../providers/auth_provider.dart';

class ScheduleConfigScreen extends StatefulWidget {
  const ScheduleConfigScreen({super.key});

  @override
  State<ScheduleConfigScreen> createState() => _ScheduleConfigScreenState();
}

class _ScheduleConfigScreenState extends State<ScheduleConfigScreen> {
  final Map<String, Map<String, String>> _schedule = {
    'segunda': {'inicio': '08:00', 'fim': '18:00', 'ativo': 'true'},
    'terca': {'inicio': '08:00', 'fim': '18:00', 'ativo': 'true'},
    'quarta': {'inicio': '08:00', 'fim': '18:00', 'ativo': 'true'},
    'quinta': {'inicio': '08:00', 'fim': '18:00', 'ativo': 'true'},
    'sexta': {'inicio': '08:00', 'fim': '18:00', 'ativo': 'true'},
    'sabado': {'inicio': '08:00', 'fim': '13:00', 'ativo': 'true'},
    'domingo': {'inicio': '', 'fim': '', 'ativo': 'false'},
  };

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('Configurar Horários'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Horário de Funcionamento',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Defina os horários em que sua oficina estará disponível para agendamentos',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: _schedule.entries.map((entry) {
                return _buildDayCard(entry.key, entry.value);
              }).toList(),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: ElevatedButton(
                onPressed: authProvider.isLoading
                    ? null
                    : () async {
                        final success = await authProvider.updateWorkshop({
                          'horario_funcionamento': _schedule,
                        });

                        if (success && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Horários salvos com sucesso!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          Navigator.pop(context);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Salvar Horários',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayCard(String day, Map<String, String> hours) {
    final isActive = hours['ativo'] == 'true';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  day.substring(0, 1).toUpperCase() + day.substring(1),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Switch(
                  value: isActive,
                  activeColor: AppColors.primary,
                  onChanged: (value) {
                    setState(() {
                      _schedule[day]!['ativo'] = value.toString();
                    });
                  },
                ),
              ],
            ),
            if (isActive) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: hours['inicio'],
                      decoration: const InputDecoration(
                        labelText: 'Abertura',
                        hintText: '08:00',
                        prefixIcon: Icon(Icons.access_time, size: 20),
                      ),
                      keyboardType: TextInputType.datetime,
                      onChanged: (value) {
                        _schedule[day]!['inicio'] = value;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      initialValue: hours['fim'],
                      decoration: const InputDecoration(
                        labelText: 'Fechamento',
                        hintText: '18:00',
                        prefixIcon: Icon(Icons.access_time, size: 20),
                      ),
                      keyboardType: TextInputType.datetime,
                      onChanged: (value) {
                        _schedule[day]!['fim'] = value;
                      },
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

        children: [
          const Text(
            'Horário de Funcionamento',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 20),
          ..._schedule.entries.map((entry) {
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    SizedBox(
                      width: 60,
                      child: Text(
                        entry.key.toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: Text('${entry.value['inicio']} - ${entry.value['fim']}'),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, color: AppColors.secondary),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Agenda salva!')),
              );
              Navigator.pop(context);
            },
            child: const Text('Salvar Agenda'),
          ),
        ],
      ),
    );
  }
}

