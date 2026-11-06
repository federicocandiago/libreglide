package org.libreglide.launcher

import android.app.Activity
import android.content.ComponentName
import android.content.Intent
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.Bundle
import android.text.InputFilter
import android.text.InputType
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.view.ViewGroup.LayoutParams.MATCH_PARENT
import android.view.ViewGroup.LayoutParams.WRAP_CONTENT
import android.view.WindowInsets
import android.view.inputmethod.EditorInfo
import android.widget.Button
import android.widget.EditText
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import android.window.OnBackInvokedDispatcher
import java.util.Locale

/**
 * Schermata di blocco di Digital detox: nera, a tutto schermo, semplice.
 * Ombrellone e sole, "App bloccata", il PIN se lo sblocco è permesso e
 * "Torna alla Home". È nativa per comparire subito, senza avviare Flutter.
 */
class DetoxLockActivity : Activity() {

    companion object {
        const val EXTRA_PACKAGE = "package"
        const val EXTRA_TARGET = "target"
    }

    private var lockedPackage: String? = null
    private var target: String? = null

    private lateinit var body: TextView
    private lateinit var pinField: EditText
    private lateinit var unlockButton: Button
    private lateinit var message: TextView

    private val density by lazy { resources.displayMetrics.density }
    private fun dp(v: Int) = (v * density).toInt()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(buildUi())
        if (Build.VERSION.SDK_INT >= 33) {
            onBackInvokedDispatcher.registerOnBackInvokedCallback(OnBackInvokedDispatcher.PRIORITY_DEFAULT) {
                goHome()
            }
        }
        bind(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        bind(intent)
    }

    @Deprecated("Solo per Android 12: dal 13 c'è OnBackInvokedDispatcher.")
    override fun onBackPressed() = goHome()

    override fun onStop() {
        super.onStop()
        // Lasciata in qualunque modo: non resta appesa in background.
        if (!isChangingConfigurations) finish()
    }

    override fun onDestroy() {
        if (Detox.showingFor == lockedPackage) Detox.showingFor = null
        super.onDestroy()
    }

    private fun bind(intent: Intent) {
        lockedPackage = intent.getStringExtra(EXTRA_PACKAGE)
        target = intent.getStringExtra(EXTRA_TARGET)
        val label = lockedPackage?.let { pkg ->
            try {
                packageManager.getApplicationLabel(packageManager.getApplicationInfo(pkg, 0)).toString()
            } catch (e: Exception) {
                pkg
            }
        } ?: ""
        val until = Detox.endMinutes(this)?.let {
            "\n" + getString(R.string.detox_locked_until, String.format(Locale.ROOT, "%02d:%02d", it / 60, it % 60))
        } ?: ""
        body.text = getString(R.string.detox_locked_body, label) + until
        val unlockable = Detox.unlockable(this)
        pinField.visibility = if (unlockable) View.VISIBLE else View.GONE
        unlockButton.visibility = if (unlockable) View.VISIBLE else View.GONE
        pinField.text.clear()
        message.text = ""
    }

