package org.libreglide.launcher

import android.accessibilityservice.AccessibilityService
import android.view.accessibility.AccessibilityEvent
import android.view.inputmethod.InputMethodManager

/**
 * Servizio di accessibilità di Digital detox.
 *
 * Riceve SOLO l'evento "è cambiata la finestra in primo piano"
 * (typeWindowStateChanged, vedi res/xml/detox_service.xml) e ne legge il
 * nome del pacchetto. Non può leggere il contenuto dello schermo
 * (canRetrieveWindowContent=false), non fa polling e non tiene nulla in
 * memoria oltre al pacchetto sbloccato: si sveglia solo quando si apre o si
 * cambia app.
 */
class DetoxService : AccessibilityService() {

    /** Finestre che passano sopra un'app senza "lasciarla". */
    private var transient: Set<String> = emptySet()

    override fun onServiceConnected() {
        super.onServiceConnected()
        val keyboards = try {
            getSystemService(InputMethodManager::class.java).enabledInputMethodList.map { it.packageName }
        } catch (e: Exception) {
            emptyList()
        }
        transient = setOf(
            "com.android.systemui",
            "android",
            "com.android.intentresolver",
            "com.google.android.permissioncontroller",
            "com.android.permissioncontroller",
        ) + keyboards
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event?.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return
        val pkg = event.packageName?.toString() ?: return
        if (pkg in transient) return
        if (pkg == packageName && event.className?.toString() == DetoxLockActivity::class.java.name) return
        // L'utente ha lasciato l'app sbloccata: alla prossima apertura si richiude.
        if (pkg != Detox.unlockedPackage) Detox.unlockedPackage = null
        if (pkg == packageName) return
        if (Detox.unlockedPackage == pkg || !Detox.isLockedNow(this, pkg)) return
        Detox.showLock(this, pkg)
    }

    override fun onInterrupt() {}
}
