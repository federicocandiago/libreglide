package org.libreglide.launcher

import android.appwidget.AppWidgetHost
import android.appwidget.AppWidgetManager
import android.content.Context
import android.os.Build
import android.os.Bundle
import android.util.SizeF
import android.view.View
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

/**
 * Crea le viste dei widget Android da incorporare nelle card dello Space.
 * Parametri da Flutter: `id` del widget, `width` e `height` in dp.
 */
class AppWidgetViewFactory(private val host: AppWidgetHost) :
    PlatformViewFactory(StandardMessageCodec.INSTANCE) {

    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        val params = args as? Map<*, *> ?: emptyMap<String, Any>()
        val id = (params["id"] as? Number)?.toInt() ?: -1
        val manager = AppWidgetManager.getInstance(context)
        val info = manager.getAppWidgetInfo(id)
        val view: View = if (info == null) {
            View(context)
        } else {
            host.createView(context, id, info).also { hostView ->
                val w = (params["width"] as? Number)?.toFloat()
                val h = (params["height"] as? Number)?.toFloat()
                if (w != null && h != null && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    // Widget responsivi: si adattano alla dimensione della card.
                    hostView.updateAppWidgetSize(Bundle(), listOf(SizeF(w, h)))
                }
            }
        }
        return object : PlatformView {
            override fun getView(): View = view
            override fun dispose() {}
        }
    }
}
