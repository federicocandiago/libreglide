# libreGLIDE — Specifica tecnica del motore di contesto

> Versione 0.1 · bozza · 5 novembre 2026
> Ambito: raccolta dei segnali, riconoscimento automatico di luoghi (casa, lavoro/scuola, frequenti), calcolo del contesto corrente, previsione delle app e scelta dello Space.
> Fuori ambito: UI dei Space, gestione widget, lista app e icone (avranno specifiche proprie).

---

## 1. Principi

1. **Solo in locale.** Il motore non usa la rete. Nessun account, nessuna telemetria, nessun servizio Google. L'unica eccezione nell'app è la chiave Unsplash facoltativa, che non riguarda il motore.
2. **Nessun nome da scrivere.** L'utente non deve dare nomi ai luoghi. Casa e lavoro/scuola vengono riconosciuti in automatico, gli altri luoghi restano anonimi. Tutto si può correggere dalle impostazioni.
3. **Regole spiegabili, non machine learning.** I dati sono pochi, il calcolo avviene sul telefono e l'utente deve poter capire perché il launcher ha deciso una cosa. Ogni decisione ha un punteggio e una motivazione leggibile nella schermata di diagnostica.
4. **Minimo indispensabile.** Ogni segnale ha il suo interruttore. Senza un permesso il motore continua a funzionare con meno precisione, non si blocca.
5. **Dati grezzi sensibili protetti alla fonte.** SSID e BSSID vengono trasformati in hash nel layer Kotlin con un sale locale e non arrivano mai in chiaro né in Dart né nel database. Le coordinate grezze hanno vita breve (§9).
6. **Motore puro in Dart.** Tutta la logica di inferenza è codice Dart deterministico, senza dipendenze dalla piattaforma. Riceve campioni ed eventi e produce luoghi, contesto e previsioni, quindi si testa con tracce sintetiche senza dispositivo (§12).

---

## 2. Architettura

```
┌──────────────────────── Flutter (Dart) ────────────────────────┐
│  UI (Space, Collections, Impostazioni, Diagnostica)            │
│        ▲                                                       │
│        │ ContextState / Predictions                            │
│  ┌─────┴──────────────── Motore di contesto ───────────────┐   │
│  │ Ingestion → PlaceClusterer → DailyAggregator →          │   │
│  │ RoleInference → ContextResolver → AppPredictor →        │   │
│  │ SpaceSelector                                           │   │
│  └─────┬───────────────────────────────────────────────────┘   │
│        │ Drift (SQLite)                                        │
│  ContextBridge (MethodChannel + EventChannel)                  │
└────────┼───────────────────────────────────────────────────────┘
         │
┌────────┴──────────── Kotlin (strato nativo sottile) ───────────┐
│ SnapshotProvider · UsageEventsReader · SystemEventReceiver ·   │
│ WifiHasher · PermissionHelper                                  │
└────────────────────────────────────────────────────────────────┘
```

- **Kotlin** legge il sistema e restituisce dati già normalizzati. Non prende decisioni.
- **Dart** contiene tutto il resto.
- **Persistenza** in SQLite (`sqflite` in v0.1, eventualmente Drift quando arriveranno le tabelle dei luoghi) e backup cloud di Android disattivato per questo database (§9).

**Target:** `minSdk 31` (Android 12, il primo con Material You e dynamic color, `LocationManager.FUSED_PROVIDER`, `TransportInfo` dalle `NetworkCapabilities`). `targetSdk` = Android 17. Prima di partire vanno verificati i *behavior changes* ufficiali di Android 17 su permessi di localizzazione, Wi-Fi e Bluetooth.

---

## 3. Segnali

### 3.1 Tabella dei segnali

| Segnale | Fonte Android | Permesso | Default | Uso |
|---|---|---|---|---|
| Ora, giorno, fuso orario | `ZonedDateTime`, `ACTION_TIMEZONE_CHANGED` | nessuno | sempre | fasce orarie, viaggio |
| Posizione precisa | `LocationManager.getCurrentLocation(FUSED_PROVIDER)` con riserva su `getLastKnownLocation` | `ACCESS_FINE_LOCATION`, solo mentre l'app è in uso | richiesto all'onboarding, rifiutabile | luoghi |
| Wi-Fi connesso (hash) | `NetworkCallback` con `FLAG_INCLUDE_LOCATION_INFO`, poi `WifiInfo` | come la posizione precisa | con la posizione | luoghi (più preciso al chiuso) |
| Tipo di rete | `ConnectivityManager`, `NetworkCapabilities` | nessuno | sempre | offline, Wi-Fi a consumo (hotspot) |
| Roaming | `TelephonyManager.isNetworkRoaming` | nessuno | sempre | viaggio |
| Batteria e ricarica | sticky intent `ACTION_BATTERY_CHANGED`, `ACTION_POWER_(DIS)CONNECTED` | nessuno | sempre | sonno, casa |
| Uscita audio | `AudioManager.getDevices(GET_DEVICES_OUTPUTS)` | nessuno | sempre | cuffie, ascolto |
| Tipo di dispositivo Bluetooth | `BluetoothDevice.bluetoothClass` (autoradio, cuffie, orologio) | `BLUETOOTH_CONNECT` | facoltativo | guida, ascolto |
| Suoneria e Non disturbare | `AudioManager.ringerMode`, `NotificationManager.currentInterruptionFilter` | nessuno | sempre | contesto riunione o notte |
| Prossima sveglia | `AlarmManager.nextAlarmClock` | nessuno | sempre | risveglio |
| Calendario | `CalendarContract.Instances` | `READ_CALENDAR` | facoltativo | in riunione, evento a breve |
| Uso delle app e stato schermo | `UsageStatsManager.queryEvents` (`ACTIVITY_RESUMED`, `SCREEN_INTERACTIVE`, `SCREEN_NON_INTERACTIVE`, `KEYGUARD_HIDDEN`) | *Accesso ai dati di utilizzo* (impostazione speciale) | facoltativo, consigliato | aperture fuori dal launcher, sonno |
| Passi | sensore `TYPE_STEP_COUNTER` | `ACTIVITY_RECOGNITION` | facoltativo | in cammino |
| Profilo di lavoro | `UserManager.isQuietModeEnabled` | nessuno | sempre | contesto lavoro |
| Notifiche e media in riproduzione | `NotificationListenerService`, `MediaSessionManager` | accesso alle notifiche | **disattivato** | ascolto in corso (futuro) |

