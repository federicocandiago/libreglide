# libreGLIDE — Specifica delle viste app e dell'aspetto

> Versione 0.1 · bozza · 5 novembre 2026
> Collegata a: [spec-motore-contesto.md](spec-motore-contesto.md). Il §7 di quella specifica fornisce punteggi e categorie usati qui.

---

## 0. Riferimento estetico (dal 5 novembre 2026)

**Il linguaggio Glide è il riferimento unico e totale** per estetica e UX: barre e card bianche e piatte, maiuscoletti, Space colorati. Si aggiungono solo piccoli tocchi Material You: accento dalla palette dinamica, grigi leggermente tinti, colori degli Space armonizzati con la palette, angoli arrotondati, tema scuro automatico. Gli altri launcher non sono riferimenti.

Struttura attuale (v0.2), che prevale sui paragrafi successivi dove sono in conflitto:

- **Barra delle schede in alto**, opaca: strisce colorate (aprono il cassetto degli Space) · icona dello Space · **ora** · griglia (Collections) · A-Z. Un indicatore in colore d'accento segue lo scorrimento.
- **Pagine:** Space ← **Home** → Collections → A-Z. Si parte dalla Home. Il tasto Home riporta alla Home.
- **Cassetto degli Space:** scuro, "SPACES", Impostazioni in testa, uno Space per fascia oraria con icona e nome colorati. Scegliere uno Space lo forza finché non cambia il contesto.
- **Home:** solo lo sfondo del telefono e, in basso, il dock bianco 2×4 senza etichette, con un riquadro "+" per aggiungere app. Pressione lunga sullo sfondo: impostazioni.
- **Space:** giorno e data sopra lo sfondo; striscia colorata con icona e nome dello Space in maiuscolo sottile; card azioni (Sveglia | Non disturbare); card "Per questo momento" con le app previste; prossima sveglia; banner in colore d'accento ("Le informazioni utili compariranno qui durante la giornata", chiudibile con la spunta; "non è l'app Home" con Imposta).
- **Collections:** fondo grigio, card piatte a tutta larghezza con bordo sottile, intestazione in maiuscoletto con piccola icona grigia e freccia ∨, una riga di icone senza nomi (5 su un Pixel 7); aperta, mostra il resto con i nomi.
- **A-Z:** barra "A-Z APP" con ricerca e cambio griglia/lista; griglia a 4 colonne con nomi su 2 righe; la prima cella di ogni lettera è la lettera grande e sottile in colore d'accento; divisori sottili; alfabeto completo a destra.
- **Testo di sistema grande:** le etichette delle icone crescono al massimo del 115%.
- **Ricerca globale:** si apre con uno swipe verso il basso sulla Home o sulla barra delle schede, oppure dall'icona della pagina A-Z. In alto le 4 o 8 app più usate nel contesto attuale (impostabile), poi il campo di ricerca già attivo, poi i risultati. Ordine dei risultati: inizio del nome, inizio di una parola, iniziali, a metà nome, categoria; a parità di corrispondenza conta il punteggio del predittore.
- **Card dinamiche dello Space** (attivabili in Impostazioni → Space):
  - **In ascolto:** copertina, titolo, artista e controlli. Compare quando c'è musica in riproduzione o in pausa. Se mancano i permessi e sono collegate le cuffie, compare un invito a concedere l'accesso alle notifiche, usato solo per le sessioni multimediali (`MediaListenerService` è vuoto).
  - **Agenda:** di giorno gli eventi di oggi non ancora finiti, di sera quelli di domani, con barra colorata, ora, titolo, luogo con indicazioni e "+" per un nuovo evento. Se manca il permesso calendario, la card stessa lo chiede.
