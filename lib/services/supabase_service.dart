import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/transaction_makbine.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<TransactionMakbine?> recupererProchaineCommande() async {
    final response = await _client
        .from('transactions')
        .select()
        .eq('status', 'En attente')
        .order('created_at', ascending: false)
        .limit(1);

    if (response.isEmpty) return null;
    return TransactionMakbine.fromMap(response.first);
  }

  Future<void> marquerStatut(String id, String statut) async {
    await _client.from('transactions').update({'status': statut}).eq('id', id);
  }
}