**Escluso di proposito:** location in background (`ACCESS_BACKGROUND_LOCATION`), Activity Recognition di Google Play Services, `Geocoder` (sui dispositivi Google invia le coordinate ai server), qualsiasi API di rete.

### 3.2 Quando si campiona

Il launcher torna in primo piano decine di volte al giorno, e il campionamento sfrutta questo.

- **Snapshot completo** a ogni `onResume` dell'activity home, con un limite di uno ogni 3 minuti. La posizione si richiede solo se l'ultima ha più di 5 minuti o se Wi-Fi o rete sono cambiati.
- **Eventi di sistema** (schermo acceso/spento, ricarica, cuffie, Bluetooth, fuso orario) ricevuti con receiver registrati a runtime, finché il processo del launcher è vivo, cioè quasi sempre. Vengono salvati come `system_event`, senza posizione.
- **Recupero dello storico:** a ogni snapshot si leggono da `UsageStatsManager` gli eventi successivi all'ultimo letto. Così si recuperano aperture di app e stati dello schermo anche dei periodi in cui il processo era morto.
- **Nessun job in background che chiede la posizione.** Un eventuale `WorkManager` giornaliero fa solo manutenzione: aggregati, pulizia, ricalcolo dei ruoli.

> Verifica tecnica: con `targetSdk` recente l'SSID e il BSSID si leggono solo con la posizione precisa concessa e la localizzazione di sistema attiva. Va controllato su Android 17 che questo valga anche con la sola activity in primo piano.

### 3.3 Modalità ridotte

| Permessi disponibili | Cosa funziona |
|---|---|
| Nessuna posizione | Solo contesti temporali e di sistema (fasce orarie, cuffie, ricarica, sveglia). Niente luoghi. |
| Solo posizione approssimativa | Città (§6.6) e viaggio. Casa e lavoro solo se distano più di 3 km, con confidenza ridotta. |
| Posizione precisa senza accesso ai dati di utilizzo | Tutto, ma il sonno si ricava dai buchi tra un campione e l'altro (§6.3) e le aperture vengono solo dal launcher. |
| Tutto | Precisione piena. |

---

## 4. Contratto del bridge Kotlin ↔ Dart

Canale `libreglide/context` (MethodChannel) e `libreglide/context/events` (EventChannel). Tutti i timestamp sono in millisecondi UTC, il fuso orario viaggia separato.

### 4.1 `snapshot(): Snapshot`

```jsonc
{
  "ts": 1762358400000,
  "tz": "Europe/Rome",
  "location": {                 // null se non disponibile o non concessa
    "lat": 45.4371, "lon": 12.3326,
    "accuracyM": 18.0, "ageMs": 4200, "provider": "fused",
    "precise": true
  },
  "wifi": {                     // null se non connesso o permesso mancante
    "ssidHash": "b64…", "bssidHash": "b64…", "metered": false
  },
  "network": "wifi",            // wifi | mobile | ethernet | offline
  "roaming": false,
  "battery": { "level": 0.82, "charging": true, "plug": "ac" },
  "audio": { "route": "bt", "btClass": "car" },   // speaker | wired | bt ; car | headset | speaker | watch | other
  "ringer": "normal",           // normal | vibrate | silent
  "dnd": false,
  "nextAlarmTs": 1762405200000, // null se nessuna
  "calendar": { "inEvent": false, "nextEventInMin": 45 },   // null se il permesso manca
  "workProfile": "active",      // active | paused | none
  "stepsSinceBoot": 10432       // null se il permesso manca
}
```

### 4.2 `usageEventsSince(tsExclusive): List<UsageEvent>`

```jsonc
[{ "ts": 1762358000000, "type": "app_resumed", "package": "com.example" },
 { "ts": 1762359000000, "type": "screen_off" },
 { "ts": 1762380000000, "type": "screen_on" },
 { "ts": 1762380005000, "type": "unlocked" }]
```

### 4.3 Stream `events`

Eventi `screen_on`, `screen_off`, `power_connected`, `power_disconnected`, `audio_route_changed`, `bt_connected{class}`, `bt_disconnected`, `timezone_changed`, `locale_changed`, `date_changed`.

