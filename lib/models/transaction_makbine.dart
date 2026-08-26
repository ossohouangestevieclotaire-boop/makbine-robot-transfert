class TransactionMakbine {
  final String id;
  final String destPhone;
  final String montantForfait;
  final String reseau; // 'MTN', 'ORANGE', 'MOOV', 'WAVE'...
  final String status;

  TransactionMakbine({
    required this.id,
    required this.destPhone,
    required this.montantForfait,
    required this.reseau,
    required this.status,
  });

  factory TransactionMakbine.fromMap(Map<String, dynamic> map) {
    return TransactionMakbine(
      id: map['id'].toString(),
      destPhone: map['dest_phone'].toString(),
      montantForfait: map['montant_forfait'].toString(),
      reseau: (map['reseau'] ?? 'MTN').toString().toUpperCase(),
      status: map['status'].toString(),
    );
  }
}
