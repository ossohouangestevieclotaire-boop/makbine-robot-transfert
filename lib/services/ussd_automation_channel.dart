import 'package:flutter/services.dart';

class UssdAutomationChannel {
  static const MethodChannel _channel = MethodChannel('makbine/ussd_automation');

  /// Lance le composeur MTN et démarre l'automatisation du menu.
  /// S'arrête automatiquement avant le code secret.
  static Future<void> demarrerTransfertMtn({
    required String numero,
    required String montant,
  }) async {
    await _channel.invokeMethod('demarrerTransfertMtn', {
      'numero': numero,
      'montant': montant,
    });
  }

  /// Ouvre l'écran système où l'utilisateur active le service d'accessibilité.
  /// À appeler une seule fois, lors de la première installation de l'app.
  static Future<void> ouvrirParametresAccessibilite() async {
    await _channel.invokeMethod('ouvrirParametresAccessibilite');
  }
}