### 4.4 Altri metodi

- `permissions(): Map<String, PermissionState>` (`granted | denied | permanently_denied | special_off`)
- `requestPermission(name)` e `openSpecialSetting(name)` (accesso ai dati di utilizzo, accesso alle notifiche)
- `resetHashSalt()` cambia il sale e quindi invalida tutti gli hash Wi-Fi. Si usa con "Cancella tutti i dati".

### 4.5 Hash del Wi-Fi

`hash = base64(HMAC-SHA256(salt, normalize(value)))` troncato a 16 byte. `salt` è di 32 byte casuali generati al primo avvio e conservati in `EncryptedSharedPreferences` o nel Keystore. Gli hash non si possono confrontare tra dispositivi diversi, e l'SSID in chiaro non esce mai da Kotlin.

---

## 5. Modello dati (Drift / SQLite)

```sql
-- Campioni di contesto (uno per snapshot). Le coordinate grezze vengono cancellate dopo 30 giorni.
CREATE TABLE sample (
  id            INTEGER PRIMARY KEY,
  ts            INTEGER NOT NULL,          -- ms UTC
  tz            TEXT    NOT NULL,
  lat           REAL, lon REAL, accuracy_m REAL, precise INTEGER,
  wifi_ssid_h   TEXT, wifi_bssid_h TEXT, wifi_metered INTEGER,
  network       TEXT NOT NULL,
  roaming       INTEGER NOT NULL,
  charging      INTEGER NOT NULL, battery_level REAL,
  audio_route   TEXT, bt_class TEXT,
  ringer        TEXT, dnd INTEGER,
  in_event      INTEGER, next_event_min INTEGER,
  place_id      INTEGER REFERENCES place(id),   -- assegnato dal clusterer, null se nessuno
  travel        INTEGER NOT NULL DEFAULT 0      -- 1 = escluso dall'apprendimento dei ruoli
);
CREATE INDEX sample_ts ON sample(ts);

-- Eventi di sistema e di utilizzo (senza posizione)
CREATE TABLE system_event (
  id INTEGER PRIMARY KEY, ts INTEGER NOT NULL, type TEXT NOT NULL, payload TEXT
);
CREATE INDEX system_event_ts ON system_event(ts, type);

-- Luoghi appresi
CREATE TABLE place (
  id            INTEGER PRIMARY KEY,
  lat           REAL NOT NULL, lon REAL NOT NULL,   -- centroide (media pesata)
  radius_m      REAL NOT NULL,
  n_samples     INTEGER NOT NULL,
  first_seen    INTEGER NOT NULL, last_seen INTEGER NOT NULL,
  role          TEXT NOT NULL DEFAULT 'none',       -- home | work | frequent | none
  role_conf     REAL NOT NULL DEFAULT 0,
  role_source   TEXT NOT NULL DEFAULT 'inferred',   -- inferred | user
  role_blocked  TEXT,                               -- es. "home" se l'utente ha detto "non è casa"
  work_label    TEXT NOT NULL DEFAULT 'auto',       -- auto | lavoro | scuola (solo etichetta)
  city          TEXT                                -- da GeoNames, facoltativo
);

-- Wi-Fi associati a un luogo
CREATE TABLE wifi_fingerprint (
  ssid_h    TEXT NOT NULL,
  bssid_h   TEXT,                 -- null = vale tutto l'SSID (reti mesh)
  place_id  INTEGER NOT NULL REFERENCES place(id),
  hits      INTEGER NOT NULL,     -- quante volte visto insieme a una posizione buona del luogo
  trusted   INTEGER NOT NULL DEFAULT 0,
  PRIMARY KEY (ssid_h, bssid_h, place_id)
);

-- Visite ricostruite (permanenze continue in un luogo)
CREATE TABLE visit (
  id INTEGER PRIMARY KEY,
  place_id INTEGER NOT NULL REFERENCES place(id),
  start_ts INTEGER NOT NULL, end_ts INTEGER NOT NULL,
  est_start_ts INTEGER NOT NULL, est_end_ts INTEGER NOT NULL,   -- con l'estensione dei buchi (§6.2)
  kind TEXT NOT NULL DEFAULT 'normal'                           -- normal | sleep
);

-- Episodi di sonno (uno per "giornata")
CREATE TABLE sleep_episode (
  day          TEXT PRIMARY KEY,          -- "2026-11-05" = giornata da mezzogiorno a mezzogiorno
  start_ts     INTEGER NOT NULL, end_ts INTEGER NOT NULL,
  source       TEXT NOT NULL,             -- usage | screen_events | sample_gap
  place_id     INTEGER REFERENCES place(id),   -- null se inizio e fine sono in luoghi diversi
  charging     INTEGER NOT NULL           -- in carica a inizio o fine
);

-- Aggregati giornalieri per luogo (base dei punteggi)
CREATE TABLE place_day (
  place_id          INTEGER NOT NULL REFERENCES place(id),
  day               TEXT NOT NULL,
  dwell_min         INTEGER NOT NULL,     -- minuti stimati nel luogo
  awake_dwell_min   INTEGER NOT NULL,     -- minuti fuori dall'episodio di sonno
  slept_here        INTEGER NOT NULL,
  charged_overnight INTEGER NOT NULL,
  first_or_last     INTEGER NOT NULL,     -- 1 se è il luogo del primo o dell'ultimo campione della giornata
  first_arrival_min INTEGER,              -- minuti dalla mezzanotte locale
  is_workday        INTEGER NOT NULL,     -- giorno feriale e non festivo
  PRIMARY KEY (place_id, day)
);

-- Aperture di app
CREATE TABLE launch_event (
  id         INTEGER PRIMARY KEY,
  ts         INTEGER NOT NULL,
  package    TEXT NOT NULL,
  source     TEXT NOT NULL,              -- launcher | usage_stats
  sample_id  INTEGER REFERENCES sample(id),   -- snapshot più vicino (±15 min), può essere null
  -- feature già discretizzate per il predittore (§7)
  f_slot TEXT, f_daytype TEXT, f_place TEXT, f_audio TEXT, f_motion TEXT
);
CREATE INDEX launch_event_pkg ON launch_event(package, ts);

-- Categorie
CREATE TABLE app_category (
  package   TEXT PRIMARY KEY,
  category  TEXT NOT NULL,
  source    TEXT NOT NULL                -- manifest | dictionary | heuristic | user
);
```

