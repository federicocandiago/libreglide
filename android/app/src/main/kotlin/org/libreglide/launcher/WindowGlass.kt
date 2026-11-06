package org.libreglide.launcher

import android.app.Activity
import android.view.WindowManager
import java.util.function.Consumer

/**
 * Vetro smerigliato (facoltativo): sfocatura di sistema dello sfondo dietro
 * la finestra del launcher. La calcola il compositore sulla GPU, non
 * Flutter; Android la spegne da solo in risparmio energetico (e allora
 * [onAvailable] avvisa Flutter, che rende le pagine più coprenti).
 */
class WindowGlass(private val activity: Activity, private val onAvailable: (Boolean) -> Unit) {

    private val windowManager = activity.getSystemService(WindowManager::class.java)
    private var enabled = false
    private var radius = -1

    private val listener = Consumer<Boolean> { onAvailable(it) }

    val available: Boolean get() = windowManager.isCrossWindowBlurEnabled

    /** Attiva o spegne il vetro; la finestra diventa traslucida solo se serve. */
    fun setEnabled(on: Boolean): Boolean {
        if (on == enabled) return available
        enabled = on
        if (on) {
            activity.setTranslucent(true)
            windowManager.addCrossWindowBlurEnabledListener(activity.mainExecutor, listener)
        } else {
            blurTo(0)
            windowManager.removeCrossWindowBlurEnabledListener(listener)
            activity.setTranslucent(false)
        }
        return available
    }

    /** Sfocatura dello sfondo di [target] pixel (0 = nitido). */
    fun blurTo(target: Int) {
        val goal = if (enabled) target else 0
        if (goal == radius) return
        radius = goal
        // Sfoca tutto ciò che sta dietro la finestra (lo sfondo del telefono).
        val window = activity.window
        // Android disegna la sfocatura insieme al velo scuro della finestra:
        // con il velo a zero il livello è "invisibile" e la sfocatura salta,
        // quindi serve un velo appena percettibile.
        val flags = WindowManager.LayoutParams.FLAG_BLUR_BEHIND or WindowManager.LayoutParams.FLAG_DIM_BEHIND
        if (goal > 0) window.addFlags(flags) else window.clearFlags(flags)
        window.attributes = window.attributes.apply {
            blurBehindRadius = goal
            dimAmount = if (goal > 0) 0.02f else 0f
        }
    }

    fun dispose() {
        if (enabled) windowManager.removeCrossWindowBlurEnabledListener(listener)
    }
}
