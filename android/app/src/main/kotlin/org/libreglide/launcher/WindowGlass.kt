package org.libreglide.launcher

import android.app.Activity
import android.view.WindowManager
import java.util.function.Consumer

/**
 * Frosted glass (optional): system blur of the wallpaper behind the launcher
 * window. It is computed by the compositor on the GPU, not by Flutter;
 * Android turns it off by itself in battery saver (and then [onAvailable]
 * tells Flutter, which makes the pages more opaque).
 */
class WindowGlass(private val activity: Activity, private val onAvailable: (Boolean) -> Unit) {

    private val windowManager = activity.getSystemService(WindowManager::class.java)
    private var enabled = false
    private var radius = -1

    private val listener = Consumer<Boolean> { onAvailable(it) }

    val available: Boolean get() = windowManager.isCrossWindowBlurEnabled

    /** Turns the glass on or off; the window becomes translucent only when needed. */
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

    /** Blurs the wallpaper by [target] pixels (0 = sharp). */
    fun blurTo(target: Int) {
        val goal = if (enabled) target else 0
        if (goal == radius) return
        radius = goal
        // Blurs everything behind the window (the phone's wallpaper).
        val window = activity.window
        // Android draws the blur together with the window's dim layer: with
        // zero dim the layer is "invisible" and the blur is skipped, so a
        // barely noticeable dim is needed.
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
