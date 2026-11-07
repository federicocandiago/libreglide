package org.libreglide.launcher

import android.service.notification.NotificationListenerService

/**
 * Empty service: it exists only because Android grants access to media
 * sessions (MediaSessionManager.getActiveSessions) to apps that have an
 * enabled NotificationListenerService.
 *
 * libreGLIDE does not read, store or send notifications: this class overrides
 * neither onNotificationPosted nor any other method.
 */
class MediaListenerService : NotificationListenerService()
