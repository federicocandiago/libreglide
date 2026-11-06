package org.libreglide.launcher

import android.Manifest
import android.app.AppOpsManager
import android.app.UiModeManager
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProviderInfo
import android.bluetooth.BluetoothClass
import android.bluetooth.BluetoothManager
import android.content.res.Configuration
import android.location.Location
import android.location.LocationManager
import android.os.CancellationSignal
import android.app.Activity
import android.app.ActivityOptions
import android.app.AlarmManager
import android.app.role.RoleManager
import android.content.ComponentName
import android.content.ContentUris
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.LauncherActivityInfo
import android.content.pm.LauncherApps
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.PorterDuff
import android.graphics.PorterDuffColorFilter
import android.graphics.drawable.AdaptiveIconDrawable
import android.graphics.drawable.Drawable
import android.media.AudioDeviceInfo
import android.media.AudioManager
import android.net.ConnectivityManager
import android.net.ConnectivityManager.NetworkCallback.FLAG_INCLUDE_LOCATION_INFO
import android.net.Network
import android.net.wifi.WifiInfo
import android.net.wifi.WifiManager
import android.net.NetworkCapabilities
import android.net.Uri
import android.os.BatteryManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.Process
import android.os.UserHandle
import android.provider.AlarmClock
import android.provider.CalendarContract
import android.provider.ContactsContract
import android.provider.Settings
import android.telephony.TelephonyManager
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.util.TimeZone
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.Executors

/**
 * Ponte tra Flutter e il sistema per tutto ciò che riguarda le app:
 * elenco, icone, avvio, informazioni, disinstallazione, ruolo Home.
 *
 * Non prende decisioni: legge il sistema e restituisce dati normalizzati.
 * Canali: `libreglide/launcher` (metodi) e `libreglide/launcher/events`.
 */
