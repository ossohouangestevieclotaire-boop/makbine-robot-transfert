class TransactionMakbine {
  final String id;
  final String destPhone;
  final String montant;
  final String reseau; // vient de la colonne "service" (MTN, ORANGE...)
  final String status;

  TransactionMakbine({
    required this.id,
    required this.destPhone,
    required this.montant,
    required this.reseau,
    required this.status,
  });

  factory TransactionMakbine.fromMap(Map<String, dynamic> map) {
    return TransactionMakbine(
      id: map['id'].toString(),
      destPhone: map['dest_phone'].toString(),
      montant: map['amount'].toString(),
      reseau: (map['service'] ?? 'MTN').toString().toUpperCase(),
      status: map['status'].toString(),
    );
  }
}
