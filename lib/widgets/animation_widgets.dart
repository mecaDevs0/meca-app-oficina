import 'package:flutter/material.dart';

class AnimationWidgets {
  /// Widget para exibir a animação de entrada do app
  static Widget buildEnterAnimation({double? width, double? height}) {
    return Container(
      width: width ?? 400,
      height: height ?? 400,
      child: Image.asset(
        'assets/animations/AnimacaoEnter.gif',
        fit: BoxFit.contain,
        gaplessPlayback: false,
      ),
    );
  }

  /// Widget para exibir a animação de loading (logo branca em loop)
  static Widget buildLoadingAnimation({double? width, double? height}) {
    return Container(
      width: width ?? 200,
      height: height ?? 200,
      child: Image.asset(
        'assets/animations/AnimacaoLogoBranca.gif',
        fit: BoxFit.contain,
        gaplessPlayback: true,
      ),
    );
  }

  /// Tela de splash com animação de entrada
  static Widget buildSplashScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF1F2937),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            buildEnterAnimation(width: 350, height: 350),
            const SizedBox(height: 40),
            const Text(
              'MECA',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Oficina',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF00C977),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Widget de loading com animação
  static Widget buildLoadingWidget({
    String? message,
    double? size,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          buildLoadingAnimation(
            width: size ?? 180,
            height: size ?? 180,
          ),
          if (message != null) ...[
            const SizedBox(height: 24),
            Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  /// Dialog de loading com animação
  static void showLoadingDialog(BuildContext context, {String? message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: buildLoadingWidget(message: message),
        ),
      ),
    );
  }

  /// Fechar dialog de loading
  static void hideLoadingDialog(BuildContext context) {
    Navigator.of(context).pop();
  }
}





class AnimationWidgets {
  /// Widget para exibir a animação de entrada do app
  static Widget buildEnterAnimation({double? width, double? height}) {
    return Container(
      width: width ?? 400,
      height: height ?? 400,
      child: Image.asset(
        'assets/animations/AnimacaoEnter.gif',
        fit: BoxFit.contain,
        gaplessPlayback: false,
      ),
    );
  }

  /// Widget para exibir a animação de loading (logo branca em loop)
  static Widget buildLoadingAnimation({double? width, double? height}) {
    return Container(
      width: width ?? 200,
      height: height ?? 200,
      child: Image.asset(
        'assets/animations/AnimacaoLogoBranca.gif',
        fit: BoxFit.contain,
        gaplessPlayback: true,
      ),
    );
  }

  /// Tela de splash com animação de entrada
  static Widget buildSplashScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF1F2937),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            buildEnterAnimation(width: 350, height: 350),
            const SizedBox(height: 40),
            const Text(
              'MECA',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Oficina',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF00C977),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Widget de loading com animação
  static Widget buildLoadingWidget({
    String? message,
    double? size,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          buildLoadingAnimation(
            width: size ?? 180,
            height: size ?? 180,
          ),
          if (message != null) ...[
            const SizedBox(height: 24),
            Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  /// Dialog de loading com animação
  static void showLoadingDialog(BuildContext context, {String? message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: buildLoadingWidget(message: message),
        ),
      ),
    );
  }

  /// Fechar dialog de loading
  static void hideLoadingDialog(BuildContext context) {
    Navigator.of(context).pop();
  }
}