---

## 6. Riconoscimento dei luoghi

### 6.1 Clustering online (`PlaceClusterer`)

A ogni campione:

1. **Filtro qualità.** Un campione con `accuracy_m ≤ 100` e `ageMs ≤ 10 min` è *buono*. Uno tra 100 e 500 m è *debole*: serve solo per città e viaggio, non crea luoghi. Sopra i 500 m viene ignorato.
2. **Priorità al Wi-Fi.** Se `(ssid_h, bssid_h)` o `(ssid_h, *)` corrisponde a un `wifi_fingerprint` con `trusted = 1`, il campione va a quel luogo anche senza posizione.
   - Le reti `metered` (hotspot del telefono) e quelle viste in più luoghi distanti tra loro (catene, `eduroam`) non diventano mai `trusted` da sole: valgono solo insieme alla posizione.
3. **Assegnazione geografica** (solo campioni buoni). Si cerca il luogo più vicino con `distanza ≤ max(100 m, radius_m) + accuracy_m`.
   - Se c'è, il campione gli viene assegnato. Il centroide si aggiorna con una media pesata per `1/accuracy²`, e `radius_m` diventa la deviazione standard delle distanze, limitata tra 50 e 250 m.
   - Se non c'è, si crea un luogo *candidato*. Un candidato diventa luogo vero dopo almeno 3 campioni in 2 giorni diversi. Altrimenti si cancella dopo 14 giorni.
4. **Apprendimento del Wi-Fi.** Ogni campione buono assegnato al luogo P con Wi-Fi connesso incrementa `hits` per `(ssid_h, bssid_h, P)`. Dopo 3 hits in 2 giorni diversi l'impronta diventa `trusted`. Per le reti mesh, se 3 o più BSSID con lo stesso SSID sono `trusted` su P, si crea anche l'impronta `(ssid_h, *)`.
5. **Unione.** Durante la manutenzione giornaliera si uniscono due luoghi se i centroidi distano meno di 80 m, oppure se condividono un'impronta `trusted` e distano meno di 400 m (edifici grandi, università).

### 6.2 Ricostruzione delle visite

Si ordinano per tempo i campioni assegnati.

- Una **visita** è una sequenza di campioni consecutivi nello stesso luogo, separati da meno di 4 ore e senza campioni in altri luoghi in mezzo.
- **Durata stimata.** Il campionamento è sparso, quindi la visita si allarga verso i campioni adiacenti: `est_start = start − min(½ · buco_precedente, 60 min)`, e lo stesso per `est_end`. Se il campione adiacente è nello stesso luogo, la visita si estende fino a quel campione.
- Una visita che contiene un episodio di sonno (§6.3) diventa `kind = sleep`.

### 6.3 Episodi di sonno (`SleepDetector`)

Per ogni giornata, da mezzogiorno a mezzogiorno, si cerca il **periodo di inattività più lungo** che dura almeno 4 ore. La fonte cambia in base a cosa è disponibile:

1. `usage`: periodo `screen_off → screen_on` più lungo dai dati di utilizzo. È la fonte più affidabile.
2. `screen_events`: lo stesso, ma dai receiver di runtime. Può avere buchi se il processo è morto.
3. `sample_gap`: buco più lungo tra due campioni consecutivi. È la meno precisa, perché un film di 3 ore senza tornare alla home sembra un buco.

Il luogo del sonno è il luogo dell'ultimo campione prima dell'episodio, se coincide con quello del primo campione dopo. Se i due sono diversi, `place_id = null` e l'episodio non conta per nessun luogo.

`charging = 1` se il telefono è in carica nell'ultimo campione prima o nel primo dopo, oppure se c'è un `power_connected` entro 60 minuti dall'inizio.

Basarsi sull'episodio di sonno invece che su orari fissi (22–06) fa funzionare il riconoscimento anche per chi lavora di notte o dorme a orari insoliti.

### 6.4 Aggregati giornalieri

Il `DailyAggregator` gira durante la manutenzione, oppure in modo pigro al primo snapshot dopo le 04:00, e riempie `place_day` per le giornate concluse.

