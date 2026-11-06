package org.libreglide.launcher

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.SystemClock
import android.provider.Settings
import android.util.Base64
import java.security.MessageDigest
import java.security.SecureRandom
import java.util.Calendar
import javax.crypto.SecretKeyFactory
import javax.crypto.spec.PBEKeySpec

/**
 * Digital detox: quali app sono bloccate e quando, e il PIN.
 *
 * La configurazione la scrive Flutter ([sync]); il PIN invece non passa mai
 * per Flutter in chiaro più del necessario e qui se ne salva solo l'hash
 * (PBKDF2 con un sale casuale). Tutto resta nel telefono.
 */
object Detox {
    private const val PREFS = "libreglide_detox"
    private const val ITERATIONS = 60_000

    /** App sbloccata con il PIN: resta libera finché l'utente non la lascia. */
    @Volatile
    var unlockedPackage: String? = null

    /** Pacchetto per cui la schermata di blocco è visibile adesso. */
    @Volatile
    var showingFor: String? = null

    private fun prefs(context: Context): SharedPreferences =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    fun sync(context: Context, config: Map<String, Any?>) {
        prefs(context).edit()
            .putBoolean("enabled", config["enabled"] == true)
            .putBoolean("allDay", config["allDay"] != false)
            .putInt("start", (config["start"] as? Number)?.toInt() ?: (22 * 60))
            .putInt("end", (config["end"] as? Number)?.toInt() ?: (7 * 60))
            .putBoolean("unlockable", config["unlockable"] != false)
            .putStringSet("packages", (config["packages"] as? List<*>)?.mapNotNull { it as? String }?.toSet() ?: emptySet())
            .apply()
        if (config["enabled"] != true) unlockedPackage = null
    }

    fun unlockable(context: Context): Boolean = prefs(context).getBoolean("unlockable", true)

    /** Minuti dall'inizio del giorno in cui il detox finisce, o null se è tutto il giorno. */
    fun endMinutes(context: Context): Int? {
        val p = prefs(context)
        return if (p.getBoolean("allDay", true)) null else p.getInt("end", 7 * 60)
    }

    /** Il blocco è attivo adesso (acceso e dentro l'orario). */
    fun activeNow(context: Context): Boolean {
        val p = prefs(context)
        if (!p.getBoolean("enabled", false) || !hasPin(context)) return false
        if (p.getBoolean("allDay", true)) return true
        val now = Calendar.getInstance().let { it.get(Calendar.HOUR_OF_DAY) * 60 + it.get(Calendar.MINUTE) }
        val start = p.getInt("start", 22 * 60)
        val end = p.getInt("end", 7 * 60)
        return when {
            start == end -> true
            start < end -> now in start until end
            else -> now >= start || now < end // a cavallo della mezzanotte
        }
    }

    fun isLockedNow(context: Context, packageName: String): Boolean =
        packageName != context.packageName &&
            prefs(context).getStringSet("packages", emptySet())!!.contains(packageName) &&
            activeNow(context)

    /** Mostra la schermata di blocco; [target] è l'activity da aprire dopo lo sblocco. */
    fun showLock(context: Context, packageName: String, target: ComponentName? = null) {
        showingFor = packageName
        context.startActivity(
            Intent(context, DetoxLockActivity::class.java)
                .putExtra(DetoxLockActivity.EXTRA_PACKAGE, packageName)
                .putExtra(DetoxLockActivity.EXTRA_TARGET, target?.flattenToString())
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_NO_ANIMATION),
        )
    }

    fun serviceEnabled(context: Context): Boolean {
        val mine = ComponentName(context, DetoxService::class.java)
        val enabled = Settings.Secure.getString(context.contentResolver, Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES)
            ?: return false
        return enabled.split(':').any { ComponentName.unflattenFromString(it) == mine }
    }

    // region PIN
    fun hasPin(context: Context): Boolean = prefs(context).contains("pinHash")

    fun setPin(context: Context, pin: String) {
        val salt = ByteArray(16).also { SecureRandom().nextBytes(it) }
        prefs(context).edit()
            .putString("pinSalt", Base64.encodeToString(salt, Base64.NO_WRAP))
            .putString("pinHash", Base64.encodeToString(hash(pin, salt), Base64.NO_WRAP))
            .putInt("fails", 0)
            .putLong("lockedUntil", 0)
            .apply()
    }

    fun clearPin(context: Context) {
        prefs(context).edit().remove("pinHash").remove("pinSalt").apply()
    }

    /**
     * Verifica il PIN. Restituisce 0 se è giusto, -1 se è sbagliato, oppure i
     * millisecondi da aspettare dopo troppi tentativi sbagliati.
     */
    fun checkPin(context: Context, pin: String): Long {
        val p = prefs(context)
        val wait = p.getLong("lockedUntil", 0) - SystemClock.elapsedRealtime()
        // Dopo un riavvio il contatore del tempo riparte: si ignora un'attesa
        // più lunga del massimo.
        if (wait in 1..MAX_WAIT) return wait
        val salt = Base64.decode(p.getString("pinSalt", null) ?: return -1, Base64.NO_WRAP)
        val expected = Base64.decode(p.getString("pinHash", null) ?: return -1, Base64.NO_WRAP)
        if (MessageDigest.isEqual(hash(pin, salt), expected)) {
            p.edit().putInt("fails", 0).putLong("lockedUntil", 0).apply()
            return 0
        }
        val fails = p.getInt("fails", 0) + 1
        val edit = p.edit().putInt("fails", fails)
        if (fails >= 5) {
            // 30 secondi, poi il doppio a ogni errore (al massimo un'ora).
            val delay = minOf(30_000L shl minOf(fails - 5, 7), MAX_WAIT)
            edit.putLong("lockedUntil", SystemClock.elapsedRealtime() + delay)
            edit.apply()
            return delay
        }
        edit.apply()
        return -1
    }

    private const val MAX_WAIT = 60 * 60 * 1000L

    private fun hash(pin: String, salt: ByteArray): ByteArray {
        val spec = PBEKeySpec(pin.toCharArray(), salt, ITERATIONS, 256)
        return try {
            SecretKeyFactory.getInstance("PBKDF2WithHmacSHA256").generateSecret(spec).encoded
        } finally {
            spec.clearPassword()
        }
    }
    // endregion

    /**
     * App di sistema delicate che si possono bloccare anche se non hanno
     * un'icona: installazione e disinstallazione, Impostazioni, Play Store.
     */
    val SENSITIVE_PACKAGES = listOf(
        "com.android.settings",
        "com.google.android.packageinstaller",
        "com.android.packageinstaller",
        "com.android.vending",
    )
}
