typedef ConstructeurUssd = String Function(String numero, String montant);

class OperateurConfig {
  final String nom;
  final ConstructeurUssd construireCodeUssd;

  const OperateurConfig({
    required this.nom,
    required this.construireCodeUssd,
  });
}

// ⚠️ IMPORTANT : la syntaxe exacte du code USSD "transfert rapide sans menu"
// change selon l'opérateur et le pays, et n'est pas toujours documentée
// publiquement. Le gabarit MTN ci-dessous doit être vérifié/testé par vous
// avec de petits montants avant utilisation en production.
//
// Pour ajouter un nouveau réseau plus tard, il suffit d'ajouter une entrée
// ici : aucune autre partie du code n'a besoin d'être modifiée.
final Map<String, OperateurConfig> operateursDisponibles = {
  'MTN': OperateurConfig(
    nom: 'MTN',
    construireCodeUssd: (numero, montant) => '*133*1*$numero*$montant#',
  ),

  // Exemple pour quand vous ajouterez Orange :
  // 'ORANGE': OperateurConfig(
  //   nom: 'Orange',
  //   construireCodeUssd: (numero, montant) => '*144*...#',
  // ),

  // Exemple pour Moov :
  // 'MOOV': OperateurConfig(
  //   nom: 'Moov',
  //   construireCodeUssd: (numero, montant) => '*155*...#',
  // ),
};

OperateurConfig? obtenirOperateur(String reseau) =>
    operateursDisponibles[reseau.toUpperCase()];
