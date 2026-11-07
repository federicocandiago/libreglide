package org.libreglide.launcher

import android.app.NotificationManager
import android.content.ComponentName
import android.content.Context
import android.graphics.Bitmap
import android.media.MediaMetadata
import android.media.session.MediaController
import android.media.session.MediaSessionManager
import android.media.session.PlaybackState
import android.os.Handler
import android.os.Looper
import java.io.ByteArrayOutputStream

/**
 * Tracks the music being played (media sessions) and controls it.
 * Works only if the user granted notification access to
 * [MediaListenerService]; of that access, only media sessions are used.
 */
class MediaWatcher(private val context: Context, private val onChange: () -> Unit) {

    private val sessions = context.getSystemService(MediaSessionManager::class.java)
    private val component = ComponentName(context, MediaListenerService::class.java)
    private val main = Handler(Looper.getMainLooper())
    private var started = false
    private var controllers: List<MediaController> = emptyList()
    private var lastArtId: Int? = null

    private val controllerCallback = object : MediaController.Callback() {
        override fun onPlaybackStateChanged(state: PlaybackState?) = onChange()
        override fun onMetadataChanged(metadata: MediaMetadata?) = onChange()
        override fun onSessionDestroyed() = onChange()
    }

    private val sessionsListener = MediaSessionManager.OnActiveSessionsChangedListener { list ->
        bind(list ?: emptyList())
        onChange()
    }

    /** Whether the user granted notification access to libreGLIDE. */
    fun hasAccess(): Boolean =
        context.getSystemService(NotificationManager::class.java).isNotificationListenerAccessGranted(component)

    /** Starts listening if access is granted and it isn't already running. */
    fun startIfPossible() {
        if (started || !hasAccess()) return
        try {
            sessions.addOnActiveSessionsChangedListener(sessionsListener, component, main)
            bind(sessions.getActiveSessions(component))
            started = true
        } catch (e: SecurityException) {
            started = false
        }
    }

    fun stop() {
        if (!started) return
        sessions.removeOnActiveSessionsChangedListener(sessionsListener)
        controllers.forEach { it.unregisterCallback(controllerCallback) }
        controllers = emptyList()
        started = false
    }

    private fun bind(list: List<MediaController>) {
        controllers.forEach { it.unregisterCallback(controllerCallback) }
        controllers = list
        controllers.forEach { it.registerCallback(controllerCallback, main) }
    }

    /** The session to show: the playing one, otherwise the first with metadata. */
    private fun current(): MediaController? =
        controllers.firstOrNull { it.playbackState?.state == PlaybackState.STATE_PLAYING }
            ?: controllers.firstOrNull { it.metadata != null }

    /** Current state, or null if there is nothing to show. */
    fun snapshot(artSizePx: Int): Map<String, Any?>? {
        val data = snapshotOrNull(artSizePx)
        // Nothing to show: the artwork must be sent again for the next session.
        if (data == null) lastArtId = null
        return data
    }

    private fun snapshotOrNull(artSizePx: Int): Map<String, Any?>? {
        if (!started) return null
        val controller = current() ?: return null
        val metadata = controller.metadata ?: return null
        val title = metadata.getString(MediaMetadata.METADATA_KEY_DISPLAY_TITLE)
            ?: metadata.getString(MediaMetadata.METADATA_KEY_TITLE)
            ?: return null
        val artist = metadata.getString(MediaMetadata.METADATA_KEY_ARTIST)
            ?: metadata.getString(MediaMetadata.METADATA_KEY_ALBUM_ARTIST)
            ?: metadata.getString(MediaMetadata.METADATA_KEY_DISPLAY_SUBTITLE)
        val art = metadata.getBitmap(MediaMetadata.METADATA_KEY_ALBUM_ART)
            ?: metadata.getBitmap(MediaMetadata.METADATA_KEY_ART)
            ?: metadata.getBitmap(MediaMetadata.METADATA_KEY_DISPLAY_ICON)
        // The artwork is re-encoded and sent only when it changes: player
        // events are frequent, artwork changes are rare.
        val artId = art?.let { System.identityHashCode(it) * 31 + it.generationId }
        val artSame = artId != null && artId == lastArtId
        if (!artSame) lastArtId = artId
        val actions = controller.playbackState?.actions ?: 0L
        return mapOf(
            "title" to title,
            "artist" to artist,
            "package" to controller.packageName,
            "playing" to (controller.playbackState?.state == PlaybackState.STATE_PLAYING),
            "canPrevious" to (actions and PlaybackState.ACTION_SKIP_TO_PREVIOUS != 0L),
            "canNext" to (actions and PlaybackState.ACTION_SKIP_TO_NEXT != 0L),
            "art" to if (artSame) null else art?.let { scaledPng(it, artSizePx) },
            "artSame" to artSame,
        )
    }

    /** Commands: playPause, next, previous. */
    fun command(name: String): Boolean {
        val controller = current() ?: return false
        val controls = controller.transportControls
        when (name) {
            "playPause" ->
                if (controller.playbackState?.state == PlaybackState.STATE_PLAYING) controls.pause() else controls.play()
            "next" -> controls.skipToNext()
            "previous" -> controls.skipToPrevious()
            else -> return false
        }
        return true
    }

    private fun scaledPng(source: Bitmap, size: Int): ByteArray {
        val scaled = if (source.width > size || source.height > size) {
            val ratio = size.toFloat() / maxOf(source.width, source.height)
            Bitmap.createScaledBitmap(
                source,
                (source.width * ratio).toInt().coerceAtLeast(1),
                (source.height * ratio).toInt().coerceAtLeast(1),
                true,
            )
        } else {
            source
        }
        val stream = ByteArrayOutputStream()
        scaled.compress(Bitmap.CompressFormat.PNG, 100, stream)
        return stream.toByteArray()
    }
}
