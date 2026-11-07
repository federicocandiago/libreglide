package org.libreglide.launcher

import android.Manifest
import android.bluetooth.BluetoothClass
import android.bluetooth.BluetoothDevice
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationManager
import android.os.CancellationSignal
import android.os.Handler
import android.os.Looper
import java.util.concurrent.Executors

/**
 * "Where I parked": when the phone disconnects from a Bluetooth car stereo or
 * hands-free kit, it saves the location (on the phone only). When it
 * reconnects to the car, the parking spot is forgotten.
 *
 * Active only if the user turned the feature on (`parking_enabled`
 * preference). It is the only place in libreGLIDE that uses background
 * location, and it requires that permission.
 */
class ParkingReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        if (!prefs.getBoolean(KEY_ENABLED, false)) return
        if (!isCar(context, intent)) return

        when (intent.action) {
            BluetoothDevice.ACTION_ACL_CONNECTED -> clear(context)
            BluetoothDevice.ACTION_ACL_DISCONNECTED -> saveLocation(context)
        }
    }

    private fun isCar(context: Context, intent: Intent): Boolean {
        if (context.checkSelfPermission(Manifest.permission.BLUETOOTH_CONNECT) != PackageManager.PERMISSION_GRANTED) {
            return false
        }
        return try {
            val device = intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE, BluetoothDevice::class.java)
            val cls = device?.bluetoothClass?.deviceClass
            cls == BluetoothClass.Device.AUDIO_VIDEO_CAR_AUDIO || cls == BluetoothClass.Device.AUDIO_VIDEO_HANDSFREE
        } catch (e: Exception) {
            false
        }
    }

    private fun saveLocation(context: Context) {
        val pending = goAsync()
        val lm = context.getSystemService(LocationManager::class.java)
        val main = Handler(Looper.getMainLooper())
        val executor = Executors.newSingleThreadExecutor()
        var done = false

        fun store(location: Location?, precise: Boolean) {
            if (done) return
            done = true
            if (location != null) {
                context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
                    .putString(KEY_LAT, location.latitude.toString())
                    .putString(KEY_LON, location.longitude.toString())
                    .putFloat(KEY_ACCURACY, location.accuracy)
                    .putLong(KEY_TS, System.currentTimeMillis())
                    .putBoolean(KEY_PRECISE, precise)
                    .apply()
            }
            executor.shutdown()
            pending.finish()
        }

        fun lastKnown(): Location? = listOf(LocationManager.FUSED_PROVIDER, LocationManager.GPS_PROVIDER, LocationManager.NETWORK_PROVIDER)
            .mapNotNull { p -> try { lm.getLastKnownLocation(p) } catch (e: Exception) { null } }
            .filter { System.currentTimeMillis() - it.time < 15 * 60 * 1000 }
            .minByOrNull { it.accuracy }

        val background = context.checkSelfPermission(Manifest.permission.ACCESS_BACKGROUND_LOCATION) ==
            PackageManager.PERMISSION_GRANTED
        if (!background) {
            // Without the background permission, fall back to the last known
            // location (often inaccurate).
            store(try { lastKnown() } catch (e: Exception) { null }, false)
            return
        }
        try {
            val signal = CancellationSignal()
            main.postDelayed({
                signal.cancel()
                store(lastKnown(), false)
            }, 8000)
            lm.getCurrentLocation(LocationManager.FUSED_PROVIDER, signal, executor) { location ->
                main.post { store(location ?: lastKnown(), location != null) }
            }
        } catch (e: Exception) {
            store(try { lastKnown() } catch (e2: Exception) { null }, false)
        }
    }

    companion object {
        const val PREFS = "libreglide_native"
        const val KEY_ENABLED = "parking_enabled"
        const val KEY_LAT = "parked_lat"
        const val KEY_LON = "parked_lon"
        const val KEY_ACCURACY = "parked_accuracy"
        const val KEY_TS = "parked_ts"
        const val KEY_PRECISE = "parked_precise"

        /** Forgets the saved parking spot (every key, so nothing stale is left). */
        fun clear(context: Context) {
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
                .remove(KEY_LAT).remove(KEY_LON).remove(KEY_ACCURACY).remove(KEY_TS).remove(KEY_PRECISE)
                .apply()
        }
    }
}
