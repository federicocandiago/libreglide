package org.libreglide.launcher

import android.app.Application
import android.appwidget.AppWidgetHost
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor

/**
 * Creates the Flutter engine at process start and keeps it cached.
 *
 * A launcher must reappear instantly: when the activity is recreated
 * (rotation, theme change, memory pressure) it reuses the same warm engine
 * instead of starting a new one.
 */
class LibreGlideApplication : Application() {

    override fun onCreate() {
        super.onCreate()
        widgetHost = AppWidgetHost(this, WIDGET_HOST_ID)
        val engine = FlutterEngine(this)
        // Native view for Android widgets in the Space's cards.
        engine.platformViewsController.registry
            .registerViewFactory(APP_WIDGET_VIEW, AppWidgetViewFactory(widgetHost))
        engine.dartExecutor.executeDartEntrypoint(DartExecutor.DartEntrypoint.createDefault())
        FlutterEngineCache.getInstance().put(ENGINE_ID, engine)
    }

    /** Android widget host, a single one for the whole app. */
    lateinit var widgetHost: AppWidgetHost
        private set

    companion object {
        const val ENGINE_ID = "libreglide_main"
        const val WIDGET_HOST_ID = 1024
        const val APP_WIDGET_VIEW = "libreglide/appwidget"
    }
}