    private fun unlock() {
        val pin = pinField.text.toString()
        if (pin.isEmpty()) return
        val pkg = lockedPackage ?: return
        unlockButton.isEnabled = false
        // L'hash del PIN richiede qualche decina di millisecondi: fuori dal
        // thread principale.
        Thread {
            val result = Detox.checkPin(this, pin)
            runOnUiThread {
                unlockButton.isEnabled = true
                when {
                    result == 0L -> {
                        Detox.unlockedPackage = pkg
                        target?.let(ComponentName::unflattenFromString)?.let { component ->
                            try {
                                startActivity(
                                    Intent(Intent.ACTION_MAIN)
                                        .addCategory(Intent.CATEGORY_LAUNCHER)
                                        .setComponent(component)
                                        .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_RESET_TASK_IF_NEEDED),
                                )
                            } catch (e: Exception) {
                                // L'app non c'è più: si chiude e basta.
                            }
                        }
                        finish()
                    }
                    result < 0 -> {
                        pinField.text.clear()
                        message.text = getString(R.string.detox_wrong_pin)
                    }
                    else -> {
                        pinField.text.clear()
                        message.text = getString(R.string.detox_wait, ((result + 999) / 1000).toInt())
                    }
                }
            }
        }.start()
    }

    private fun goHome() {
        try {
            startActivity(
                Intent(Intent.ACTION_MAIN)
                    .addCategory(Intent.CATEGORY_HOME)
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
            )
        } catch (e: Exception) {
            // Nessuna Home: si chiude soltanto.
        }
        finish()
    }

    // region Interfaccia
    private fun buildUi(): View {
        val muted = Color.argb(0xB3, 0xFF, 0xFF, 0xFF)
        val column = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_HORIZONTAL or Gravity.CENTER_VERTICAL
            setPadding(dp(32), dp(24), dp(32), dp(24))
        }
        column.addView(
            ImageView(this).apply {
                setImageResource(R.drawable.detox_umbrella)
                contentDescription = null
            },
            LinearLayout.LayoutParams(dp(200), dp(160)).apply { bottomMargin = dp(36) },
        )
        column.addView(
            TextView(this).apply {
                text = getString(R.string.detox_locked_title)
                setTextColor(Color.WHITE)
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 28f)
                typeface = Typeface.create("sans-serif", Typeface.NORMAL)
                gravity = Gravity.CENTER
            },
            LinearLayout.LayoutParams(MATCH_PARENT, WRAP_CONTENT),
        )
        body = TextView(this).apply {
            setTextColor(muted)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 16f)
            setLineSpacing(0f, 1.25f)
            gravity = Gravity.CENTER
        }
        column.addView(
            body,
            LinearLayout.LayoutParams(MATCH_PARENT, WRAP_CONTENT).apply { topMargin = dp(12); bottomMargin = dp(36) },
        )
        pinField = EditText(this).apply {
            hint = getString(R.string.detox_pin_hint)
            setHintTextColor(Color.argb(0x66, 0xFF, 0xFF, 0xFF))
            setTextColor(Color.WHITE)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 20f)
            gravity = Gravity.CENTER
            inputType = InputType.TYPE_CLASS_TEXT or InputType.TYPE_TEXT_VARIATION_PASSWORD
            filters = arrayOf(InputFilter.LengthFilter(16))
            imeOptions = EditorInfo.IME_ACTION_DONE
            isSingleLine = true
            background = GradientDrawable().apply {
                cornerRadius = dp(16).toFloat()
                setStroke(dp(1), Color.argb(0x55, 0xFF, 0xFF, 0xFF))
            }
            setPadding(dp(16), dp(14), dp(16), dp(14))
            setOnEditorActionListener { _, action, _ ->
                if (action == EditorInfo.IME_ACTION_DONE) {
                    unlock()
                    true
                } else {
                    false
                }
            }
        }
        column.addView(pinField, LinearLayout.LayoutParams(MATCH_PARENT, WRAP_CONTENT))
        message = TextView(this).apply {
            setTextColor(Color.rgb(0xFF, 0xB4, 0xAB))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 14f)
            gravity = Gravity.CENTER
        }
        column.addView(
            message,
            LinearLayout.LayoutParams(MATCH_PARENT, WRAP_CONTENT).apply { topMargin = dp(8); bottomMargin = dp(8) },
        )
        unlockButton = pill(getString(R.string.detox_unlock), filled = false) { unlock() }
        column.addView(unlockButton, LinearLayout.LayoutParams(MATCH_PARENT, dp(52)).apply { bottomMargin = dp(12) })
        column.addView(
            pill(getString(R.string.detox_home), filled = true) { goHome() },
            LinearLayout.LayoutParams(MATCH_PARENT, dp(52)),
        )

        return ScrollView(this).apply {
            isFillViewport = true
            setBackgroundColor(Color.BLACK)
            addView(column, MATCH_PARENT, WRAP_CONTENT)
            setOnApplyWindowInsetsListener { v, insets ->
                val bars = insets.getInsets(WindowInsets.Type.systemBars() or WindowInsets.Type.ime())
                v.setPadding(bars.left, bars.top, bars.right, bars.bottom)
                WindowInsets.CONSUMED
            }
        }
    }

    private fun pill(label: String, filled: Boolean, onClick: () -> Unit) = Button(this).apply {
        text = label
        isAllCaps = false
        stateListAnimator = null
        setTextSize(TypedValue.COMPLEX_UNIT_SP, 16f)
        typeface = Typeface.create("sans-serif-medium", Typeface.NORMAL)
        setTextColor(if (filled) Color.BLACK else Color.WHITE)
        background = GradientDrawable().apply {
            cornerRadius = dp(26).toFloat()
            if (filled) {
                setColor(Color.WHITE)
            } else {
                setColor(Color.TRANSPARENT)
                setStroke(dp(1), Color.argb(0x88, 0xFF, 0xFF, 0xFF))
            }
        }
        setOnClickListener { onClick() }
    }
    // endregion
}