class LauncherBridge(
    private val activity: Activity,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler, EventChannel.StreamHandler {

    private val context: Context = activity.applicationContext
    private val launcherApps = context.getSystemService(LauncherApps::class.java)
    private val user: UserHandle = Process.myUserHandle()
    private val main = Handler(Looper.getMainLooper())
    private val worker = Executors.newFixedThreadPool(2)

    private val methods = MethodChannel(messenger, METHOD_CHANNEL)
    private val events = EventChannel(messenger, EVENT_CHANNEL)
    private var sink: EventChannel.EventSink? = null

    /** Musica in riproduzione: avvisa Flutter quando cambia. */
    private val media = MediaWatcher(context) {
        main.post { sink?.success(mapOf("type" to "media_changed")) }
    }

    /** Ultimo elenco letto, per risolvere velocemente le icone. */
    private val infoById = ConcurrentHashMap<String, LauncherActivityInfo>()

    private val packageCallback = object : LauncherApps.Callback() {
        override fun onPackageRemoved(packageName: String, user: UserHandle) = changed(packageName)
        override fun onPackageAdded(packageName: String, user: UserHandle) = changed(packageName)
        override fun onPackageChanged(packageName: String, user: UserHandle) = changed(packageName)
        override fun onPackagesAvailable(names: Array<out String>, user: UserHandle, replacing: Boolean) =
            changed(null)
        override fun onPackagesUnavailable(names: Array<out String>, user: UserHandle, replacing: Boolean) =
            changed(null)
    }

    init {
        methods.setMethodCallHandler(this)
        events.setStreamHandler(this)
        launcherApps.registerCallback(packageCallback, main)
        media.startIfPossible()
    }

    fun dispose() {
        launcherApps.unregisterCallback(packageCallback)
        media.stop()
        unregisterWifiCallback()
        methods.setMethodCallHandler(null)
        events.setStreamHandler(null)
        glass.dispose()
        worker.shutdown()
    }

    private val glass = WindowGlass(activity) { methods.invokeMethod("onBlurAvailable", it) }

    fun notifyHomePressed() {
        methods.invokeMethod("onHomePressed", null)
    }

    fun notifyResumed() {
        // L'utente potrebbe aver appena concesso l'accesso ai media.
        media.startIfPossible()
        methods.invokeMethod("onResumed", null)
    }

    /** Apre una schermata (comando di sviluppo, vedi MainActivity). */
    fun notifyOpen(target: String) {
        methods.invokeMethod("onOpen", target)
    }

    private fun changed(packageName: String?) {
        sink?.success(mapOf("type" to "packages_changed", "package" to packageName))
    }

    // region EventChannel
    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        sink = events
    }

    override fun onCancel(arguments: Any?) {
        sink = null
    }
    // endregion

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getApps" -> background(result) { getApps() }
            "getIcons" -> {
                val ids = call.argument<List<String>>("ids") ?: emptyList()
                val size = call.argument<Int>("size") ?: 144
                background(result) { getIcons(ids, size) }
            }
            "launch" -> result.success(launch(call.argument<String>("id")!!, call.argument<List<Int>>("bounds")))
            // Vetro smerigliato
            "setGlass" -> result.success(glass.setEnabled(call.argument<Boolean>("enabled") == true))
            "setWindowBlur" -> {
                glass.blurTo(((call.argument<Number>("dp")?.toFloat() ?: 0f) * context.resources.displayMetrics.density).toInt())
                result.success(true)
            }
            // Digital detox
            "detoxSync" -> {
                @Suppress("UNCHECKED_CAST")
                Detox.sync(context, (call.arguments as? Map<String, Any?>) ?: emptyMap())
                result.success(true)
            }
            "detoxHasPin" -> result.success(Detox.hasPin(context))
            "detoxSetPin" -> background(result) { Detox.setPin(context, call.argument<String>("pin")!!); true }
            "detoxCheckPin" -> background(result) { Detox.checkPin(context, call.argument<String>("pin") ?: "") }
            "detoxServiceEnabled" -> result.success(Detox.serviceEnabled(context))
            // Comando di sviluppo: mostra la schermata di blocco (per Impostazioni).
            "detoxPreview" -> {
                Detox.showLock(context, "com.android.settings")
                result.success(true)
            }
            "openDetoxService" -> result.success(openDetoxService())
            "detoxSystemApps" -> background(result) {
                Detox.SENSITIVE_PACKAGES.mapNotNull { pkg ->
                    try {
                        val info = context.packageManager.getApplicationInfo(pkg, 0)
                        mapOf("package" to pkg, "label" to context.packageManager.getApplicationLabel(info).toString())
                    } catch (e: PackageManager.NameNotFoundException) {
                        null
                    }
                }
            }
            "openAppInfo" -> result.success(openAppInfo(call.argument<String>("id")!!))
            "uninstall" -> result.success(uninstall(call.argument<String>("package")!!))
            "isDefaultHome" -> result.success(isDefaultHome())
            "requestDefaultHome" -> result.success(requestDefaultHome())
            "openSystemSettings" -> result.success(startSafely(Intent(Settings.ACTION_SETTINGS)))
            "openUrl" -> result.success(
                startSafely(Intent(Intent.ACTION_VIEW, Uri.parse(call.argument<String>("url") ?: ""))),
            )
            "getContextSnapshot" -> result.success(contextSnapshot())
            "timeZoneOffset" -> result.success(
                TimeZone.getTimeZone(call.argument<String>("tz") ?: "UTC").getOffset(System.currentTimeMillis()),
            )
            "getMedia" -> {
                val size = call.argument<Int>("artSize") ?: 192
                result.success(mapOf("access" to media.hasAccess(), "media" to media.snapshot(size)))
            }
            "mediaCommand" -> result.success(media.command(call.argument<String>("command") ?: ""))
            "openMediaAccess" -> result.success(openMediaAccess())
            "getEvents" -> {
                val from = call.argument<Number>("from")!!.toLong()
                val to = call.argument<Number>("to")!!.toLong()
                background(result) { readEvents(from, to) }
            }
            "requestCalendar" -> result.success(requestCalendar())
            "hasUsageAccess" -> result.success(hasUsageAccess())
            "usageOpenings" -> {
                val since = call.argument<Number>("since")?.toLong() ?: 0L
                background(result) { usageOpenings(since) }
            }
            "openUsageAccess" -> result.success(
                startSafely(
                    Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS, Uri.parse("package:${context.packageName}")),
                ) || startSafely(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)),
            )
            "screenTimeToday" -> background(result) { screenTimeToday() }
            "widgetProviders" -> background(result) { widgetProviders() }
            "addWidget" -> addWidget(call.argument<String>("provider")!!, result)
            "removeWidget" -> {
                widgetHost.deleteAppWidgetId(call.argument<Number>("id")!!.toInt())
                result.success(true)
            }
            "getParking" -> result.success(parking())
            "clearParking" -> {
                context.getSharedPreferences(ParkingReceiver.PREFS, Context.MODE_PRIVATE).edit()
                    .remove(ParkingReceiver.KEY_LAT).remove(ParkingReceiver.KEY_LON)
                    .remove(ParkingReceiver.KEY_TS).apply()
                result.success(true)
            }
            "setParkingEnabled" -> {
                context.getSharedPreferences(ParkingReceiver.PREFS, Context.MODE_PRIVATE).edit()
                    .putBoolean(ParkingReceiver.KEY_ENABLED, call.argument<Boolean>("enabled") == true).apply()
                result.success(true)
            }
            "hasBackgroundLocation" -> result.success(
                context.checkSelfPermission(Manifest.permission.ACCESS_BACKGROUND_LOCATION) ==
                    PackageManager.PERMISSION_GRANTED,
            )
            "requestBackgroundLocation" -> result.success(
                requestOnce(Manifest.permission.ACCESS_BACKGROUND_LOCATION, "background_asked", REQUEST_BACKGROUND),
            )
            // Negata in modo definitivo: Android non mostra più la richiesta,
            // si può concedere solo dalle impostazioni dell'app.
            "backgroundLocationBlocked" -> result.success(
                context.checkSelfPermission(Manifest.permission.ACCESS_BACKGROUND_LOCATION) !=
                    PackageManager.PERMISSION_GRANTED &&
                    context.getSharedPreferences("libreglide_native", Context.MODE_PRIVATE)
                        .getBoolean("background_asked", false) &&
                    !activity.shouldShowRequestPermissionRationale(Manifest.permission.ACCESS_BACKGROUND_LOCATION),
            )
            "hasPreciseLocation" -> result.success(hasPreciseLocation())
            "requestPreciseLocation" -> result.success(requestPreciseLocation())
            "placeSample" -> placeSample(result, call.argument<Boolean>("withLocation") != false)
            "hasLocation" -> result.success(hasLocation())
            "requestLocation" -> result.success(requestLocation())
            "coarseLocation" -> coarseLocation(result)
            "hasBluetooth" -> result.success(hasBluetooth())
            "requestBluetooth" -> result.success(requestBluetooth())
            "hasContacts" -> result.success(hasContacts())
            "requestContacts" -> result.success(requestContacts())
            "starredContacts" -> background(result) { starredContacts() }
            "contactsByLookup" -> {
                val keys = call.argument<List<String>>("keys") ?: emptyList()
                background(result) { contactsByLookup(keys) }
            }
            "searchContacts" -> {
                val query = call.argument<String>("query") ?: ""
                background(result) { searchContacts(query) }
            }
            "dial" -> result.success(
                startSafely(Intent(Intent.ACTION_DIAL, Uri.parse("tel:" + Uri.encode(call.argument<String>("number") ?: "")))),
            )
            "sms" -> result.success(
                startSafely(Intent(Intent.ACTION_SENDTO, Uri.parse("smsto:" + Uri.encode(call.argument<String>("number") ?: "")))),
            )
            "openContact" -> result.success(
                startSafely(
                    Intent(
                        Intent.ACTION_VIEW,
                        ContactsContract.Contacts.getLookupUri(
                            call.argument<Number>("id")!!.toLong(),
                            call.argument<String>("lookupKey") ?: "",
                        ),
                    ),
                ),
            )
            "openEvent" -> result.success(
                openEvent(
                    call.argument<Number>("id")!!.toLong(),
                    call.argument<Number>("begin")!!.toLong(),
                    call.argument<Number>("end")!!.toLong(),
                ),
            )
            "newEvent" -> result.success(
                startSafely(Intent(Intent.ACTION_INSERT, CalendarContract.Events.CONTENT_URI)),
            )
            "navigateTo" -> result.success(
                startSafely(Intent(Intent.ACTION_VIEW, Uri.parse("geo:0,0?q=" + Uri.encode(call.argument<String>("query") ?: "")))),
            )
            "getNextAlarm" -> result.success(
                context.getSystemService(AlarmManager::class.java).nextAlarmClock?.triggerTime,
            )
            "openAlarms" -> result.success(startSafely(Intent(AlarmClock.ACTION_SHOW_ALARMS)))
            "openTimers" -> result.success(
                startSafely(Intent(AlarmClock.ACTION_SHOW_TIMERS)) ||
                    startSafely(Intent(AlarmClock.ACTION_SHOW_ALARMS)),
            )
            "openDoNotDisturb" -> result.success(
                startSafely(Intent(Settings.ACTION_ZEN_MODE_PRIORITY_SETTINGS)) ||
                    startSafely(Intent(Settings.ACTION_SOUND_SETTINGS)),
            )
            else -> result.notImplemented()
        }
    }

    private fun <T> background(result: MethodChannel.Result, block: () -> T) {
        worker.execute {
            try {
                val value = block()
                main.post { result.success(value) }
            } catch (e: Exception) {
                main.post { result.error("native_error", e.message, null) }
            }
        }
    }

    // region App
    private fun idOf(info: LauncherActivityInfo): String =
        "${info.componentName.packageName}/${info.componentName.className}"

    private fun componentOf(id: String): ComponentName? {
        val slash = id.indexOf('/')
        if (slash <= 0) return null
        return ComponentName(id.substring(0, slash), id.substring(slash + 1))
    }

    private fun getApps(): List<Map<String, Any?>> {
        val own = context.packageName
        val list = launcherApps.getActivityList(null, user)
        infoById.clear()
        return list.filter { it.componentName.packageName != own }.map { info ->
            val id = idOf(info)
            infoById[id] = info
            val appInfo = info.applicationInfo
            val system = (appInfo.flags and (ApplicationInfo.FLAG_SYSTEM or ApplicationInfo.FLAG_UPDATED_SYSTEM_APP)) != 0
            mapOf(
                "package" to info.componentName.packageName,
                "activity" to info.componentName.className,
                "label" to info.label?.toString(),
                "system" to system,
                "category" to appInfo.category,
                "installed" to info.firstInstallTime,
            )
        }
    }

    private fun resolve(id: String): LauncherActivityInfo? {
        infoById[id]?.let { return it }
        val component = componentOf(id) ?: return null
        val intent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER).setComponent(component)
        return launcherApps.resolveActivity(intent, user)?.also { infoById[id] = it }
    }

    private fun launch(id: String, bounds: List<Int>?): Boolean {
        val info = resolve(id) ?: return false
        // Digital detox: un'app bloccata aperta dal launcher mostra subito il
        // blocco, senza passare dall'app.
        val pkg = info.componentName.packageName
        if (Detox.unlockedPackage != pkg && Detox.isLockedNow(context, pkg)) {
            Detox.showLock(context, pkg, info.componentName)
            return true
        }
        return try {
            val options = if (bounds != null && bounds.size == 4) {
                val view = activity.window.decorView
                ActivityOptions.makeScaleUpAnimation(
                    view, bounds[0], bounds[1], bounds[2] - bounds[0], bounds[3] - bounds[1],
                ).toBundle()
            } else {
                null
            }
            val rect = if (bounds != null && bounds.size == 4) {
                android.graphics.Rect(bounds[0], bounds[1], bounds[2], bounds[3])
            } else {
                null
            }
            launcherApps.startMainActivity(info.componentName, user, rect, options)
            true
        } catch (e: Exception) {
            false
        }
    }

    /** Apre la scheda del servizio di Digital detox nelle impostazioni di accessibilità. */
    private fun openDetoxService(): Boolean {
        if (Build.VERSION.SDK_INT >= 33) {
            val details = Intent("android.settings.ACCESSIBILITY_DETAILS_SETTINGS")
                .putExtra(Intent.EXTRA_COMPONENT_NAME, ComponentName(context, DetoxService::class.java).flattenToString())
            if (startSafely(details)) return true
        }
        return startSafely(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
    }

    private fun openAppInfo(id: String): Boolean {
        val component = componentOf(id) ?: return false
        return try {
            launcherApps.startAppDetailsActivity(component, user, null, null)
            true
        } catch (e: Exception) {
            false
        }
    }

    private fun uninstall(packageName: String): Boolean =
        startSafely(Intent(Intent.ACTION_DELETE, Uri.parse("package:$packageName")))

    private fun startSafely(intent: Intent): Boolean = try {
        activity.startActivity(intent)
        true
    } catch (e: Exception) {
        false
    }
    // endregion

    // region Icone
    /**
     * Per ogni id restituisce l'icona normale e, se esiste (Android 13+),
     * il layer monocromo come maschera bianca per le icone a tema.
     */
    private fun getIcons(ids: List<String>, size: Int): Map<String, Map<String, ByteArray?>> {
        val density = context.resources.displayMetrics.densityDpi
        val out = HashMap<String, Map<String, ByteArray?>>()
        for (id in ids) {
            val info = resolve(id) ?: continue
            val drawable = try {
                info.getIcon(density)
            } catch (e: Exception) {
                null
            } ?: continue
            out[id] = mapOf(
                "icon" to renderIcon(drawable, size),
                "mono" to renderMonochrome(drawable, size),
            )
        }
        return out
    }

    private fun renderIcon(d: Drawable, size: Int): ByteArray {
        val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        d.setBounds(0, 0, size, size)
        d.draw(canvas)
        return bitmap.toPng()
    }

    private fun renderMonochrome(d: Drawable, size: Int): ByteArray? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return null
        val adaptive = d as? AdaptiveIconDrawable ?: return null
        val mono = adaptive.monochrome?.mutate() ?: return null
        // I layer adattivi sono 108 unità, la zona visibile 72: si allarga
        // di 1/4 per lato così il glifo riempie l'icona come nel sistema.
        val inset = size / 4
        val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        mono.setBounds(-inset, -inset, size + inset, size + inset)
        mono.colorFilter = PorterDuffColorFilter(Color.WHITE, PorterDuff.Mode.SRC_IN)
        mono.draw(canvas)
        return bitmap.toPng()
    }

    private fun Bitmap.toPng(): ByteArray {
        val stream = ByteArrayOutputStream()
        compress(Bitmap.CompressFormat.PNG, 100, stream)
        recycle()
        return stream.toByteArray()
    }
    // endregion

    // region Contesto
    /**
     * Segnali di contesto che non richiedono permessi: tipo di rete, uscita
     * audio, ricarica. Nessun nome di rete o dispositivo esce da qui.
     */
    private fun contextSnapshot(): Map<String, Any?> {
        val connectivity = context.getSystemService(ConnectivityManager::class.java)
        val caps = connectivity.getNetworkCapabilities(connectivity.activeNetwork)
        val network = when {
            caps == null -> "offline"
            caps.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) -> "wifi"
            caps.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) -> "mobile"
            else -> "wifi" // ethernet, VPN su Wi-Fi: trattati come rete fissa
        }

        val audio = context.getSystemService(AudioManager::class.java)
        val devices = audio.getDevices(AudioManager.GET_DEVICES_OUTPUTS).toList()
        val outputs = devices.map { it.type }.toSet()
        val wired = setOf(
            AudioDeviceInfo.TYPE_WIRED_HEADSET,
            AudioDeviceInfo.TYPE_WIRED_HEADPHONES,
            AudioDeviceInfo.TYPE_USB_HEADSET,
        )
        val bluetooth = setOf(
            AudioDeviceInfo.TYPE_BLUETOOTH_A2DP,
            AudioDeviceInfo.TYPE_BLE_HEADSET,
            AudioDeviceInfo.TYPE_BLE_SPEAKER,
        )
        val route = when {
            outputs.any { it in wired } -> "headphones"
            outputs.any { it in bluetooth } -> "bt"
            else -> "speaker"
        }

        val battery = context.getSystemService(BatteryManager::class.java)
        val roaming = try {
            context.getSystemService(TelephonyManager::class.java).isNetworkRoaming
        } catch (e: Exception) {
            false
        }
        return mapOf(
            "network" to network,
            "audio" to route,
            "charging" to battery.isCharging,
            // Fuso orario (es. "Europe/Rome") e roaming: servono a capire
            // se l'utente è in viaggio, senza posizione.
            "tz" to TimeZone.getDefault().id,
            "roaming" to roaming,
            "car" to inCar(devices),
            "battery" to battery.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY),
            "dnd" to (
                context.getSystemService(android.app.NotificationManager::class.java)
                    .currentInterruptionFilter > android.app.NotificationManager.INTERRUPTION_FILTER_ALL
                ),
        )
    }
    // endregion

    // region Calendario
    private fun hasCalendar(): Boolean =
        context.checkSelfPermission(Manifest.permission.READ_CALENDAR) == PackageManager.PERMISSION_GRANTED

    /**
     * Eventi tra [from] e [to] (ms) dai calendari visibili, esclusi quelli
     * rifiutati. Null se manca il permesso.
     */
    private fun readEvents(from: Long, to: Long): List<Map<String, Any?>>? {
        if (!hasCalendar()) return null
        val builder = CalendarContract.Instances.CONTENT_URI.buildUpon()
        ContentUris.appendId(builder, from)
        ContentUris.appendId(builder, to)
        val projection = arrayOf(
            CalendarContract.Instances.EVENT_ID,
            CalendarContract.Instances.TITLE,
            CalendarContract.Instances.BEGIN,
            CalendarContract.Instances.END,
            CalendarContract.Instances.ALL_DAY,
            CalendarContract.Instances.EVENT_LOCATION,
            CalendarContract.Instances.DISPLAY_COLOR,
        )
        val selection = "${CalendarContract.Instances.VISIBLE} = 1 AND " +
            "${CalendarContract.Instances.SELF_ATTENDEE_STATUS} != ${CalendarContract.Attendees.ATTENDEE_STATUS_DECLINED}"
        val out = ArrayList<Map<String, Any?>>()
        context.contentResolver.query(
            builder.build(), projection, selection, null, "${CalendarContract.Instances.BEGIN} ASC",
        )?.use { c ->
            while (c.moveToNext() && out.size < 20) {
                out.add(
                    mapOf(
                        "id" to c.getLong(0),
                        "title" to (c.getString(1) ?: ""),
                        "begin" to c.getLong(2),
                        "end" to c.getLong(3),
                        "allDay" to (c.getInt(4) == 1),
                        "location" to c.getString(5),
                        "color" to c.getInt(6),
                    ),
                )
            }
        }
        return out
    }

    /**
     * Chiede il permesso calendario. Se l'utente l'ha già negato in modo
     * definitivo, apre le informazioni dell'app dove si può concedere a mano.
     */
    private fun requestCalendar(): Boolean {
        if (hasCalendar()) return true
        val prefs = context.getSharedPreferences("libreglide_native", Context.MODE_PRIVATE)
        val asked = prefs.getBoolean("calendar_asked", false)
        return if (!asked || activity.shouldShowRequestPermissionRationale(Manifest.permission.READ_CALENDAR)) {
            prefs.edit().putBoolean("calendar_asked", true).apply()
            activity.requestPermissions(arrayOf(Manifest.permission.READ_CALENDAR), REQUEST_CALENDAR)
            true
        } else {
            startSafely(
                Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:${context.packageName}")),
            )
        }
    }

    private fun openEvent(id: Long, begin: Long, end: Long): Boolean = startSafely(
        Intent(Intent.ACTION_VIEW, ContentUris.withAppendedId(CalendarContract.Events.CONTENT_URI, id))
            .putExtra(CalendarContract.EXTRA_EVENT_BEGIN_TIME, begin)
            .putExtra(CalendarContract.EXTRA_EVENT_END_TIME, end),
    )
    // endregion

    // region Contatti
    private fun hasContacts(): Boolean =
        context.checkSelfPermission(Manifest.permission.READ_CONTACTS) == PackageManager.PERMISSION_GRANTED

    private fun requestContacts(): Boolean {
        if (hasContacts()) return true
        val prefs = context.getSharedPreferences("libreglide_native", Context.MODE_PRIVATE)
        val asked = prefs.getBoolean("contacts_asked", false)
        return if (!asked || activity.shouldShowRequestPermissionRationale(Manifest.permission.READ_CONTACTS)) {
            prefs.edit().putBoolean("contacts_asked", true).apply()
            activity.requestPermissions(arrayOf(Manifest.permission.READ_CONTACTS), REQUEST_CONTACTS)
            true
        } else {
            startSafely(
                Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:${context.packageName}")),
            )
        }
    }

    private val contactProjection = arrayOf(
        ContactsContract.Contacts._ID,
        ContactsContract.Contacts.LOOKUP_KEY,
        ContactsContract.Contacts.DISPLAY_NAME_PRIMARY,
        ContactsContract.Contacts.STARRED,
        ContactsContract.Contacts.HAS_PHONE_NUMBER,
    )

    /** Righe di contatto con numero principale e miniatura (solo in memoria). */
    private fun readContacts(uri: Uri, selection: String?, args: Array<String>?, limit: Int): List<Map<String, Any?>> {
        if (!hasContacts()) return emptyList()
        val out = ArrayList<Map<String, Any?>>()
        context.contentResolver.query(
            uri, contactProjection, selection, args,
            "${ContactsContract.Contacts.DISPLAY_NAME_PRIMARY} COLLATE LOCALIZED ASC",
        )?.use { c ->
            while (c.moveToNext() && out.size < limit) {
                val id = c.getLong(0)
                val name = c.getString(2) ?: continue
                out.add(
                    mapOf(
                        "id" to id,
                        "lookupKey" to c.getString(1),
                        "name" to name,
                        "starred" to (c.getInt(3) == 1),
                        "number" to if (c.getInt(4) == 1) primaryNumber(id) else null,
                        "photo" to thumbnail(id),
                    ),
                )
            }
        }
        return out
    }

    private fun primaryNumber(contactId: Long): String? {
        context.contentResolver.query(
            ContactsContract.CommonDataKinds.Phone.CONTENT_URI,
            arrayOf(ContactsContract.CommonDataKinds.Phone.NUMBER, ContactsContract.CommonDataKinds.Phone.IS_SUPER_PRIMARY),
            "${ContactsContract.CommonDataKinds.Phone.CONTACT_ID} = ?",
            arrayOf(contactId.toString()),
            "${ContactsContract.CommonDataKinds.Phone.IS_SUPER_PRIMARY} DESC",
        )?.use { c -> if (c.moveToFirst()) return c.getString(0) }
        return null
    }

    private fun thumbnail(contactId: Long): ByteArray? = try {
        val uri = ContentUris.withAppendedId(ContactsContract.Contacts.CONTENT_URI, contactId)
        ContactsContract.Contacts.openContactPhotoInputStream(context.contentResolver, uri, false)
            ?.use { it.readBytes() }
    } catch (e: Exception) {
        null
    }

    private fun starredContacts(): List<Map<String, Any?>> = readContacts(
        ContactsContract.Contacts.CONTENT_URI, "${ContactsContract.Contacts.STARRED} = 1", null, 24,
    )

    private fun contactsByLookup(keys: List<String>): List<Map<String, Any?>> {
        if (keys.isEmpty()) return emptyList()
        val marks = keys.joinToString(",") { "?" }
        return readContacts(
            ContactsContract.Contacts.CONTENT_URI,
            "${ContactsContract.Contacts.LOOKUP_KEY} IN ($marks)",
            keys.toTypedArray(),
            keys.size,
        )
    }

    private fun searchContacts(query: String): List<Map<String, Any?>> {
        if (query.isBlank()) return emptyList()
        val uri = Uri.withAppendedPath(ContactsContract.Contacts.CONTENT_FILTER_URI, Uri.encode(query.trim()))
        return readContacts(uri, null, null, 30)
    }
    // endregion

    // region Luoghi: posizione precisa e impronta del Wi-Fi
    private fun hasPreciseLocation(): Boolean =
        context.checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED

    private fun requestPreciseLocation(): Boolean {
        if (hasPreciseLocation()) return true
        val prefs = context.getSharedPreferences("libreglide_native", Context.MODE_PRIVATE)
        val asked = prefs.getBoolean("precise_asked", false)
        return if (!asked || activity.shouldShowRequestPermissionRationale(Manifest.permission.ACCESS_FINE_LOCATION)) {
            prefs.edit().putBoolean("precise_asked", true).apply()
            activity.requestPermissions(
                arrayOf(Manifest.permission.ACCESS_FINE_LOCATION, Manifest.permission.ACCESS_COARSE_LOCATION),
                REQUEST_PRECISE,
            )
            true
        } else {
            startSafely(
                Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:${context.packageName}")),
            )
        }
    }

    /** Ultima rete Wi-Fi vista (con il permesso di posizione precisa). */
    @Volatile private var wifiSsid: String? = null
    @Volatile private var wifiMetered = true

    private val wifiCallback = object : ConnectivityManager.NetworkCallback(FLAG_INCLUDE_LOCATION_INFO) {
        override fun onCapabilitiesChanged(network: Network, caps: NetworkCapabilities) {
            val info = caps.transportInfo as? WifiInfo
            val ssid = info?.ssid?.trim('"')
            wifiSsid = if (ssid.isNullOrEmpty() || ssid == WifiManager.UNKNOWN_SSID.trim('"')) null else ssid
            wifiMetered = !caps.hasCapability(NetworkCapabilities.NET_CAPABILITY_NOT_METERED)
        }

        override fun onLost(network: Network) {
            wifiSsid = null
        }
    }

    private fun registerWifiCallback() {
        try {
            context.getSystemService(ConnectivityManager::class.java)
                .registerDefaultNetworkCallback(wifiCallback, main)
        } catch (e: Exception) {
        }
    }

    // Dopo la dichiarazione della callback: i blocchi init girano in ordine.
    init {
        registerWifiCallback()
    }

    private fun unregisterWifiCallback() {
        try {
            context.getSystemService(ConnectivityManager::class.java).unregisterNetworkCallback(wifiCallback)
        } catch (e: Exception) {
        }
    }

    /**
     * Impronta del Wi-Fi: SHA-256 del nome con una chiave casuale che esiste
     * solo su questo telefono. Il nome della rete non esce mai da qui.
     * Le reti a consumo (hotspot) sono escluse: si spostano con te.
     */
    private fun wifiHash(): String? {
        val ssid = wifiSsid ?: return null
        if (wifiMetered) return null
        val prefs = context.getSharedPreferences("libreglide_native", Context.MODE_PRIVATE)
        var salt = prefs.getString("wifi_salt", null)
        if (salt == null) {
            val bytes = ByteArray(32).also { java.security.SecureRandom().nextBytes(it) }
            salt = android.util.Base64.encodeToString(bytes, android.util.Base64.NO_WRAP)
            prefs.edit().putString("wifi_salt", salt).apply()
        }
        val digest = java.security.MessageDigest.getInstance("SHA-256").digest((salt + ssid).toByteArray())
        return digest.take(16).joinToString("") { "%02x".format(it) }
    }

    /** Parcheggio salvato da [ParkingReceiver], o null. */
    private fun parking(): Map<String, Any?>? {
        val prefs = context.getSharedPreferences(ParkingReceiver.PREFS, Context.MODE_PRIVATE)
        val lat = prefs.getString(ParkingReceiver.KEY_LAT, null)?.toDoubleOrNull() ?: return null
        val lon = prefs.getString(ParkingReceiver.KEY_LON, null)?.toDoubleOrNull() ?: return null
        return mapOf(
            "lat" to lat,
            "lon" to lon,
            "accuracy" to prefs.getFloat(ParkingReceiver.KEY_ACCURACY, 0f).toDouble(),
            "ts" to prefs.getLong(ParkingReceiver.KEY_TS, 0L),
            "precise" to prefs.getBoolean(ParkingReceiver.KEY_PRECISE, false),
        )
    }

    /** Un campione per i luoghi: posizione precisa, impronta Wi-Fi, ricarica. */
    private fun placeSample(result: MethodChannel.Result, withLocation: Boolean) {
        if (!hasPreciseLocation()) {
            result.success(null)
            return
        }
        val lm = context.getSystemService(LocationManager::class.java)
        val charging = context.getSystemService(BatteryManager::class.java).isCharging
        fun reply(location: Location?) {
            val wifi = wifiHash()
            main.post {
                if (location == null && wifi == null) {
                    result.success(null)
                } else {
                    result.success(
                        mapOf(
                            "lat" to location?.latitude,
                            "lon" to location?.longitude,
                            "accuracy" to location?.accuracy?.toDouble(),
                            "wifi" to wifi,
                            "charging" to charging,
                        ),
                    )
                }
            }
        }
        if (!withLocation) {
            // Solo Wi-Fi e ricarica: la localizzazione resta spenta.
            reply(null)
            return
        }
        fun recent(): Location? = listOf(LocationManager.FUSED_PROVIDER, LocationManager.GPS_PROVIDER, LocationManager.NETWORK_PROVIDER)
            .mapNotNull { p -> try { lm.getLastKnownLocation(p) } catch (e: Exception) { null } }
            .filter { System.currentTimeMillis() - it.time < 10 * 60 * 1000 }
            .minByOrNull { it.accuracy }
        val provider = when {
            lm.isProviderEnabled(LocationManager.FUSED_PROVIDER) -> LocationManager.FUSED_PROVIDER
            lm.isProviderEnabled(LocationManager.NETWORK_PROVIDER) -> LocationManager.NETWORK_PROVIDER
            else -> null
        }
        if (provider == null) {
            reply(recent())
            return
        }
        try {
            val signal = CancellationSignal()
            var done = false
            main.postDelayed({
                if (!done) {
                    done = true
                    signal.cancel()
                    reply(recent())
                }
            }, 6000)
            lm.getCurrentLocation(provider, signal, worker) { location ->
                if (!done) {
                    done = true
                    reply(location ?: recent())
                }
            }
        } catch (e: Exception) {
            reply(recent())
        }
    }
    // endregion

    // region Tempo di utilizzo
    private fun hasUsageAccess(): Boolean {
        val ops = context.getSystemService(AppOpsManager::class.java)
        val mode = ops.unsafeCheckOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS, Process.myUid(), context.packageName)
        return mode == AppOpsManager.MODE_ALLOWED
    }

    /**
     * Tempo in primo piano di oggi (da mezzanotte), per app, calcolato dagli
     * eventi di utilizzo. Esclusi libreGLIDE e l'interfaccia di sistema.
     * Null senza l'accesso ai dati di utilizzo.
     */
    /**
     * Aperture di app dalla cronologia di utilizzo di Android, da [since]
     * (al massimo 14 giorni fa): un'apertura è il passaggio in primo piano
     * di un'app avviabile diversa dalla precedente. Launcher, SystemUI e
     * tastiere non contano e non interrompono l'app in uso. Si leggono solo
     * pacchetto e ora; nulla esce dal telefono.
     */
    private fun usageOpenings(since: Long): List<Map<String, Any>> {
        if (!hasUsageAccess()) return emptyList()
        val usm = context.getSystemService(UsageStatsManager::class.java)
        val now = System.currentTimeMillis()
        val from = maxOf(since, now - 14L * 24 * 60 * 60 * 1000)
        val launchable = launcherApps.getActivityList(null, Process.myUserHandle())
            .map { it.componentName.packageName }.toSet()
        val homes = context.packageManager.queryIntentActivities(
            Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME),
            PackageManager.MATCH_ALL,
        ).map { it.activityInfo.packageName }
        val keyboards = try {
            context.getSystemService(android.view.inputmethod.InputMethodManager::class.java)
                .enabledInputMethodList.map { it.packageName }
        } catch (e: Exception) {
            emptyList()
        }
        val passive = setOf(context.packageName, "com.android.systemui") + homes + keyboards
        val out = ArrayList<Map<String, Any>>()
        var current: String? = null
        val events = usm.queryEvents(from, now)
        val e = UsageEvents.Event()
        while (events.hasNextEvent()) {
            events.getNextEvent(e)
            if (e.eventType != UsageEvents.Event.ACTIVITY_RESUMED) continue
            val pkg = e.packageName
            if (pkg in passive) {
                // Tornare alla Home "chiude" l'app: riaprirla poi è una nuova apertura.
                if (pkg != "com.android.systemui" && pkg !in keyboards) current = null
                continue
            }
            if (pkg != current && pkg in launchable) out.add(mapOf("package" to pkg, "ts" to e.timeStamp))
            current = pkg
        }
        return out
    }

    private fun screenTimeToday(): Map<String, Any?>? {
        if (!hasUsageAccess()) return null
        val usm = context.getSystemService(UsageStatsManager::class.java)
        val now = System.currentTimeMillis()
        val midnight = java.util.Calendar.getInstance().apply {
            set(java.util.Calendar.HOUR_OF_DAY, 0)
            set(java.util.Calendar.MINUTE, 0)
            set(java.util.Calendar.SECOND, 0)
            set(java.util.Calendar.MILLISECOND, 0)
        }.timeInMillis
        val excluded = setOf(context.packageName, "com.android.systemui")
        val totals = HashMap<String, Long>()
        var current: String? = null
        var since = 0L
        fun close(at: Long) {
            val pkg = current ?: return
            if (pkg !in excluded) totals[pkg] = (totals[pkg] ?: 0L) + (at - since).coerceAtLeast(0L)
            current = null
        }
        val events = usm.queryEvents(midnight, now)
        val e = UsageEvents.Event()
        while (events.hasNextEvent()) {
            events.getNextEvent(e)
            when (e.eventType) {
                UsageEvents.Event.ACTIVITY_RESUMED -> {
                    if (current != e.packageName) {
                        close(e.timeStamp)
                        current = e.packageName
                        since = e.timeStamp
                    }
                }
                UsageEvents.Event.ACTIVITY_PAUSED, UsageEvents.Event.ACTIVITY_STOPPED ->
                    if (current == e.packageName) close(e.timeStamp)
                UsageEvents.Event.SCREEN_NON_INTERACTIVE, UsageEvents.Event.KEYGUARD_SHOWN -> close(e.timeStamp)
            }
        }
        close(now)
        val top = totals.entries.sortedByDescending { it.value }.take(5)
        return mapOf(
            "totalMs" to totals.values.sum(),
            "top" to top.map { mapOf("package" to it.key, "ms" to it.value) },
        )
    }
    // endregion

    // region Widget Android
    private val widgetHost = (activity.application as LibreGlideApplication).widgetHost
    private val widgetManager = AppWidgetManager.getInstance(context)
    private var pendingWidgetId: Int? = null
    private var pendingWidgetResult: MethodChannel.Result? = null

    private fun pxToDp(px: Int): Int = (px / context.resources.displayMetrics.density).toInt()

    /** Widget installati, dall'app al nome. */
    private fun widgetProviders(): List<Map<String, Any?>> {
        val pm = context.packageManager
        return widgetManager.installedProviders.map { info ->
            mapOf(
                "provider" to info.provider.flattenToString(),
                "package" to info.provider.packageName,
                "label" to info.loadLabel(pm),
                "minWidth" to pxToDp(info.minWidth),
                "minHeight" to pxToDp(info.minHeight),
            )
        }.sortedWith(compareBy({ it["package"] as String }, { it["label"] as String }))
    }

    /**
     * Aggiunge un widget: alloca l'id, chiede il permesso di collegarlo se
     * serve, poi apre la sua configurazione se la richiede. Il risultato
     * (id, nome, dimensioni minime) arriva alla fine del flusso, o null.
     */
    private fun addWidget(flattened: String, result: MethodChannel.Result) {
        val provider = ComponentName.unflattenFromString(flattened)
        if (provider == null || pendingWidgetResult != null) {
            result.success(null)
            return
        }
        val id = widgetHost.allocateAppWidgetId()
        pendingWidgetId = id
        pendingWidgetResult = result
        if (widgetManager.bindAppWidgetIdIfAllowed(id, provider)) {
            configureOrFinish(id)
        } else {
            val intent = Intent(AppWidgetManager.ACTION_APPWIDGET_BIND)
                .putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, id)
                .putExtra(AppWidgetManager.EXTRA_APPWIDGET_PROVIDER, provider)
            try {
                activity.startActivityForResult(intent, REQUEST_BIND_WIDGET)
            } catch (e: Exception) {
                finishWidget(false)
            }
        }
    }

    private fun configureOrFinish(id: Int) {
        val info = widgetManager.getAppWidgetInfo(id)
        val optional = info?.widgetFeatures?.and(AppWidgetProviderInfo.WIDGET_FEATURE_CONFIGURATION_OPTIONAL) != 0
        if (info?.configure != null && !optional) {
            try {
                widgetHost.startAppWidgetConfigureActivityForResult(activity, id, 0, REQUEST_CONFIGURE_WIDGET, null)
            } catch (e: Exception) {
                finishWidget(false)
            }
        } else {
            finishWidget(true)
        }
    }

    private fun finishWidget(ok: Boolean) {
        val id = pendingWidgetId
        val result = pendingWidgetResult
        pendingWidgetId = null
        pendingWidgetResult = null
        if (id == null || result == null) return
        if (!ok) {
            widgetHost.deleteAppWidgetId(id)
            result.success(null)
            return
        }
        val info = widgetManager.getAppWidgetInfo(id)
        result.success(
            mapOf(
                "id" to id,
                "label" to info?.loadLabel(context.packageManager),
                "minHeight" to (info?.let { pxToDp(it.minHeight) } ?: 110),
            ),
        )
    }

    /** Risultati dei dialoghi di sistema (collegamento, configurazione). */
    fun onActivityResult(requestCode: Int, resultCode: Int) {
        when (requestCode) {
            REQUEST_BIND_WIDGET ->
                if (resultCode == Activity.RESULT_OK) configureOrFinish(pendingWidgetId ?: return) else finishWidget(false)
            REQUEST_CONFIGURE_WIDGET -> finishWidget(resultCode == Activity.RESULT_OK)
        }
    }
    // endregion

    // region Posizione approssimativa (meteo) e Bluetooth (auto)
    private fun hasLocation(): Boolean =
        context.checkSelfPermission(Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED

    private fun requestLocation(): Boolean =
        requestOnce(Manifest.permission.ACCESS_COARSE_LOCATION, "location_asked", REQUEST_LOCATION)

    private fun hasBluetooth(): Boolean =
        context.checkSelfPermission(Manifest.permission.BLUETOOTH_CONNECT) == PackageManager.PERMISSION_GRANTED

    private fun requestBluetooth(): Boolean =
        requestOnce(Manifest.permission.BLUETOOTH_CONNECT, "bluetooth_asked", REQUEST_BLUETOOTH)

    /**
     * Chiede un permesso; se l'utente l'ha già negato in modo definitivo apre
     * le informazioni dell'app, dove si può concedere a mano.
     */
    private fun requestOnce(permission: String, key: String, code: Int): Boolean {
        if (context.checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED) return true
        val prefs = context.getSharedPreferences("libreglide_native", Context.MODE_PRIVATE)
        val asked = prefs.getBoolean(key, false)
        return if (!asked || activity.shouldShowRequestPermissionRationale(permission)) {
            prefs.edit().putBoolean(key, true).apply()
            activity.requestPermissions(arrayOf(permission), code)
            true
        } else {
            startSafely(
                Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:${context.packageName}")),
            )
        }
    }

    /**
     * Posizione approssimativa (rete/fused), solo con il permesso concesso.
     * Prima prova una lettura fresca, poi l'ultima nota. Null se non c'è.
     */
    private fun coarseLocation(result: MethodChannel.Result) {
        if (!hasLocation()) {
            result.success(null)
            return
        }
        val lm = context.getSystemService(LocationManager::class.java)
        fun reply(location: Location?) {
            main.post {
                result.success(
                    location?.let {
                        mapOf(
                            "lat" to it.latitude,
                            "lon" to it.longitude,
                            "ageMs" to (System.currentTimeMillis() - it.time),
                        )
                    },
                )
            }
        }
        fun lastKnown(): Location? = listOf(LocationManager.NETWORK_PROVIDER, LocationManager.FUSED_PROVIDER, LocationManager.PASSIVE_PROVIDER)
            .mapNotNull { p -> try { lm.getLastKnownLocation(p) } catch (e: Exception) { null } }
            .maxByOrNull { it.time }
        val provider = when {
            lm.isProviderEnabled(LocationManager.NETWORK_PROVIDER) -> LocationManager.NETWORK_PROVIDER
            lm.isProviderEnabled(LocationManager.FUSED_PROVIDER) -> LocationManager.FUSED_PROVIDER
            else -> null
        }
        if (provider == null) {
            reply(lastKnown())
            return
        }
        try {
            val signal = CancellationSignal()
            var done = false
            main.postDelayed({
                if (!done) {
                    done = true
                    signal.cancel()
                    reply(lastKnown())
                }
            }, 8000)
            lm.getCurrentLocation(provider, signal, worker) { location ->
                if (!done) {
                    done = true
                    reply(location ?: lastKnown())
                }
            }
        } catch (e: Exception) {
            reply(lastKnown())
        }
    }

    /**
     * In auto: Android Auto attivo (nessun permesso) oppure, con il permesso
     * Bluetooth, un'autoradio o un vivavoce collegato come uscita audio.
     */
    private fun inCar(outputs: List<AudioDeviceInfo>): Boolean {
        val ui = context.getSystemService(UiModeManager::class.java)
        if (ui.currentModeType == Configuration.UI_MODE_TYPE_CAR) return true
        if (!hasBluetooth()) return false
        return try {
            val adapter = context.getSystemService(BluetoothManager::class.java).adapter ?: return false
            outputs.filter {
                it.type == AudioDeviceInfo.TYPE_BLUETOOTH_A2DP || it.type == AudioDeviceInfo.TYPE_BLUETOOTH_SCO
            }.any { device ->
                val cls = adapter.getRemoteDevice(device.address).bluetoothClass?.deviceClass
                cls == BluetoothClass.Device.AUDIO_VIDEO_CAR_AUDIO || cls == BluetoothClass.Device.AUDIO_VIDEO_HANDSFREE
            }
        } catch (e: Exception) {
            false
        }
    }
    // endregion

    // region Media
    private fun openMediaAccess(): Boolean {
        val component = ComponentName(context, MediaListenerService::class.java)
        return startSafely(
            Intent(Settings.ACTION_NOTIFICATION_LISTENER_DETAIL_SETTINGS)
                .putExtra(Settings.EXTRA_NOTIFICATION_LISTENER_COMPONENT_NAME, component.flattenToString()),
        ) || startSafely(Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS))
    }
    // endregion

    // region Ruolo Home
    private fun isDefaultHome(): Boolean {
        val roleManager = context.getSystemService(RoleManager::class.java)
        return roleManager.isRoleAvailable(RoleManager.ROLE_HOME) && roleManager.isRoleHeld(RoleManager.ROLE_HOME)
    }

    private fun requestDefaultHome(): Boolean {
        val roleManager = context.getSystemService(RoleManager::class.java)
        if (roleManager.isRoleAvailable(RoleManager.ROLE_HOME) && !roleManager.isRoleHeld(RoleManager.ROLE_HOME)) {
            return try {
                activity.startActivityForResult(roleManager.createRequestRoleIntent(RoleManager.ROLE_HOME), REQUEST_HOME_ROLE)
                true
            } catch (e: Exception) {
                startSafely(Intent(Settings.ACTION_HOME_SETTINGS))
            }
        }
        return startSafely(Intent(Settings.ACTION_HOME_SETTINGS))
    }
    // endregion

    companion object {
        const val METHOD_CHANNEL = "libreglide/launcher"
        const val EVENT_CHANNEL = "libreglide/launcher/events"
        private const val REQUEST_HOME_ROLE = 4201
        private const val REQUEST_CALENDAR = 4202
        private const val REQUEST_CONTACTS = 4203
        private const val REQUEST_LOCATION = 4204
        private const val REQUEST_BLUETOOTH = 4205
        private const val REQUEST_BIND_WIDGET = 4206
        private const val REQUEST_CONFIGURE_WIDGET = 4207
        private const val REQUEST_PRECISE = 4208
        private const val REQUEST_BACKGROUND = 4209
    }
}