- `dwell_min` è la somma delle visite stimate nella giornata. `awake_dwell_min` è la stessa cosa escluso l'episodio di sonno.
- `is_workday` vale 1 se è lunedì–venerdì e non festivo.
  - I festivi nazionali sono calcolati in locale per paese, partendo dalla lingua o dal fuso orario: per l'Italia le date fisse più Pasqua e Pasquetta.
  - Facoltativamente si leggono anche i festivi da un calendario "Festività" se l'utente ha concesso il calendario.
- I giorni con `travel = 1` (§6.7) vengono saltati.

### 6.5 Inferenza dei ruoli (`RoleInference`)

**Finestra e decadimento.** Si guardano gli ultimi 28 giorni. Il giorno di età *a* pesa `w(a) = 0.5^(a/14)`. Tutte le "quote" qui sotto sono medie pesate con `w`.

#### Casa

Per ogni luogo P con almeno 2 episodi di sonno nella finestra:

```
sleep_share(P)   = Σ w · [slept_here]         / Σ w · [episodio con luogo noto]
charge_share(P)  = Σ w · [charged_overnight]  / Σ w · [slept_here]          (0 se nessun sonno)
edge_share(P)    = Σ w · [first_or_last]      / Σ w · [giorni osservati]

home_score(P) = 0.60 · sleep_share + 0.20 · charge_share + 0.20 · edge_share
evidence(P)   = min(1, notti_dormite_qui_ultimi_14g / 4)
home_conf(P)  = sigmoid(10 · (home_score − 0.5)) · evidence
```

Il ruolo `home` va al luogo con `home_conf` più alta, se è almeno 0.6, se il luogo ha almeno 3 notti negli ultimi 14 giorni e se `home` non compare in `role_blocked`.

#### Lavoro/Scuola

Per ogni luogo P diverso da casa, a più di 250 m da casa e senza impronte Wi-Fi in comune con casa:

```
weekday_share(P) = Σ w · awake_dwell_min[is_workday]  / Σ w · awake_dwell_min_totale[is_workday]
weekend_ratio(P) = (media dwell nei giorni non feriali) / (media dwell nei giorni feriali + ε)
regularity(P)    = 1 − min(1, devstd(first_arrival_min) / 120)       // ±2h o più vale 0
presence(P)      = giorni_feriali_con_dwell ≥ 120 min, ultimi 14g

work_score(P) = 0.50 · weekday_share + 0.20 · (1 − min(1, weekend_ratio)) + 0.30 · regularity
evidence(P)   = min(1, presence / 5)
work_conf(P)  = sigmoid(10 · (work_score − 0.45)) · evidence
```

Il ruolo `work` va al migliore, se `work_conf` è almeno 0.6 e `presence` almeno 3. Se nessun luogo passa la soglia non c'è lavoro, e va bene così: è il caso dello smart working, dei pensionati e di chi ha orari irregolari.

Per chi lavora a turni, `weekday_share` e `regularity` si possono calcolare su "giorni lavorativi personali". Questa variante è facoltativa e va valutata nei test (§12): un giorno conta come lavorativo se l'utente ha passato almeno 4 ore nel candidato più forte, e si rimuove la dipendenza da lunedì–venerdì.

#### Frequenti

Un luogo diventa `frequent` se non è casa né lavoro e ha avuto visite in almeno 3 giorni diversi negli ultimi 28. Resta senza nome. Nella UI appare come "Luogo frequente" con l'icona della sua categoria di app prevalente.

#### Stabilità (isteresi)

- Una volta assegnato un ruolo, un altro luogo lo prende solo se ha `conf ≥ conf_attuale + 0.15` per 3 valutazioni giornaliere di fila. Così un weekend fuori non sposta casa, mentre un trasloco viene recepito in 4–7 giorni.
- Un ruolo con `role_source = user` non viene mai cambiato dall'inferenza.
- I ruoli si ricalcolano una volta al giorno, non a ogni snapshot.

#### Scuola o lavoro

Con `work_label = auto` il tipo si deduce dagli orari nel luogo di lavoro (ultime 4 settimane, solo giorni feriali): ogni giorno conta come "mattina" se ci sei visto tra le 8:00 e le 13:00 e come "pomeriggio" tra le 14:30 e le 19:30. Dopo almeno 5 giorni: pomeriggi in almeno metà dei giorni → **Lavoro**; in un quarto o meno → **Scuola**; nel mezzo resta la risposta precedente (isteresi). Finché non ci sono abbastanza giorni lo Space si chiama "Lavoro/Scuola". L'utente può sempre fissare "Lavoro" o "Scuola" dalle impostazioni.

Stessa struttura, pesi diversi:
- **Lavoro:** azioni nuovo evento ed email, riga di app di lavoro, agenda e prossimo luogo in alto.
- **Scuola** (più essenziale): azioni silenzioso e timer, riga di app per lo studio, agenda (orario) in alto anche se vuota; nascosti email, prossimo luogo, musica, meteo e tempo di utilizzo (tornano se usati spesso lì o scelti con "Mostra sempre qui").

### 6.6 Città offline ("Sei a Venezia")

