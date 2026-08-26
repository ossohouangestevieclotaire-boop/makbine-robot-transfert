package com.example.makbine_transfert

import android.accessibilityservice.AccessibilityService
import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import androidx.core.app.NotificationCompat

/**
 * Automatise la saisie des écrans USSD (menu, sous-menu, numéro, montant).
 *
 * IMPORTANT : ce service s'arrête volontairement AVANT la saisie du code
 * secret. Le code secret n'est jamais stocké ni saisi automatiquement —
 * c'est une décision de conception intentionnelle, pas un oubli. Ne modifiez
 * pas ce fichier pour y ajouter le code secret.
 */
class UssdAutomationService : AccessibilityService() {

    companion object {
        private var etapesRestantes: MutableList<String> = mutableListOf()
        private var enCours = false
        private const val CHANNEL_ID = "makbine_ussd"
        private const val DELAI_LECTURE_ECRAN_MS = 900L

        /** Démarre l'automatisation avec la séquence d'étapes à saisir, dans l'ordre. */
        fun demarrer(sequence: List<String>) {
            etapesRestantes = sequence.toMutableList()
            enCours = true
        }

        fun arreter() {
            etapesRestantes.clear()
            enCours = false
        }
    }

    private val handler = Handler(Looper.getMainLooper())
    private var traitementEnCours = false

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (!enCours || event == null || traitementEnCours) return

        val paquet = event.packageName?.toString() ?: return
        val estEcranTelephone = paquet == "com.android.phone" || paquet.contains("dialer", true)
        if (!estEcranTelephone) return

        if (event.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED ||
            event.eventType == AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED
        ) {
            traitementEnCours = true
            handler.postDelayed({
                traiterEcranActuel()
                traitementEnCours = false
            }, DELAI_LECTURE_ECRAN_MS)
        }
    }

    private fun traiterEcranActuel() {
        val racine = rootInActiveWindow ?: return

        if (etapesRestantes.isEmpty()) {
            notifierSaisieManuelle()
            arreter()
            return
        }

        val valeur = etapesRestantes.removeAt(0)
        val champTexte = trouverChampTexte(racine)

        if (champTexte != null) {
            val args = Bundle()
            args.putCharSequence(
                AccessibilityNodeInfo.ACTION_ARGUMENT_SET_TEXT_CHARSEQUENCE, valeur
            )
            champTexte.performAction(AccessibilityNodeInfo.ACTION_SET_TEXT, args)
        }

        // Selon les téléphones, le bouton peut s'appeler "Envoyer", "OK" ou "Send".
        val boutonEnvoyer = trouverBoutonParTexte(racine, listOf("envoyer", "send", "ok", "valider"))
        boutonEnvoyer?.performAction(AccessibilityNodeInfo.ACTION_CLICK)
    }

    private fun trouverChampTexte(noeud: AccessibilityNodeInfo): AccessibilityNodeInfo? {
        if (noeud.className == "android.widget.EditText") return noeud
        for (i in 0 until noeud.childCount) {
            val enfant = noeud.getChild(i) ?: continue
            val trouve = trouverChampTexte(enfant)
            if (trouve != null) return trouve
        }
        return null
    }

    private fun trouverBoutonParTexte(
        noeud: AccessibilityNodeInfo,
        motsCles: List<String>
    ): AccessibilityNodeInfo? {
        val texte = noeud.text?.toString()?.lowercase() ?: ""
        val estBouton = noeud.className?.toString()?.contains("Button") == true
        if (estBouton && motsCles.any { texte.contains(it) }) return noeud

        for (i in 0 until noeud.childCount) {
            val enfant = noeud.getChild(i) ?: continue
            val trouve = trouverBoutonParTexte(enfant, motsCles)
            if (trouve != null) return trouve
        }
        return null
    }

    private fun notifierSaisieManuelle() {
        val manager = getSystemService(NotificationManager::class.java) ?: return

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Makbine - Code secret requis",
                NotificationManager.IMPORTANCE_HIGH
            )
            manager.createNotificationChannel(channel)
        }

        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("⚠️ Code secret requis")
            .setContentText("Le menu est prêt. Entrez le code secret sur l'écran USSD pour valider le transfert.")
            .setSmallIcon(android.R.drawable.ic_dialog_alert)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .build()

        manager.notify(1, notification)
    }

    override fun onInterrupt() {
        arreter()
    }
}
