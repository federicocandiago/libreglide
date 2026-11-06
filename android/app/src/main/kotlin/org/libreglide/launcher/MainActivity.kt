package org.libreglide.launcher

import android.content.Intent
import android.os.Build
import android.os.Bundle
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

    /** Usa l'engine creato da [LibreGlideApplication]. */
    override fun getCachedEngineId(): String = LibreGlideApplication.ENGINE_ID

    /** L'engine sopravvive all'activity. */
    override fun shouldDestroyEngineWithHost(): Boolean = false

    /** Trasparente, così si vede lo sfondo di sistema. */
    override fun getBackgroundMode(): BackgroundMode = BackgroundMode.transparent

    /**
     * Con lo sfondo trasparente FlutterActivity sceglierebbe da sola
     * [RenderMode.texture] (TextureView), molto più lento: ogni frame passa
     * per una copia in più sulla GPU. Usiamo invece un SurfaceView
     * trasparente. Per i confronti si può forzare la TextureView avviando
     * l'activity con l'extra `render=texture`.
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
     * Di norma la superficie di Flutter viene distrutta quando il launcher
     * va in background e ricreata al ritorno: tornando alla Home da un'app
     * si vedrebbe un frame vuoto (sfondo nero, poi tutto di colpo). Da
     * Android 14 la si può tenere finché la vista è agganciata: al ritorno
     * l'ultimo frame è già pronto.
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

    /** Tasto o gesto Home mentre il launcher è già in primo piano. */
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        if (intent.action == Intent.ACTION_MAIN && intent.hasCategory(Intent.CATEGORY_HOME)) {
            bridge?.notifyHomePressed()
        }
    }

    override fun onStart() {
        super.onStart()
        (application as LibreGlideApplication).widgetHost.startListening()
    }

    override fun onStop() {
        super.onStop()
        // Su alcuni dispositivi stopListening lancia se l'host non ascolta.
        try {
            (application as LibreGlideApplication).widgetHost.stopListening()
        } catch (e: Exception) {
        }
    }

    @Deprecated("Usato per i flussi di sistema dei widget (collegamento e configurazione).")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        bridge?.onActivityResult(requestCode, resultCode)
    }

    override fun onResume() {
        super.onResume()
        bridge?.notifyResumed()
        // Comando di sviluppo: `adb shell am start -n org.libreglide.launcher/.MainActivity
        // --es open settings` apre una schermata senza toccare il telefono.
        intent?.getStringExtra(EXTRA_OPEN)?.let { target ->
            intent.removeExtra(EXTRA_OPEN)
            bridge?.notifyOpen(target)
        }
    }

    companion object {
        private const val EXTRA_OPEN = "open"
    }
}