- Nell'app si include `cities15000` di GeoNames (CC-BY 4.0, con attribuzione nelle informazioni dell'app). Si filtra a nome, nome italiano o locale, lat, lon, paese e popolazione e si salva come tabella SQLite preindicizzata o file binario ordinato, nell'ordine di 1–3 MB.
- **Ricerca.** Si prende la città più vicina entro 30 km usando una griglia di 0,5° per indicizzarle. Se due città sono a distanze simili si sceglie la più popolosa: sotto il 20% di differenza di distanza vince la popolazione.
- Funziona anche con la sola posizione approssimativa.
- Serve solo per l'interfaccia e per riconoscere i viaggi. Non è usata per i ruoli.

### 6.7 Viaggio

`travel = 1` se vale almeno una di queste condizioni:

- `roaming = true`;
- il fuso orario è diverso da quello prevalente a casa;
- la distanza da casa supera 100 km. Se casa non è ancora nota, si confronta con la città dove l'utente sta da più giorni.

Durante il viaggio i campioni vengono salvati ma esclusi da `place_day` e dall'inferenza dei ruoli, così un hotel non diventa mai casa. Il contesto corrente diventa "In viaggio" (§8).

---

## 7. Previsione delle app (`AppPredictor`)

### 7.1 Feature discrete

Ogni apertura e il contesto corrente vengono ridotti a queste feature:

| Feature | Valori |
|---|---|
| `slot` | `risveglio` (le prime 2 ore dopo la fine del sonno) · `mattina` · `pranzo` (12–14:30) · `pomeriggio` · `sera` (dalle 19 fino a 1 ora prima del sonno abituale) · `notte` |
| `daytype` | `feriale` · `festivo` |
| `network` | `wifi` · `mobile` · `offline` |
| `place` | `home` · `work` · `frequent:<id>` · `altro` · `viaggio` · `null` |
| `audio` | `speaker` · `cuffie` · `bt_auto` |
| `motion` | `fermo` · `cammino` (passi in aumento più di 60 al minuto) · `guida` (autoradio Bluetooth connessa) |

Le soglie di `risveglio` e `sera` sono relative agli episodi di sonno abituali, cioè la mediana degli ultimi 14 giorni. Senza dati si usano 07:00 per il risveglio e 23:00 per il sonno, quindi la notte inizia alle 22:00.

### 7.2 Punteggio: frequenza, recentezza, contesto

Per ogni app si tengono contatori che decadono nel tempo, aggiornati in **O(1)** a ogni apertura senza rileggere lo storico:

- **abitudine H** (emivita 30 giorni): la frequenza;
- **slancio M** (emivita 6 ore): la recentezza;
- per ogni feature di contesto, l'abitudine dell'app con quel valore.

```
score(app | ctx) = log( (H(app) + κ·M(app)) / (H_tot + κ·M_tot) )
                 + Σ_f λ_f · log( (H(app, f = ctx_f) + α) / (H(app) + α · |V_f|) )
```

- κ = 3: un'apertura appena avvenuta vale per qualche ora come 4 aperture abituali, poi torna alla frequenza normale. Un picco di un giorno non cancella mesi di abitudini.
- α = 1. I pesi iniziali sono `λ = {slot: 1.0, place: 1.0, network: 0.8, daytype: 0.5, audio: 0.8, motion: 0.8}`.
- **O(1) senza ricalcoli:** ogni apertura al tempo t aggiunge e^{λ(t − t0)}. Al momento del calcolo si moltiplica per e^{−λ(now − t0)}. Quando l'esponente supera 500 si sposta t0 e si riscalano i contatori, cosa che succede raramente.
- **App ammesse:** almeno 3 aperture, oppure usate nelle ultime ore (M ≥ 0,5).
- **All'avvio** i contatori si ricostruiscono dallo storico in un solo passaggio.
- **Costo:** un'apertura vale qualche somma. Un calcolo dei suggerimenti vale circa |app| × |feature| operazioni, cioè microsecondi.
- **Diagnostica:** la spiegazione include il fattore `recency` oltre alle feature.

**Output:**
- le N app migliori per lo Space corrente;
- le N app della ricerca globale (contesto reale, completate con le più usate in assoluto e poi con il dock);
- l'ordinamento dei risultati di ricerca a parità di corrispondenza;
- l'ordine delle app nelle Collections;
- una spiegazione leggibile nella diagnostica.

**Feature attive in v0.2:** `slot`, `daytype`, `network` (wifi, mobile, offline) e `audio` (speaker, headphones, bt). Rete e audio si leggono senza permessi. `place` e `motion` arriveranno con M1.

### 7.3 Categorie

L'ordine di priorità per assegnare la categoria a un'app è:

1. `user`: scelta dall'utente.
2. `dictionary`: dizionario offline incluso nell'app, pacchetto→categoria, da costruire partendo dai metadati di F-Droid e da una lista curata delle app più diffuse. Viene prima del manifest perché è più specifico: WhatsApp nel manifest è "Social", per noi è "Messaggi".
3. `manifest`: `ApplicationInfo.category`. Copre poche categorie e molte app non la dichiarano.
4. `heuristic`: parole chiave nel nome del pacchetto o nell'etichetta (`bank`, `music`, `maps`…).
5. Se nessuna fonte risponde, la categoria è "Altro".

Le categorie si allineano a quelle di Android estese: Social, Messaggi, Musica e audio, Video, Foto, News, Mappe e viaggio, Produttività, Lavoro, Studio, Finanza, Shopping, Cibo, Salute e sport, Giochi, Strumenti, Sistema.

---

## 8. Contesto corrente e scelta dello Space

### 8.1 `ContextResolver`

