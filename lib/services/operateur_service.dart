typedef ConstructeurUssd = String Function(String numero, String montant);

class OperateurConfig {
  final String nom;
  final ConstructeurUssd construireCodeUssd;

  const OperateurConfig({
    required this.nom,
    required this.construireCodeUssd,
  });
}

// ⚠️ La syntaxe USSD exacte doit être vérifiée/testée par vous avec de
// petits montants avant utilisation en production.
//
// Pour ajouter un nouveau réseau plus tard, ajoutez simplement une entrée
// ici : aucune autre partie du code n'a besoin d'être modifiée.
final Map<String, OperateurConfig> operateursDisponibles = {
  'MTN': OperateurConfig(
    nom: 'MTN',
    construireCodeUssd: (numero, montant) => '*133*1*$numero*$montant#',
  ),

  // 'ORANGE': OperateurConfig(
  //   nom: 'Orange',
  //   construireCodeUssd: (numero, montant) => '*144*...#',
  // ),
  // 'MOOV': OperateurConfig(
  //   nom: 'Moov',
  //   construireCodeUssd: (numero, montant) => '*155*...#',
  // ),
};

OperateurConfig? obtenirOperateur(String reseau) =>
    operateursDisponibles[reseau.toUpperCase()];
