import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/transaction_makbine.dart';
import '../services/operateur_service.dart';
import '../services/reseau_service.dart';
import '../services/supabase_service.dart';

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

      // Un scan a réussi : on réinitialise le compteur d'erreurs et
      // l'intervalle revient à la normale.
      _erreursConsecutives = 0;
      _intervalleSecondes = 5;

      if (commande == null) {
        ajouterLog("Rien à signaler. En attente de paiement client...");
        return;
      }

      ajouterLog(
          "🔥 COMMANDE DÉTECTÉE ! Client: ${commande.destPhone} | ${commande.reseau} | ${commande.montantForfait} F");

      final operateur = obtenirOperateur(commande.reseau);
      if (operateur == null) {
        ajouterLog("❌ Réseau '${commande.reseau}' pas encore pris en charge.");
        await _supabaseService.marquerStatut(commande.id, 'Échec');
        return;
      }

      await _executerTransfert(commande, operateur);
    } on SocketException catch (_) {
      _gererErreurReseau();
    } catch (e) {
      // Erreur réelle (clé invalide, table absente, etc.) : on la signale
      // clairement mais sans casser la boucle du robot.
      ajouterLog("❌ Erreur inattendue : $e");
    }
  }

  void _gererErreurReseau() {
    _erreursConsecutives++;
    // Backoff progressif : 5s, 10s, 20s, 40s, plafonné à 60s. Ça évite de
    // spammer les logs et la batterie pendant une vraie coupure réseau,
    // tout en revenant vite à la normale dès que la connexion revient.
    _intervalleSecondes = (5 * (1 << _erreursConsecutives)).clamp(5, 60);
    ajouterLog(
        "⚠️ Problème réseau temporaire (tentative $_erreursConsecutives). Nouvel essai dans ${_intervalleSecondes}s.");
  }

  Future<void> _executerTransfert(
      TransactionMakbine commande, OperateurConfig operateur) async {
    final codeUssd =
        operateur.construireCodeUssd(commande.destPhone, commande.montantForfait);
    final url = Uri.parse('tel:${Uri.encodeComponent(codeUssd)}');

    if (await canLaunchUrl(url)) {
      // On marque "En cours" AVANT de composer, pour ne jamais traiter deux
      // fois la même commande si un scan se déclenche entre-temps.
      await _supabaseService.marquerStatut(commande.id, 'En cours');
      ajouterLog("Appel réseau ${operateur.nom} ($codeUssd)...");
      await launchUrl(url);
    } else {
      ajouterLog("⚠️ Échec : impossible d'accéder au clavier téléphonique.");
      await _supabaseService.marquerStatut(commande.id, 'Échec');
    }
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