A ogni snapshot, e a ogni evento rilevante come le cuffie collegate o la ricarica, si produce un `ContextState`:

```dart
class ContextState {
  final DateTime now;
  final Slot slot;
  final DayType dayType;
  final PlaceRef? place;      // ruolo + id + confidenza
  final String? city;
  final bool travel;
  final Motion motion;
  final AudioRoute audio;
  final bool charging;
  final bool inEvent;
  final int? nextEventInMin;
  final Duration? untilNextAlarm;
  final bool justWokeUp;      // primo sblocco dopo l'episodio di sonno, entro 2h
}
```

### 8.2 `SpaceSelector`

Si valutano le regole in ordine di priorità e vince la prima che è vera. L'utente può sempre cambiare Space a mano, e la scelta manuale resta finché il contesto cambia di nuovo. Uno Space scelto a mano vale come la sua situazione: luogo (Casa, Lavoro), fascia oraria o attività (auto, allenamento, cuffie, viaggio, serata fuori). La pagina e le app suggerite si calcolano da quella; restano reali solo i dati veri (musica, agenda, posizione dell'auto, ora di casa in viaggio).

| # | Space | Condizione |
|---|---|---|
| 1 | **In movimento** (auto) | Android Auto o autoradio Bluetooth collegata |
| 2 | **Attività fisica** | contapassi di sistema, letto a ogni ritorno sul launcher: cadenza media ≥ 115 passi/min su una finestra di 3–45 minuti; resta 15 minuti, finisce sotto i 60 passi/min. Facoltativo (permesso Attività fisica) |
| 3 | **In ascolto** | cuffie o audio Bluetooth collegati |
| 4 | **In viaggio** | roaming o fuso orario diverso da casa |
| 5 | **Serata fuori** | sera o notte, casa già riconosciuta, luogo localizzato diverso da casa e lavoro, niente Wi-Fi. Venerdì, sabato e vigilie di festivi: qualsiasi luogo; domenica dalle 20:30; dal lunedì al giovedì dalle 21:00 e solo in un luogo occasionale (non frequente). Dopo mezzanotte vale la sera prima |
| 6 | **Lavoro/Scuola** | `place.role = work` |
| 7 | **Casa** | `place.role = home`, tranne risveglio, sera e notte che restano Spaces orari |
| 8 | **Fascia oraria** | sempre vera: risveglio, mattina, pranzo, pomeriggio, sera, notte |

Il contenuto di ogni Space (widget, azioni rapide, app suggerite) sarà nella specifica della UI. Il motore fornisce `SpaceId` + `ContextState` + `List<AppPrediction>`.

---

## 9. Privacy e conservazione dei dati

| Dato | Conservazione |
|---|---|
| `sample` con coordinate | 30 giorni. Dopo, le coordinate vengono azzerate e resta solo `place_id`, che diventa inutile dopo 90 giorni. |
| `system_event` | 30 giorni |
| `visit`, `sleep_episode`, `place_day` | 90 giorni |
| `launch_event` | 180 giorni, con decadimento nel punteggio |
| `place` | cancellato dopo 90 giorni senza visite, tranne i ruoli impostati dall'utente |

- **Compattazione** (`lib/core/compaction.dart`), a piccoli passi ogni 5 minuti (di più in carica) finché c'è lavoro, poi una volta al giorno:
  - `launch_event` e tocchi sulle card: righe singole per 48 ore; poi una riga al giorno per app/card, sorgente e contesto, con conteggio `n` e un orario "equivalente" che mantiene **esatto** il peso dell'abitudine (emivita 30 giorni per le app, 21 per le card); dopo 30 giorni le righe giornaliere si fondono per mese. La recentezza (emivita 6 ore) dopo 48 ore vale meno dello 0,4%. L'import dalla cronologia di Android non risale mai prima delle righe singole.
  - Campioni di posizione dopo 48 ore: si tolgono solo quelli ridondanti (tra due campioni dello stesso luogo, stesso giorno, a meno di 30 minuti), così pause notturne, permanenze, primo/ultimo campione del giorno e orari di arrivo restano identici.
  - Conservazione: un gruppo mensile si cancella appena il suo mese inizia a superare i 180 giorni (nulla di più vecchio resta). `VACUUM` al massimo una volta al mese, in carica.
  - Test di equivalenza: punteggi delle app e affinità delle card uguali prima e dopo; ruoli e punteggi dei luoghi identici dopo lo sfoltimento.
- **Backup:** il database è escluso dal backup cloud e dal trasferimento tra dispositivi tramite `dataExtractionRules`. Le impostazioni dell'utente possono essere incluse.
- **Cifratura:** facoltativa in v1 (SQLCipher). È da decidere (§13).
- **Esportazione:** un JSON leggibile con tutto il contenuto, per trasparenza.
- **"Cancella tutti i dati":** svuota le tabelle e chiama `resetHashSalt()`.
- **Pausa apprendimento:** un interruttore rapido che smette di salvare campioni e aperture mantenendo i dati già raccolti.

---

## 10. Impostazioni (parte del motore)

**Contesto e privacy**
- Interruttore generale "Adatta la home al contesto".
- Un interruttore per ogni segnale (§3.1), con una riga che spiega cosa usa e un link al permesso di sistema.
- Pausa apprendimento.
- Conservazione: 30, 90 o 180 giorni.
- Esporta i dati, Cancella tutti i dati.

