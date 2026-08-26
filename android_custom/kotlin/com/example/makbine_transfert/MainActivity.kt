package com.example.makbine_transfert

import android.content.Intent
import android.net.Uri
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "makbine/ussd_automation"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "demarrerTransfertMtn" -> {
                    val numero = call.argument<String>("numero") ?: ""
                    val montant = call.argument<String>("montant") ?: ""

                    // Séquence des saisies automatiques dans l'ordre des écrans.
                    // Le code secret n'apparaît JAMAIS ici : il reste manuel.
                    UssdAutomationService.demarrer(listOf("4", "1", "2", numero, montant))

                    // ACTION_DIAL ouvre le composeur avec le code pré-rempli.
                    // Une pression sur "Appeler" reste nécessaire une seule fois
                    // pour lancer la session USSD (évite la permission CALL_PHONE).
                    val uri = Uri.parse("tel:" + Uri.encode("*133#"))
                    val intent = Intent(Intent.ACTION_DIAL, uri)
                    startActivity(intent)
                    result.success(true)
                }
                "ouvrirParametresAccessibilite" -> {
                    startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }
}
