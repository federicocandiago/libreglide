# libreGLIDE

Launcher Android **contestuale**, open source e **local-only**, scritto in Flutter con un sottile strato nativo in Kotlin. La home cambia con l'ora del giorno, il luogo (casa, lavoro, in viaggio), l'auto e la musica, e impara dalle tue abitudini. Tutto resta sul telefono.

*English summary below.*

> Versione **1.0.1**. Provato su Pixel 7 con Android 17; funziona da Android 12 in su.

## Cosa fa

- **Quattro pagine** con swipe orizzontale: **Space ← Home → Collections → A-Z**. Il tasto Home riporta sempre alla Home.
- **Space:** la pagina del momento. In cima la data sopra lo sfondo, con lo Space corrente (Risveglio, Mattina, Sera, Notte, Casa, Lavoro/Scuola, In movimento, In ascolto, In viaggio…). Sotto, le app più probabili adesso e le card, in ordine di importanza per il contesto:
  - Agenda e Prossima destinazione;
  - In ascolto, In auto, Dove ho parcheggiato;
  - In viaggio, Meteo, Buonanotte, Tempo di utilizzo;
  - widget Android.

  Ogni momento ha il suo contenuto: azioni rapide (Sveglia, Nuovo evento, Timer, Dove mangiare…), card in primo piano e una riga di app di una categoria (Notizie al risveglio, Cibo a pranzo, Video la sera). La sera il meteo mostra domani. Le card che tocchi spesso in un contesto salgono e compaiono anche dove non erano previste; tenendo premuta una card si sceglie "Mostra sempre" o "Nascondi" in quello Space. Il cassetto laterale permette di scegliere uno Space a mano.
- **Home:** lo sfondo incorniciato da barra e dock, fino a 3 widget Android a tutta larghezza e un dock da 4 posti. Le app del dock si riordinano tenendole premute e trascinandole. Il dock può essere un vassoio pieno o trasparente, e gli angoli della cornice si possono spegnere. Pressione lunga sullo sfondo per aggiungere e modificare i widget.
- **Collections:** una card per categoria con le app più probabili *adesso*, espandibile. Le card si possono fissare o nascondere.
- **A-Z:** griglia o lista, ricerca senza accenti, barra delle lettere.
- **Ricerca globale** (swipe in su) con 4 o 8 app suggerite e apertura automatica se c'è un solo risultato. **Contatti** (swipe in giù): un tocco apre il compositore con il numero, una pressione lunga dà chiama, messaggio e scheda. I gesti sono configurabili.
- **Previsione locale:** Naive Bayes con contatori che decadono nel tempo (abitudine su 30 giorni, slancio su 6 ore). Usa come segnali fascia oraria, tipo di giorno, rete, uscita audio, luogo e movimento. Con l'accesso ai dati di utilizzo impara anche dalle app aperte fuori da libreGLIDE (notifiche, recenti, link), a partire dalle ultime due settimane; si può spegnere. Una schermata di diagnostica spiega le scelte.
- **Luoghi senza nomi da inserire:** casa e lavoro vengono riconosciuti in automatico (sonno, permanenza nei giorni feriali, Wi-Fi in hash) e si possono correggere.
- **Digital detox:** blocca le app che scegli, tutto il giorno o in una fascia oraria:
  - un PIN da 8 a 16 caratteri, salvato solo come hash;
  - sblocco con il PIN oppure mai;
  - opzione per nascondere le app bloccate;
  - una schermata di blocco nera.

  Usa un servizio di accessibilità che riceve **solo** il nome dell'app in primo piano.
