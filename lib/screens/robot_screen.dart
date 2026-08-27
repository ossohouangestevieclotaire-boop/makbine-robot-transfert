import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/transaction_makbine.dart';
import '../services/operateur_service.dart';
import '../services/reseau_service.dart';
import '../services/supabase_service.dart';
import '../services/notification_service.dart';

class RobotTransfertScreen extends StatefulWidget {
  const RobotTransfertScreen({super.key});

  @override
  State<RobotTransfertScreen> createState() => _RobotTransfertScreenState();
}

class _RobotTransfertScreenState extends State<RobotTransfertScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  final ReseauService _reseauService = ReseauService();

  bool isRunning = false;
  Timer? _timer;
  String logs = "Robot en attente de démarrage...\n";

  int _intervalleSecondes = 5;
  int _erreursConsecutives = 0;
  String? _idEnAttenteConfirmation;

  void demarrerRobot() {
    setState(() {
      isRunning = true;
      _erreursConsecutives = 0;
      _intervalleSecondes = 5;
      logs += _horodatage("Robot activé. Écoute de makbine.ci...");
    });
    _programmerProchainScan();
  }

  void arreterRobot() {
    _timer?.cancel();
    setState(() {
      isRunning = false;
      logs += _horodatage("Robot mis en pause.");
    });
  }

  void _programmerProchainScan() {
    _timer?.cancel();
    _timer = Timer(Duration(seconds: _intervalleSecondes), () async {
      await _cycleDeVerification();
      if (isRunning) _programmerProchainScan();
    });
  }

  Future<void> _cycleDeVerification() async {
    final connecte = await _reseauService.estConnecte();
    if (!connecte) {
      ajouterLog("⚠️ Pas de connexion internet. Nouvel essai dans ${_intervalleSecondes}s.");
      return;
    }

    ajouterLog("Scan de la table transactions...");

    try {
      final commande = await _supabaseService.recupererProchaineCommande();

      _erreursConsecutives = 0;
      _intervalleSecondes = 5;

      if (commande == null) {
        ajouterLog("Rien à signaler. En attente de paiement client...");
        return;
      }

      ajouterLog(
          "🔥 COMMANDE DÉTECTÉE ! Client: ${commande.destPhone} | ${commande.typeService} | ${commande.montant} F");

      // Pour l'instant, un seul réseau est géré : MTN. Quand vous ajouterez
      // Orange/Moov, il faudra une vraie colonne réseau dans la table —
      // "service" décrit le type de prestation, pas l'opérateur.
      final operateur = obtenirOperateur('MTN');
      if (operateur == null) {
        ajouterLog("❌ Configuration MTN manquante.");
        await _supabaseService.marquerStatut(commande.id, 'Échec');
        return;
      }

      await _executerTransfert(commande, operateur);
    } on SocketException catch (_) {
      _gererErreurReseau();
    } catch (e) {
      ajouterLog("❌ Erreur inattendue : $e");
    }
  }

  void _gererErreurReseau() {
    _erreursConsecutives++;
    _intervalleSecondes = (5 * (1 << _erreursConsecutives)).clamp(5, 60);
    ajouterLog(
        "⚠️ Problème réseau temporaire (tentative $_erreursConsecutives). Nouvel essai dans ${_intervalleSecondes}s.");
  }

  Future<void> _executerTransfert(
      TransactionMakbine commande, OperateurConfig operateur) async {
    await _supabaseService.marquerStatut(commande.id, 'En cours');

    // On ne pilote plus le composeur nous-mêmes : on envoie une notification
    // structurée que MacroDroid lit et utilise pour lancer le transfert USSD.
    const reseauActuel = 'MTN'; // seul réseau géré pour l'instant
    ajouterLog(
        "🤖 Commande transmise à MacroDroid : ${commande.destPhone} | $reseauActuel | ${commande.montant} F.");
    await NotificationService.envoyerCommandePourMacroDroid(
      id: commande.id,
      numero: commande.destPhone,
      operateur: reseauActuel,
      montant: commande.montant,
    );
    setState(() => _idEnAttenteConfirmation = commande.id);
  }

  Future<void> _confirmerTransfertEffectue() async {
    final id = _idEnAttenteConfirmation;
    if (id == null) return;
    await _supabaseService.marquerStatut(id, 'Succès');
    ajouterLog("✅ Transfert confirmé manuellement pour la commande $id.");
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
    _timer?.cancel();
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
                      "⚠️ Entrez le code secret sur l'écran USSD, puis validez ci-dessous.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _confirmerTransfertEffectue,
                      icon: const Icon(Icons.check, color: Colors.white),
                      label: const Text("TRANSFERT EFFECTUÉ",
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