**Luoghi**
- Casa e Lavoro/Scuola con stato ("Riconosciuta, 92%" oppure "In apprendimento, ancora qualche giorno") e una mappa statica disegnata in locale, senza tile online: un cerchio su sfondo neutro e la città.
- Azioni sul luogo attuale: "Questa è casa mia", "Questo è il mio lavoro/scuola", "Questo non è casa mia", "Questo non è il mio lavoro".
- L'etichetta Lavoro/Scuola.
- Luoghi frequenti: elenco con cancellazione.
- Reimposta luoghi.

**Conferma facoltativa**
La prima volta che casa o lavoro superano la confidenza di 0.8, compare una notifica discreta: "Sembra che tu sia a casa: è giusto?" con **Sì** e **No**. Il sì imposta `role_source = user`, il no imposta `role_blocked`. La conferma si può disattivare.

**Diagnostica (sviluppatore)**
Campioni recenti, luoghi con punteggi e componenti, episodi di sonno, contesto corrente, Space scelto con il motivo, previsioni con spiegazione.

---

## 11. Prestazioni

- **Snapshot:** ha un budget di 150 ms in Kotlin, al netto della richiesta di posizione, che è asincrona con timeout di 2 s e riserva sull'ultima posizione nota. La UI non aspetta mai il motore: mostra l'ultimo `ContextState` e si aggiorna quando arriva il nuovo.
- **Clustering e previsione:** sono incrementali e in memoria, con meno di 5 ms per snapshot e decine di luoghi al massimo.
- **Aggregati e ruoli:** girano una volta al giorno su un isolate Dart separato.
- **Volume stimato:** 30–80 campioni e 100–300 aperture al giorno, cioè meno di 10 MB in 180 giorni.

---

## 12. Test

Il motore è puro Dart, quindi si testa con un **generatore di tracce sintetiche**: persone simulate per 4–6 settimane con rumore GPS, Wi-Fi, campionamento sparso e giorni anomali.

| Persona | Atteso |
|---|---|
| Impiegato 9–18, lun–ven | casa ≥ 0.8 entro 5 giorni, lavoro ≥ 0.8 entro 7 |
| Studente con lezioni 8–13 e biblioteca il pomeriggio | casa ok, scuola ok, biblioteca `frequent` |
| Turnista notturno (dorme 8–15) | casa ok anche se dorme di giorno, lavoro ok con la variante a turni |
| Smart working tutti i giorni | casa ok, nessun lavoro assegnato |
| Settimana di vacanza all'estero | casa invariata, hotel mai casa, contesto "In viaggio" |
| Trasloco al giorno 20 | nuova casa entro il giorno 27, la vecchia perde il ruolo |
| Casa e lavoro a 400 m con Wi-Fi diversi | distinti correttamente |
| Casa e lavoro a 400 m con solo posizione approssimativa | lavoro non assegnato, o con confidenza bassa |
| Rete mesh con 3 BSSID | un unico luogo |
| Hotspot del telefono sempre attivo | non diventa mai un'impronta `trusted` |
| Senza accesso ai dati di utilizzo | casa ok entro 7 giorni con `sample_gap` |

Oltre a questi servono:
- test unitari per ogni componente (clusterer, sleep detector, aggregator, inference, predictor);
- test di proprietà, per esempio che un ruolo impostato dall'utente non cambi mai;
- una schermata di diagnostica da usare sui telefoni reali nelle prime settimane.

---

## 13. Domande aperte

1. **Variante a turni:** attivarla in automatico se il sonno abituale cade di giorno, o sempre?
2. **Cifratura del database:** SQLCipher in v1 o dopo? Costa circa 2–3 MB e un po' di complessità.
3. **Insieme finale degli Space:** quelli del §8.2 sono una proposta. Vanno validati con la specifica della UI.
4. **Dizionario delle categorie:** quante app coprire all'inizio, per esempio le 2.000 più diffuse in Italia ed Europa, e come aggiornarlo senza rete (solo con gli aggiornamenti dell'app).
5. **Lettura del Wi-Fi su Android 17:** verificare che SSID e BSSID siano leggibili con il solo permesso di posizione "mentre in uso".
6. **Festività:** quali paesi supportare oltre all'Italia in v1.

---

## 14. Piano di sviluppo

| Fase | Contenuto | Risultato verificabile |
|---|---|---|
| **M0 — Raccolta** | Bridge Kotlin, snapshot, eventi, database, schermata di diagnostica | Dopo un giorno d'uso la diagnostica mostra campioni ed eventi corretti |
| **M1 — Luoghi** | Clusterer, Wi-Fi, visite, sonno, aggregati, ruoli, generatore di tracce e test | Tutte le persone del §12 passano, e casa viene riconosciuta sul telefono reale |
| **M2 — Previsione** | Categorie, aperture, Naive Bayes, spiegazioni | Le prime 5 app suggerite sono "giuste" a occhio dopo una settimana |
| **M3 — Contesto e Space** | `ContextResolver`, `SpaceSelector`, impostazioni dei luoghi, conferma | La home cambia Space da sola nei casi del §8.2 |
| **M4 — Rifinitura** | Città offline, viaggio, conservazione, esportazione, cancellazione | Checklist privacy del §9 completa |
