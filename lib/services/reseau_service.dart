import 'package:connectivity_plus/connectivity_plus.dart';

class ReseauService {
  Future<bool> estConnecte() async {
    final resultats = await Connectivity().checkConnectivity();
    return !resultats.contains(ConnectivityResult.none);
  }
}
