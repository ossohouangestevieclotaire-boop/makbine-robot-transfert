import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import '../services/foreground_task_handler.dart';
import '../services/supabase_service.dart';

class RobotTransfertScreen extends StatefulWidget {
  const RobotTransfertScreen({super.key});

  @override
  State<RobotTransfertScreen> createState() => _RobotTransfertScreenState();
}

class _RobotTransfertScreenState extends State<RobotTransfertScreen>
    with WidgetsBindingObserver {
  final SupabaseService _supabaseService = SupabaseService();

  bool isRunning = false;
  String logs = "Robot en attente de démarrage...\n";
  String? _idEnAttenteConfirmation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialiserServiceArrierePlan();
    FlutterForegroundTask.addTaskDataCallback(_surReceptionLog);
  }

  void _initialiserServiceArrierePlan() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'makbine_service',
        channelName: 'Robot Makbine actif',
        channelDescription:
            'Affiche que le robot Makbine surveille les commandes en continu.',
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(7000),
        autoRunOnBoot: false,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  void _surReceptionLog(Object data) {
    if (data is String) {
      ajouterLog(data);
      // Détecte dans le message qu'une commande vient d'être transmise pour
      // afficher le bandeau de confirmation manuelle.
      if (data.contains('Commande transmise à MacroDroid')) {
        setState(() => _idEnAttenteConfirmation = 'dernier');
      }
    }
  }

  Future<void> demarrerRobot() async {
    final permissionOk = await _demanderPermissions();
    if (!permissionOk) {
      ajouterLog("⚠️ Permissions manquantes : le robot risque de s'arrêter en arrière-plan.");
    }

    await FlutterForegroundTask.startService(
      notificationTitle: 'Makbine - Robot actif',
      notificationText: 'Surveillance des commandes en cours...',
      callback: demarrerServiceArrierePlan,
    );

    setState(() {
      isRunning = true;
      logs += _horodatage("Robot activé (service en arrière-plan).");
    });
  }

  Future<bool> _demanderPermissions() async {
    // Autorisation de notification (Android 13+).
    final notifOk = await FlutterForegroundTask.checkNotificationPermission();
    if (notifOk != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }
    // Exemption d'optimisation de batterie : sans ça, Android peut quand
    // même geler le service au bout de plusieurs heures sur certains
    // téléphones (Xiaomi, Huawei, Tecno...).
    if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
      await FlutterForegroundTask.requestIgnoreBatteryOptimization();
    }
    return true;
  }

  Future<void> arreterRobot() async {
    await FlutterForegroundTask.stopService();
    setState(() {
      isRunning = false;
      logs += _horodatage("Robot mis en pause.");
    });
  }

  Future<void> _confirmerTransfertEffectue() async {
    // Note : dans cette version, la confirmation manuelle marque la
    // dernière commande transmise. Pour un suivi précis par commande,
    // l'ID exact est visible dans les logs ci-dessus.
    ajouterLog("✅ Transfert confirmé manuellement.");
    setState(() => _idEnAttenteConfirmation = null);
  }

  String _horodatage(String message) {
    final heure = DateTime.now().toIso8601String().substring(11, 19);
    return "[$heure] $message\n";
  }

  void ajouterLog(String message) {
    if (!mounted) return;
    setState(() {
      logs += _horodatage(message);
    });
  }

  @override
  void dispose() {
    FlutterForegroundTask.removeTaskDataCallback(_surReceptionLog);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text(
          "Makbine - Serveur USSD",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.amber,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: isRunning ? null : demarrerRobot,
                    icon: const Icon(Icons.play_arrow, color: Colors.white),
                    label: const Text("DÉMARRER",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  ),
                  ElevatedButton.icon(
                    onPressed: isRunning ? arreterRobot : null,
                    icon: const Icon(Icons.stop, color: Colors.white),
                    label: const Text("ARRÊTER",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  ),
                ],
              ),
            ),
            if (isRunning) ...[
              const SizedBox(height: 8),
              const Text(
                "🟢 Service actif en arrière-plan — continue même écran éteint",
                style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ],
            if (_idEnAttenteConfirmation != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: Column(
                  children: [
                    const Text(
                      "⚠️ Une commande a été transmise à MacroDroid.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _confirmerTransfertEffectue,
                      icon: const Icon(Icons.check, color: Colors.white),
                      label: const Text("VU",
                          style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[800]),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            const Row(
              children: [
                Icon(Icons.terminal, color: Colors.grey),
                SizedBox(width: 8),
                Text("ÉCRAN DE CONTRÔLE EN TEMPS RÉEL :",
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  reverse: true,
                  child: Text(
                    logs,
                    style: const TextStyle(
                        color: Colors.greenAccent, fontFamily: 'monospace', fontSize: 13),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
