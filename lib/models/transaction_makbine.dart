class TransactionMakbine {
  final String id;
  final String destPhone;
  final String montant;
  final String typeService; // ex: "TRANSFERT D'UNITÉS" — décrit le service demandé, pas le réseau
  final String status;

  TransactionMakbine({
    required this.id,
    required this.destPhone,
    required this.montant,
    required this.typeService,
    required this.status,
  });

  factory TransactionMakbine.fromMap(Map<String, dynamic> map) {
    return TransactionMakbine(
      id: map['id'].toString(),
      destPhone: map['dest_phone'].toString(),
      montant: map['amount'].toString(),
      typeService: (map['service'] ?? '').toString(),
      status: map['status'].toString(),
    );
  }
}
