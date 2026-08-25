import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. CONNEXION SÉCURISÉE À VOTRE BASE DE DONNÉES SUPABASE AVEC VOS CLÉS MAKBINE
  await Supabase.initialize(
    url: 'https://vxaglbaqfpxitbdimeqj.supabase.co', 
    anonKey: 'sb_publishable_otC4yztme4tqkL9BA8FM5Q_APYQrtGg', 
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MaKbine Robot',
      home: const RobotTransfertScreen(),
      theme: ThemeData(primarySwatch: Colors.amber), // Identité visuelle MTN
      debugShowCheckedModeBanner: false,
    );
  }
}

class RobotTransfertScreen extends StatefulWidget {
  const RobotTransfertScreen({super.key});

  @override
  State<RobotTransfertScreen> createState() => _RobotTransfertScreenState();
}

class _RobotTransfertScreenState extends State<RobotTransfertScreen> {
  final supabase = Supabase.instance.client;
  bool isRunning = false;
  Timer? timer;
  String logs = "Robot en attente de démarrage...\n";

  // 2. BOUTON DÉMARRER : CHRONOMÈTRE TOUTES LES 5 SECONDES
  void demarrerRobot() {
    setState(() {
      isRunning = true;
      logs += "[${DateTime.now().toString().substring(11, 19)}] Robot activé. Écoute de makbine.ci...\n";
    });

    timer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      ajouterLog("Scan de la table transactions...");
      await verifierNouvellesCommandes();
    });
  }

  void arreterRobot() {
    timer?.cancel();
    setState(() {
      isRunning = false;
      logs += "[${DateTime.now().toString().substring(11, 19)}] Robot mis en pause.\n";
    });
  }

  // 3. REQUÊTE SUPABASE : TROUVER LES TRANSACTIONS "En attente"
  Future<void> verifierNouvellesCommandes() async {
    try {
      final response = await supabase
          .from('transactions')
          .select()
          .eq('status', 'En attente')
          .order('created_at', ascending: false)
          .limit(1);

      if (response.isNotEmpty) {
        final commande = response.first;
        final String id = commande['id'].toString();
        final String numero = commande['dest_phone'].toString();
        final String montant = commande['montant_forfait'].toString();

        ajouterLog("🔥 COMMANDE DÉTECTÉE ! client: $numero | prix: $montant F");
        
        // Déclencher le protocole USSD sur la carte SIM
        await executerCodeUssdMtn(numero, montant, id);
      } else {
        ajouterLog("Rien à signaler. En attente de paiement client...");
      }
    } catch (e) {
      ajouterLog("❌ Problème réseau ou clé Supabase invalide : $e");
    }
  }

  // 4. OUVERTURE DE L'APPLICATION TÉLÉPHONE (*133#)
  Future<void> executerCodeUssdMtn(String numero, String montant, String transactionId) async {
    final String ussdCode = "*133#"; 
    final Uri url = Uri.parse("tel:${Uri.encodeComponent(ussdCode)}");

    if (await canLaunchUrl(url)) {
      ajouterLog("Appel réseau du menu MTN MoMo (*133#)...");
      await launchUrl(url);

      // On passe le statut à "En cours" pour ne pas traiter la commande deux fois
      await marquerCommandeEnCours(transactionId);
    } else {
      ajouterLog("⚠️ Échec : Impossible d'accéder au transmetteur d'appel de votre smartphone.");
    }
  }

  Future<void> marquerCommandeEnCours(String id) async {
    try {
      await supabase
          .from('transactions')
          .update({'status': 'En cours'}).eq('id', id);
      ajouterLog("Statut mis à jour sur Supabase ➔ [En cours]");
    } catch (e) {
      ajouterLog("Erreur de mise à jour du statut : $e");
    }
  }

  void ajouterLog(String message) {
    if (!mounted) return;
    setState(() {
      String time = DateTime.now().toString().substring(11, 19);
      logs += "[$time] $message\n";
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text("MaKbine - Serveur USSD", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: isRunning ? null : demarrerRobot,
                    icon: const Icon(Icons.play_arrow, color: Colors.white),
                    label: const Text("DÉMARRER", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
                  ),
                  ElevatedButton.icon(
                    onPressed: isRunning ? arreterRobot : null,
                    icon: const Icon(Icons.stop, color: Colors.white),
                    label: const Text("ARRÊTER", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Icon(Icons.terminal, color: Colors.grey),
                const SizedBox(width: 8),
                Text("ÉCRAN DE CONTRÔLE EN TEMPS RÉEL :", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700])),
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
                  child: Text(
                    logs, 
                    style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace', fontSize: 13, height: 1.4),
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
