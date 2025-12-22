import 'package:flutter/material.dart';

class VerifyAccountModal extends StatelessWidget {
  final VoidCallback onVerify;

  const VerifyAccountModal({Key? key, required this.onVerify}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final secondaryText = isDark ? Colors.grey[400] : Colors.grey[600];
    final cardColor = isDark ? const Color(0xFF2D2D2D) : (Colors.grey[50] ?? Colors.white);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.verified_user,
                    color: Color(0xFF3B82F6),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Validar Conta PagBank',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  color: secondaryText,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Para validar sua conta PagBank, siga estes passos:',
              style: TextStyle(
                fontSize: 16,
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            _buildStep(
              step: 1,
              title: 'Abra o App PagBank',
              description: 'Entre no aplicativo PagBank no seu celular',
              icon: Icons.phone_android,
              textColor: textColor,
              secondaryText: secondaryText,
              cardColor: cardColor,
            ),
            const SizedBox(height: 12),
            _buildStep(
              step: 2,
              title: 'Faça Login',
              description: 'Entre com o email e senha da conta que você conectou',
              icon: Icons.login,
              textColor: textColor,
              secondaryText: secondaryText,
              cardColor: cardColor,
            ),
            const SizedBox(height: 12),
            _buildStep(
              step: 3,
              title: 'Complete a Validação',
              description: 'Siga as instruções no app para validar sua conta e documentos',
              icon: Icons.verified,
              textColor: textColor,
              secondaryText: secondaryText,
              cardColor: cardColor,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7).withOpacity(isDark ? 0.2 : 1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFCD34D).withOpacity(isDark ? 0.5 : 1),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFFF59E0B), size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Após validar no app PagBank, clique em "Sim, já validei" abaixo para verificar.',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white70 : const Color(0xFF78350F),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: secondaryText ?? Colors.grey),
                    ),
                    child: Text(
                      'Cancelar',
                      style: TextStyle(color: secondaryText ?? Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: onVerify,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00C977),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Sim, já validei'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep({
    required int step,
    required String title,
    required String description,
    required IconData icon,
    required Color textColor,
    required Color? secondaryText,
    required Color cardColor,
  }) {
    final secText = secondaryText ?? Colors.grey;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                '$step',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3B82F6),
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
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: secText,
                  ),
                ),
              ],
            ),
          ),
          Icon(icon, color: const Color(0xFF3B82F6), size: 24),
        ],
      ),
    );
  }
}