- **Aspetto Material You:** colori di sistema o 8 colori predefiniti, 5 stili di palette, contrasto, tema chiaro/scuro/automatico, icone a tema, carattere di sistema (Google Sans Flex dove c'è). In più, un **vetro smerigliato** facoltativo: Space, Collections e A-Z semitrasparenti sopra lo sfondo sfocato da Android.
- **Sfondo contestuale** facoltativo da Unsplash (con una tua chiave), scelto in base a momento e meteo, visibile solo dentro libreGLIDE.
- **Lingue:** italiano, inglese, spagnolo, tedesco e francese. L'informativa sulla privacy è in italiano e in inglese.

## Privacy

Informativa completa: [docs/PRIVACY.md](docs/PRIVACY.md), visibile anche nell'app (onboarding e Impostazioni → Informazioni).

- Nessun account, nessuna pubblicità, nessuna telemetria.
- **Connessioni facoltative:** solo lo sfondo Unsplash (con una chiave inserita da te) e la card Meteo (Open-Meteo, posizione arrotondata). Tutto il codice di rete è in `lib/net/`.
- **Permessi:** ogni permesso è facoltativo e chiesto dalla funzione che lo usa. La posizione in background serve solo a "Dove ho parcheggiato", che è spento di default.
- **Backup:** lo storico delle aperture è in SQLite, viene cancellato dopo 180 giorni ed è escluso dal backup cloud.
- **Cancellazione:** si può cancellare tutto dalle impostazioni.

## Installare

Scarica l'APK dall'ultima [release](https://github.com/federicocandiago/libreglide/releases). Poi apri libreGLIDE e impostalo come app Home. Serve Android 12 o successivo.

## Compilare

Servono Flutter 3.47+, JDK 17 e l'SDK di Android con la piattaforma 37 (Android 17). `minSdk` è 31.

```sh
flutter pub get
flutter test
flutter build apk --release --target-platform android-arm64
```

Senza `android/key.properties` la release viene firmata con la chiave di debug.

Per i comandi di sviluppo (aprire una schermata senza toccare il telefono):

```sh
adb shell am start -n org.libreglide.launcher/.MainActivity --es open settings
```

## Struttura

```
lib/
  core/        logica pura in Dart, testabile senza dispositivo
               (contesto, previsione, Collections, luoghi, Space, ricerca, detox…)
  data/        impostazioni (shared_preferences) e storico (SQLite)
  net/         l'unico codice di rete (Unsplash, Open-Meteo)
  platform/    lato Dart del bridge con Kotlin
  state/       controller (app, card, luoghi, meteo, sfondo)
  theme/       palette Material You e carattere di sistema
  ui/          pagine e widget (stile Glide in ui/glide_style.dart)
  legal/       informativa sulla privacy
  l10n/        traduzioni (ARB)
android/app/src/main/kotlin/org/libreglide/launcher/
  MainActivity.kt, LibreGlideApplication.kt   activity Home ed engine sempre caldo
  LauncherBridge.kt                            app, icone, permessi, contesto, widget
  Detox*.kt                                    Digital detox (servizio e schermata di blocco)
  ParkingReceiver.kt, MediaWatcher.kt          parcheggio e musica
test/core/                                     test del nucleo
docs/                                          specifiche e informativa
```

## Licenza

[GNU General Public License v3.0](LICENSE) o successiva.

Dati meteo di [Open-Meteo.com](https://open-meteo.com) (CC BY 4.0). Foto di [Unsplash](https://unsplash.com), con il credito all'autore mostrato nell'app. Le licenze delle librerie sono in Impostazioni → Informazioni → Licenze open source.

---

## English

libreGLIDE is an open source, **local-only**, context-aware Android launcher built with Flutter and a thin Kotlin layer.

- **Context:** the home adapts to the time of day, your places (home and work are recognized automatically), driving, music and travel.
- **Habits:** it learns which apps you use with an on-device Naive Bayes predictor.
- **Pages:** Space (cards and suggestions for the moment), Home (wallpaper, widgets, dock), Collections (apps by category, sorted for now) and A-Z.
- **Digital detox:** locks chosen apps on a schedule, with a PIN.
- **No tracking:** no accounts, ads or telemetry.
- **Optional network:** only Unsplash wallpapers (with your own key) and Open-Meteo weather.

UI in Italian, English, Spanish, German and French. Licensed under the GPL-3.0-or-later.
