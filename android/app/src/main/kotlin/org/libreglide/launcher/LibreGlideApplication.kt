package org.libreglide.launcher

import android.app.Application
import android.appwidget.AppWidgetHost
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor

/**
 * Crea l'engine Flutter all'avvio del processo e lo tiene in cache.
 *
 * Un launcher deve ricomparire all'istante: se l'activity viene ricreata
 * (rotazione, cambio tema, memoria) riusa lo stesso engine già caldo invece
 * di farne partire uno nuovo.
 */
class LibreGlideApplication : Application() {

    override fun onCreate() {
        super.onCreate()
        widgetHost = AppWidgetHost(this, WIDGET_HOST_ID)
        val engine = FlutterEngine(this)
        // Vista nativa per i widget Android nelle card dello Space.
        engine.platformViewsController.registry
            .registerViewFactory(APP_WIDGET_VIEW, AppWidgetViewFactory(widgetHost))
        engine.dartExecutor.executeDartEntrypoint(DartExecutor.DartEntrypoint.createDefault())
        FlutterEngineCache.getInstance().put(ENGINE_ID, engine)
    }

    /** Host dei widget Android, unico per tutta l'app. */
    lateinit var widgetHost: AppWidgetHost
        private set

    companion object {
        const val ENGINE_ID = "libreglide_main"
        const val WIDGET_HOST_ID = 1024
        const val APP_WIDGET_VIEW = "libreglide/appwidget"
    }
}
