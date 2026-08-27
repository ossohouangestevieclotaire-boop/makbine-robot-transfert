import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Envoie une notification système contenant les infos de la commande,
/// dans un format simple à découper par MacroDroid (séparateur "|").
///
/// Format du corps de la notification : id|numero|operateur|montant
/// Exemple : 135|0556724316|MTN|100
class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialiser() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(settings);

    // Depuis Android 13, il faut demander explicitement l'autorisation
    // d'afficher des notifications, sinon elles restent invisibles sans
    // aucune erreur.
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.requestNotificationsPermission();
  }

  static Future<void> envoyerCommandePourMacroDroid({
    required String id,
    required String numero,
    required String operateur,
    required String montant,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'makbine_commandes',
      'Commandes Makbine',
      channelDescription:
          'Notifications lues par MacroDroid pour lancer le transfert USSD',
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(''),
    );
    const details = NotificationDetails(android: androidDetails);

    await _plugin.show(
      1,
      'MAKBINE_COMMANDE',
      '$id|$numero|$operateur|$montant',
      details,
    );
  }
}
