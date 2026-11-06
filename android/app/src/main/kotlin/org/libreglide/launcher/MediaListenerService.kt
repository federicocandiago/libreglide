package org.libreglide.launcher

import android.service.notification.NotificationListenerService

/**
 * Servizio vuoto: esiste solo perché Android concede l'accesso alle sessioni
 * multimediali (MediaSessionManager.getActiveSessions) alle app che hanno un
 * NotificationListenerService abilitato.
 *
 * libreGLIDE non legge, non conserva e non invia le notifiche: questa classe
 * non sovrascrive onNotificationPosted né altri metodi.
 */
class MediaListenerService : NotificationListenerService()
