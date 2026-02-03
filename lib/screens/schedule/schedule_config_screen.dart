import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../core/app_colors.dart';

class ScheduleConfigScreen extends StatefulWidget {
  const ScheduleConfigScreen({Key? key}) : super(key: key);

  @override
  State<ScheduleConfigScreen> createState() => _ScheduleConfigScreenState();
}

class _ScheduleConfigScreenState extends State<ScheduleConfigScreen> {
  final ApiService _apiService = ApiService();
  bool _loading = false;
  
  final Map<String, Map<String, dynamic>> _schedule = {
    'monday': {'enabled': true, 'start': '08:00', 'end': '18:00'},
    'tuesday': {'enabled': true, 'start': '08:00', 'end': '18:00'},
    'wednesday': {'enabled': true, 'start': '08:00', 'end': '18:00'},
    'thursday': {'enabled': true, 'start': '08:00', 'end': '18:00'},
    'friday': {'enabled': true, 'start': '08:00', 'end': '18:00'},
    'saturday': {'enabled': true, 'start': '08:00', 'end': '12:00'},
    'sunday': {'enabled': false, 'start': '08:00', 'end': '18:00'},
  };

  final Map<String, String> _dayNames = {
    'monday': 'Segunda-feira',
    'tuesday': 'Terça-feira',
    'wednesday': 'Quarta-feira',
    'thursday': 'Quinta-feira',
    'friday': 'Sexta-feira',
    'saturday': 'Sábado',
    'sunday': 'Domingo',
  };

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    final result = await _apiService.getSchedule();
    if (result['success'] && result['data'] != null) {
      // Load existing schedule
    }
  }

  Future<void> _saveSchedule() async {
    setState(() => _loading = true);

    final result = await _apiService.updateSchedule(_schedule);

    setState(() => _loading = false);

    if (result['success']) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agenda configurada com sucesso!'),
          backgroundColor: AppColors.primaryColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLightGrayColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Configurar Horários',
          style: TextStyle(color: Color(0xFF252940), fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF252940)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Defina seus horários de atendimento',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 20),

          ..._schedule.entries.map((entry) {
            return _buildDayCard(entry.key, entry.value);
          }).toList(),

          const SizedBox(height: 30),

          // Save Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _saveSchedule,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 5,
              ),
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Salvar Configurações',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayCard(String day, Map<String, dynamic> config) {
    final isEnabled = config['enabled'] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isEnabled ? AppColors.primaryColor : Colors.grey[300]!,
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
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _dayNames[day] ?? day,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF252940),
                ),
              ),
              Switch(
                value: isEnabled,
                onChanged: (value) {
                  setState(() {
                    _schedule[day]!['enabled'] = value;
                  });
                },
                thumbColor: MaterialStateProperty.all(AppColors.primaryColor),
              ),
            ],
          ),
          if (isEnabled) ...[
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: _buildTimeSelector(
                    label: 'Abertura',
                    time: config['start'],
                    onChanged: (time) {
                      setState(() {
                        _schedule[day]!['start'] = time;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _buildTimeSelector(
                    label: 'Fechamento',
                    time: config['end'],
                    onChanged: (time) {
                      setState(() {
                        _schedule[day]!['end'] = time;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeSelector({
    required String label,
    required String time,
    required Function(String) onChanged,
  }) {
    return InkWell(
      onTap: () async {
        final TimeOfDay? picked = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(
            hour: int.parse(time.split(':')[0]),
            minute: int.parse(time.split(':')[1]),
          ),
        );

        if (picked != null) {
          final formattedTime = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
          onChanged(formattedTime);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF252940),
                  ),
                ),
                Icon(Icons.access_time, color: Colors.grey[400], size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