- **Impostazioni:** stesso linguaggio delle Collections. Barra con il titolo in maiuscoletto, sezioni in card piatte, righe con icona su fondo tonale, scelte a tutta larghezza sotto il titolo.
- **Onboarding** (primo avvio, poi da Impostazioni → Informazioni): benvenuto, come funziona, privacy con link all'informativa, scelta delle raccolte preferite tra le 8 più popolate, App Home e dock proposto (telefono, messaggi, fotocamera, browser).
- **Spinta iniziale delle raccolte preferite:** tabella `category_boost`. Per 21 giorni le preferite stanno in cima (+8 in unità log), poi la spinta si dimezza ogni 21 giorni. Nel frattempo le loro app riempiono "Per questo momento" e la ricerca quando le previsioni sono poche.
- **Sfondi Unsplash** (facoltativi, chiave dell'utente), mostrati solo dentro libreGLIDE; lo sfondo di sistema non viene mai toccato. Credito "Foto di … · Unsplash" con link e segnalazione d'uso come da regole Unsplash, sulla Home e nell'intestazione dello Space.
  - **Sfondo giornaliero** (Home): una foto casuale (`/photos/random`) scaricata alla prima apertura del giorno; la foto di ieri resta visibile finché la nuova non è pronta (o se si è offline). "Cambia la foto di oggi" ne scarica un'altra.
  - **Sfondo contestuale** (solo intestazione dello Space; se spento, lo Space mostra il giornaliero): momento scelto in modo deterministico: festività → viaggio (roaming o fuso orario diverso da casa) → meteo → cuffie → fascia oraria + stagione. Foto stabile nel giorno (hash di ricerca e data), "Cambia foto" passa alla successiva.
  - **Stile delle foto** (scelta singola): Nessuno, Aesthetic, Natura, Minimal, Astratto, Architettura, Scuro. La parola (in inglese) si aggiunge a entrambe le ricerche; se la ricerca contestuale con lo stile dà meno di 3 foto, si ripete senza.
- **Informativa privacy** (GDPR) e **Librerie open source** in Impostazioni → Informazioni.
- **Barra degli Space:** strisce sottili e attenuate. **A-Z:** intestazione sottile in maiuscoletto con il numero di app, che scorre via con la lista.
- **Ricerca (v0.3):** barra in alto, poi "Per questo momento" (4 o 8 app con nome), poi i risultati come elenco. Senza testo, le raccolte come chip da sfogliare. Con "Apri da sola l'unica app trovata" (attivo di default), se resta una sola app corrispondente con almeno 2 lettere si apre dopo 350 ms di pausa. Aperta un'app, la ricerca si chiude e si torna alla schermata di partenza.
- **Contatti (swipe verso l'alto):** ricerca, poi "Preferiti e più usati": prima i più usati da libreGLIDE (tabella `contact_usage`, peso che si dimezza ogni 30 giorni), poi i preferiti con la stella. Azioni: Chiama (apre il tastierino, non avvia la chiamata), Messaggio, Scheda contatto.
- **Gesti configurabili:** swipe in giù e in su sulla Home, ciascuno Ricerca, Contatti o Niente. Lo swipe in giù funziona anche sulla barra delle schede.
- **Card Buonanotte** (sera e notte, al posto della card azioni e della sveglia): sveglia, Non disturbare con il suo stato, promemoria di ricarica sotto il 40%. **Prossima destinazione:** impegno con un luogo nelle prossime 3 ore, indicazioni e app di mappe. **In viaggio** (fuso diverso da casa o roaming): ora di casa, app di mappe, "Ora vivo qui".
- **Nomi nelle Collections:** interruttore, spento di default. Vale anche per le righe di app dello Space (App suggerite e App della categoria).
- **Card Meteo** (spenta di default, Impostazioni → Space): Open-Meteo, senza chiave, con la posizione approssimativa arrotondata a 1 decimale (~10 km). Temperatura grande e sottile, simbolo, massima e minima con barrette rossa e blu, le prossime 4 ore ogni 2, credito "Open-Meteo (CC BY 4.0)". Aggiornamento al massimo ogni 30 minuti.
- **Card In auto:** con Android Auto (nessun permesso) o con l'autoradio Bluetooth (permesso facoltativo "Dispositivi nelle vicinanze"). Prossima destinazione con indicazioni, app di mappe e di musica. In auto il contesto passa `motion = driving` al predittore.
- **Ordine delle card dello Space:** priorità del profilo dello Space, poi l'uso. Ogni tocco su una card la fa salire nello stesso contesto (fascia, luogo, cuffie, auto; emivita 21 giorni), fino a 18 posizioni. "App suggerite" e "App della categoria" restano al posto del profilo: il loro contenuto si adatta già e si toccano molto più delle altre. Una card nascosta dal profilo torna solo con "Mostra sempre qui" o se usata almeno 3 volte di recente in quello stesso Space (i tocchi sono salvati come `card@space`). "Mostra sempre qui" vale anche per l'agenda vuota. Con uno Space scelto a mano, ordine e tocchi seguono la situazione di quello Space.
- **Widget Android:** a tutta larghezza in card dello Space (AppWidgetHost + PlatformView), gestiti da Impostazioni → Space → Widget: aggiunta con il flusso di sistema (collegamento e configurazione), altezza a passi di 40 dp, ordine, rimozione.

- **Tempo di utilizzo** (spento di default; Home o Space): tempo in primo piano da mezzanotte calcolato dagli eventi di utilizzo (esclusi libreGLIDE e SystemUI). Home: pillola "Oggi · 3 h 12 min"; Space: card con totale e 3 app più usate con barra. Tocco → Benessere digitale. Serve l'accesso ai dati di utilizzo.
- **Meteo nello sfondo contestuale:** pioggia, neve, temporale e nebbia hanno priorità dopo festività e viaggio ("rain window", "snowy street", "storm clouds", "foggy morning").
- **Onboarding** in modale quasi a tutto schermo (margini 12/20, raggio 28) sopra la Home, che resta visibile intorno. Al primo avvio non si chiude con "indietro".
- **Space:** data in una card arrotondata staccata (la pagina è opaca intorno e lascia vedere lo sfondo solo dentro la card); anche la striscia dello Space è una card arrotondata.
- **Collections:** la freccia compare solo se ci sono app oltre la riga visibile.
- **Carattere:** Google Sans dai file del telefono (Pixel), versione "Text" se presente; altrimenti Roboto. Nessun font incluso nell'app.
- **Icona:** elica a tre pale nei colori degli Space dentro un'orbita, su fondo blu notte; adaptive icon con layer monocromo per le icone a tema (`docs/icon/libreglide-icon.svg`).

- **Space di contesto (v0.5):** Casa, Lavoro/Scuola, In movimento, In ascolto, In viaggio, oltre a quelli dell'ora. Regole in ordine: auto → cuffie → viaggio (roaming, fuso diverso, oltre 100 km da casa) → lavoro → casa (a casa Risveglio e Sera/Notte restano Space dell'ora) → ora del giorno. Il cambio si nota: l'icona nella barra entra ruotando, la striscia cambia colore e nome con una transizione. Azioni per Space: Lavoro "Nuovo evento | Email", In movimento e In viaggio "Verso casa | Verso il lavoro", gli altri "Sveglia | Non disturbare". Il cassetto elenca gli Space "dal contesto" e "dall'ora del giorno".
- **Luoghi (M1):** campione a ogni ritorno sul launcher (al massimo ogni 3 minuti) con posizione precisa, impronta Wi-Fi (hash con chiave locale, hotspot esclusi) e ricarica; ruoli ricalcolati ogni 6 ore; stato salvato nella tabella `kv`, campioni in `location_sample` (30 giorni). Impostazioni → Luoghi: attivazione, stato di casa e lavoro, nome dello Space di lavoro, correzioni sul luogo attuale, reimpostazione. Diagnostica con i punteggi di ogni luogo.

- **Widget sulla Home:** pressione lunga sullo sfondo → Aggiungi widget, Modifica i widget, Impostazioni. Al massimo 3, a tutta larghezza sopra il dock, altezza da 1 a 4 righe da 88 dp; in modifica un velo con più basso/più alto, su/giù, rimuovi e "Fine".
- **Dove ho parcheggiato** (spento di default): allo scollegamento dall'autoradio/vivavoce Bluetooth `ParkingReceiver` salva il punto (posizione in background, solo in quel momento); al ricollegamento lo dimentica. Card nello Space con ora, "fa", indicazioni a piedi e "Dimentica" (per 24 ore, non a casa né al lavoro); permessi chiesti uno alla volta.
- **Cassetto degli Space (v0.5):** segue il tema; card "Automatico | Impostazioni", "Dal contesto", "Dall'ora del giorno"; righe con icona in cerchio del colore dello Space, selezione a pillola tinta, badge "ora" sullo Space del contesto; "Automatico" torna allo Space del contesto.
- **Dock:** card arrotondata sospesa (raggio 28, margini 10).
- **Tema chiaro:** card `surfaceContainerLow` su pagina `surfaceContainerHigh`, così le icone con fondo bianco restano riconoscibili.
- **Comandi di sviluppo:** anche `theme:light`, `theme:dark`, `theme:system`.

### Linguaggio grafico comune (v0.4)

Impostazione Glide, forme e toni di Android 17, uguali in tutte le schermate:

| Elemento | Regola |
|---|---|
| Card | senza bordo, colore `card` (bianco / `surfaceContainerHigh` al buio) su pagina `page` (`surfaceContainer` / `surface`), raggio 24 |
| Fogli dal basso, dialoghi | raggio 28, colore `card` |
| Elementi interni | raggio 16 (scelte, riquadri), 12 (chip, copertine) |
| Campi di ricerca, pulsanti | pillola |
| Spazi | 10 tra le card e dai bordi, 16 dentro le card, intestazioni 48, righe ≥ 56 |
| Intestazioni | icona 18 in colore d'accento + maiuscoletto 12,5 peso 700 spaziato 1,3 |
| Righe delle impostazioni | icona tonale 40 in cerchio, titolo 16 medio, sottotitolo 14, linee sottili rientrate a 72 |
| Interruttori | con la spunta nel cursore (Android 17) |
| Cassetto degli Space | scuro, angoli destri da 28 |

- **Comando di sviluppo:** `adb shell am start -n org.libreglide.launcher/.MainActivity --es open <schermata>` apre home, space, collections, az, search, drawer, settings, colors, hidden o diagnostics senza toccare lo schermo.

## 1. Navigazione

```
 ┌────────┐  swipe  ┌──────────────┐  swipe  ┌───────────────┐
 │  Home  │ ──────▶ │ Collections  │ ──────▶ │ Tutte le app  │
 │ (Space)│ ◀────── │ (menu        │ ◀────── │ (griglia o    │
 └────────┘         │  dinamico)   │         │  lista A-Z)   │
                    └──────────────┘         └───────────────┘
```

- È un `PageView` orizzontale a tre pagine, con indicatore discreto in basso.
- **Tasto Home** (o gesto Home): torna alla pagina Home, chiude le card espanse e svuota la ricerca.
- **Indietro**: da Collections o Tutte le app torna alla Home. Dalla Home non fa nulla, perché un launcher non si chiude.
- **Pressione lunga su uno spazio vuoto della Home**: apre le impostazioni.

## 2. Home (Space)

v0.1, versione essenziale. Gli Space completi arriveranno con il motore di contesto, fase M3.

- **In alto:** orologio grande, data e chip del contesto, per esempio "Mattina · feriale".
- **Al centro:** "Per te adesso", una riga con le 5 app più probabili nel contesto corrente (AppPredictor). Prima che ci siano dati compare un messaggio che spiega che il launcher sta imparando.
- **In basso:** dock dei **preferiti**, fino a 5 app scelte dall'utente (pressione lunga, poi "Aggiungi ai preferiti").
- **Sfondo:** lo sfondo di sistema, visibile dietro al launcher, con una leggera sfumatura nella parte bassa per la leggibilità.

## 3. Collections (menu dinamico)

### 3.1 Struttura a due livelli

- **Livello 1: card di categoria a tutta larghezza.** Ogni card ha un'intestazione con icona, nome e numero di app, e sotto una riga con le app della categoria più probabili *nel contesto corrente*. Le icone nella riga sono `floor(larghezza_utile / 72dp)`, cioè 5 su un telefono normale e da 4 a 7 secondo lo schermo.
- **Livello 2: card espansa.** Toccando l'intestazione la card si apre con un'animazione (`AnimatedSize`) e mostra tutte le app della categoria: prima la riga dinamica, poi tutte le altre **in ordine alfabetico**.
- **Una sola card aperta alla volta.** Aprirne un'altra chiude la precedente.

### 3.2 Ordinamento e stabilità

- **Punteggio di una categoria:** la media dei 3 punteggi migliori delle sue app nel contesto corrente.
- **Ricalcolo:** l'ordine delle card e delle icone si ricalcola **solo quando cambia il contesto** (fascia oraria, tipo di giorno e, in futuro, Space), quando si installa o disinstalla un'app, o quando l'utente cambia una categoria. Mai tra un'apertura e l'altra nello stesso contesto.
- **Isteresi:** due elementi adiacenti si scambiano solo se il punteggio del secondo supera quello del primo di almeno il 10% (in scala logaritmica: almeno `ln(1.1)`).
- **Card fissate:** l'utente può fissare una card in cima, e le card fissate mantengono l'ordine di fissaggio.
- **Ordine fisso** (impostazione): disattiva l'ordinamento per contesto. Le card seguono l'ordine predefinito delle categorie e le icone l'ordine alfabetico.
- **Senza dati sufficienti** (meno di 20 aperture registrate) l'ordine è quello predefinito delle categorie.

### 3.3 Categorie piccole e nascoste

- Le categorie con 1–2 app confluiscono in **"Altro"**, tranne quelle fissate.
- Una categoria nascosta non compare nelle Collections. Le sue app restano in "Tutte le app".

### 3.4 Pressione lunga

- **Sull'intestazione:** Fissa in cima / Rimuovi dai fissati, Nascondi categoria.
- **Su un'app:** vedi §5.

### 3.5 Niente suggerimenti di app non installate

Erano tipici dei launcher contestuali commerciali, come pubblicità. libreGLIDE non li mostra, e del resto richiederebbero la rete.

## 4. Tutte le app

- **Barra di ricerca** in alto, sempre visibile. La ricerca è per nome, senza accenti e senza distinguere maiuscole, e trova anche corrispondenze a metà parola. Il tasto Invio apre il primo risultato.
- **Pulsante griglia/lista**, salvato nelle impostazioni:
  - **Griglia:** icona ed etichetta su una riga, con colonne = `floor(larghezza / 84dp)`.
  - **Lista:** icona, nome e categoria in piccolo, alta 64 dp.
- **Ordine alfabetico** con intestazioni di sezione per lettera. Le lettere accentate e i caratteri non latini finiscono sotto `#`.
- **Barra delle lettere** sul bordo destro: toccando o trascinando si salta alla sezione.
- **Filtri dalle impostazioni:** app di sistema (mostra o nascondi) e app nascoste (sempre escluse).

## 5. Azioni su un'app (pressione lunga, ovunque)

Un bottom sheet con: icona e nome, **Aggiungi ai preferiti / Rimuovi**, **Cambia categoria**, **Nascondi**, **Informazioni app** (impostazioni di Android) e **Disinstalla** (conferma di sistema). Le app di sistema non hanno "Disinstalla".

## 6. Aspetto

### 6.1 Tema
Chiaro, scuro o automatico (segue il sistema).

### 6.2 Colori

**Origine del colore:**
1. **Sistema** (predefinito, Android 12+): usa la palette dinamica di Android tramite `dynamic_color`.
2. **Colore scelto:** uno dei seed predefiniti. La palette completa si genera con `ColorScheme.fromSeed`.
3. **Dallo sfondo di libreGLIDE:** solo quando ci sarà lo sfondo Unsplash, che non è in v0.1.

**Seed predefiniti** (indicativi, da rifinire guardando le palette):

| Nome | Seed |
|---|---|
| Laguna | `#3A6EA5` |
| Salvia | `#5B8C5A` |
| Terracotta | `#C2603A` |
| Ambra | `#D49A2A` |
| Lampone | `#B03A5B` |
| Lavanda | `#7A64B8` |
| Petrolio | `#2F7F86` |
| Grafite | `#5F6368` |

**Stile della palette:** Tonale (predefinito), Vivace, Espressivo, Neutro, Monocromo (`DynamicSchemeVariant`). Con l'origine "Sistema" e lo stile Tonale si usa la palette di Android così com'è. Con altri stili, il primario del sistema diventa il seed.

**Contrasto:** standard, medio o alto (`contrastLevel` 0, 0.5 o 1).

**Anteprima dal vivo:** la schermata Colori mostra in alto una mini home (card Collections, riga di icone, pulsante) che cambia in tempo reale.

### 6.3 Icone
- **Originali** (predefinito).
- **A tema:** usa il layer monocromo delle adaptive icon (Android 13+), colorato con `onPrimaryContainer` su sfondo `primaryContainer`. Le app senza layer monocromo mostrano l'icona originale.

### 6.4 Sfondo
v0.1 usa lo sfondo di sistema. Lo sfondo Unsplash (chiave facoltativa) è rimandato a una versione successiva.

## 7. Altre impostazioni (v0.1)

- **App:** vista griglia o lista, mostra app di sistema, app nascoste (elenco con ripristino), ordine fisso delle Collections, categorie nascoste e fissate.
- **Lingua:** sistema, italiano, inglese.
- **Launcher predefinito:** un pulsante "Imposta libreGLIDE come app Home" (`RoleManager.ROLE_HOME`).
- **Dati:** cancella lo storico delle aperture.
- **Informazioni:** versione, licenza, codice sorgente.

## 8. Dati salvati (v0.1)

- **Impostazioni:** `shared_preferences`.
- **Storico delle aperture:** SQLite (`sqflite`), tabella `launch_event` come nel §5 della specifica del motore. Si conservano 180 giorni.
- **Correzioni dell'utente** (categorie, preferiti, app nascoste, card fissate e nascoste): `shared_preferences`.

> In v0.1 si usa `sqflite` invece di Drift per evitare la generazione di codice. Si potrà passare a Drift quando arriveranno le tabelle dei luoghi.

## 9. Fuori da v0.1

Widget nelle card e negli Space, Space contestuali completi, contatti con swipe in su, luoghi, sfondo Unsplash, riordino manuale delle card con trascinamento, profilo di lavoro.
