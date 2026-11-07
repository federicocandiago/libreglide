package org.libreglide.launcher

import android.accessibilityservice.AccessibilityService
import android.view.accessibility.AccessibilityEvent
import android.view.inputmethod.InputMethodManager

/**
 * Digital detox accessibility service.
 *
 * Receives ONLY the "foreground window changed" event
 * (typeWindowStateChanged, see res/xml/detox_service.xml) and reads its
 * package name. It cannot read the screen content
 * (canRetrieveWindowContent=false), does no polling and keeps nothing in
 * memory besides the unlocked package: it wakes up only when an app is
 * opened or switched.
 */
class DetoxService : AccessibilityService() {

    /** Windows that appear over an app without "leaving" it. */
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
        // The user left the unlocked app: it locks again on the next opening.
        if (pkg != Detox.unlockedPackage) Detox.unlockedPackage = null
        if (pkg == packageName) return
        if (Detox.unlockedPackage == pkg || !Detox.isLockedNow(this, pkg)) return
        Detox.showLock(this, pkg)
    }

    override fun onInterrupt() {}
}
