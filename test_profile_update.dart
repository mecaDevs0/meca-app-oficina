import 'package:flutter/material.dart';

import 'lib/services/api_service.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test Profile Update',
      home: TestProfileUpdate(),
    );
  }
}

class TestProfileUpdate extends StatefulWidget {
  @override
  _TestProfileUpdateState createState() => _TestProfileUpdateState();
}

class _TestProfileUpdateState extends State<TestProfileUpdate> {
  final ApiService _apiService = ApiService();
  String _result = 'Clique em "Testar" para verificar o método updateProfile';

  Future<void> _testUpdateProfile() async {
    setState(() {
      _result = 'Testando...';
    });

    try {
      final testData = {
        'name': 'Oficina Teste',
        'email': 'teste@oficina.com',
        'phone': '11999999999',
        'cnpj': '12345678000199',
        'address': {
          'logradouro': 'Rua Teste, 123',
          'cidade': 'São Paulo',
          'estado': 'SP',
          'cep': '01234567',
        },
      };

      final response = await _apiService.updateProfile(testData);
      
      setState(() {
        _result = 'Resultado: ${response.toString()}';
      });
    } catch (e) {
      setState(() {
        _result = 'Erro: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Test Profile Update'),
        backgroundColor: Color(0xFF00C977),
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _testUpdateProfile,
              child: Text('Testar updateProfile'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF00C977),
                foregroundColor: Colors.white,
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  _result,
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
