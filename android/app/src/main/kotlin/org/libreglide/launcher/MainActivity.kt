package org.libreglide.launcher

import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.SurfaceView
import android.view.View
import android.view.ViewGroup
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.FlutterActivityLaunchConfigs.BackgroundMode
import io.flutter.embedding.android.RenderMode
import io.flutter.embedding.android.TransparencyMode
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {

    private var bridge: LauncherBridge? = null

    /** Uses the engine created by [LibreGlideApplication]. */
    override fun getCachedEngineId(): String = LibreGlideApplication.ENGINE_ID

    /** The engine outlives the activity. */
    override fun shouldDestroyEngineWithHost(): Boolean = false

    /** Transparent, so the system wallpaper shows through. */
    override fun getBackgroundMode(): BackgroundMode = BackgroundMode.transparent

    /**
     * With a transparent background FlutterActivity would pick
     * [RenderMode.texture] (TextureView) on its own, which is much slower:
     * every frame goes through an extra GPU copy. We use a transparent
     * SurfaceView instead. For comparisons, TextureView can be forced by
     * starting the activity with the extra `render=texture`.
     */
    override fun getRenderMode(): RenderMode =
        if (intent?.getStringExtra("render") == "texture") RenderMode.texture else RenderMode.surface

    override fun getTransparencyMode(): TransparencyMode = TransparencyMode.transparent

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.setDecorFitsSystemWindows(false)
    }

    override fun onPostCreate(savedInstanceState: Bundle?) {
        super.onPostCreate(savedInstanceState)
        keepSurfaceAlive(window.decorView)
    }

    /**
     * Normally the Flutter surface is destroyed when the launcher goes to the
     * background and recreated on return: going back Home from an app would
     * show an empty frame (black background, then everything at once). Since
     * Android 14 it can be kept while the view is attached, so the last frame
     * is already there on return.
     */
    private fun keepSurfaceAlive(view: View) {
        if (Build.VERSION.SDK_INT < 34) return
        if (view is SurfaceView) {
            view.setSurfaceLifecycle(SurfaceView.SURFACE_LIFECYCLE_FOLLOWS_ATTACHMENT)
            return
        }
        if (view is ViewGroup) for (i in 0 until view.childCount) keepSurfaceAlive(view.getChildAt(i))
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        bridge?.dispose()
        bridge = LauncherBridge(this, flutterEngine.dartExecutor.binaryMessenger)
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        bridge?.dispose()
        bridge = null
        super.cleanUpFlutterEngine(flutterEngine)
    }

    /** Home button or gesture while the launcher is already in the foreground. */
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        if (intent.action == Intent.ACTION_MAIN && intent.hasCategory(Intent.CATEGORY_HOME)) {
            bridge?.notifyHomePressed()
        }
    }

    /**
     * Set when another MainActivity took the shared engine away from this one.
     * It happens when a second instance is started outside the Home task (for
     * example "Open" from another launcher or the store while libreGLIDE is
     * the Home): when that one closes, this one would be left without the
     * engine, showing only the wallpaper.
     */
    private var evicted = false

    override fun detachFromFlutterEngine() {
        evicted = true
        super.detachFromFlutterEngine()
    }

    override fun onStart() {
        super.onStart()
        if (evicted) {
            // Becoming visible again without the engine: recreate, so the new
            // instance takes the engine back (state lives in the engine).
            evicted = false
            recreate()
            return
        }
        (application as LibreGlideApplication).widgetHost.startListening()
    }

    override fun onStop() {
        super.onStop()
        // On some devices stopListening throws if the host isn't listening.
        try {
            (application as LibreGlideApplication).widgetHost.stopListening()
        } catch (e: Exception) {
        }
    }

    @Deprecated("Used for the system widget flows (binding and configuration).")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        bridge?.onActivityResult(requestCode, resultCode)
    }

    /** Whether this activity has shown the Flutter UI at least once. */
    private var shownOnce = false
    private val main = Handler(Looper.getMainLooper())

    /**
     * Watchdog: back in the foreground, the UI must be on screen. If it was
     * shown before and now nothing is drawn (the surface was taken or
     * stopped by another instance of this activity), recreate: the state
     * lives in the engine, so the user just sees the launcher again instead
     * of a bare wallpaper.
     */
    private val checkUi = Runnable {
        val renderer = flutterEngine?.renderer ?: return@Runnable
        if (renderer.isDisplayingFlutterUi) {
            shownOnce = true
        } else if (shownOnce && !isFinishing && !isDestroyed) {
            shownOnce = false
            recreate()
        }
    }

    override fun onPause() {
        main.removeCallbacks(checkUi)
        super.onPause()
    }

    override fun onResume() {
        super.onResume()
        if (flutterEngine?.renderer?.isDisplayingFlutterUi == true) shownOnce = true
        main.removeCallbacks(checkUi)
        main.postDelayed(checkUi, 1200)
        bridge?.notifyResumed()
        // Development command: `adb shell am start -n org.libreglide.launcher/.MainActivity
        // --es open settings` opens a screen without touching the phone.
        intent?.getStringExtra(EXTRA_OPEN)?.let { target ->
            intent.removeExtra(EXTRA_OPEN)
            bridge?.notifyOpen(target)
        }
    }

    companion object {
        private const val EXTRA_OPEN = "open"
    }
}
