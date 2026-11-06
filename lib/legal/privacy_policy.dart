/// Informativa sulla privacy di libreGLIDE (GDPR, Reg. UE 2016/679).
///
/// Testo in italiano e inglese; docs/PRIVACY.md ne è la copia in Markdown
/// (generata da tool/privacy_md.dart).
library;

/// Titolare e contatto.
const String controllerName = 'Federico Candiago';
const String controllerContact =
    'https://github.com/federicocandiago/libreglide/issues';

const String policyVersion = '1.2';
const String policyDate = '6 novembre 2026';

class PolicySection {
  const PolicySection(this.title, this.paragraphs);
  final String title;
  final List<String> paragraphs;
}

List<PolicySection> privacyPolicy(String languageCode) =>
    languageCode == 'it' ? _it : _en;

const List<PolicySection> _it = [
  PolicySection('In breve', [
    'libreGLIDE non raccoglie, non invia e non vende dati personali. Non ci sono account, pubblicità, statistiche d\'uso né telemetria.',
    'Tutto quello che il launcher impara sulle tue abitudini resta sul tuo telefono. Lo sviluppatore non vi ha accesso.',
    'Le connessioni a Internet sono facoltative e partono solo se le attivi tu: lo sfondo contestuale (Unsplash, con una tua chiave) e la card Meteo (Open-Meteo).',
  ]),
  PolicySection('Titolare e contatti', [
    'libreGLIDE è un launcher open source sviluppato da $controllerName. Contatto: $controllerContact.',
    'Poiché lo sviluppatore non riceve né conserva dati personali degli utenti, non effettua trattamenti di dati personali attraverso l\'app.',
  ]),
  PolicySection('Dati che restano sul telefono', [
    'Per suggerirti le app giuste, libreGLIDE salva sul dispositivo lo storico delle aperture: quale app, quando, la fascia oraria, se è un giorno feriale o festivo, il tipo di rete (Wi-Fi, dati, offline) e l\'uscita audio (altoparlante o cuffie). Non salva nomi di reti, posizioni o contenuti delle app.',
    'Salva inoltre le tue impostazioni, le app preferite e nascoste, le raccolte preferite scelte all\'avvio e, se attivi lo sfondo contestuale, la foto in uso con il nome dell\'autore.',
    'Lo storico delle aperture viene cancellato automaticamente dopo 180 giorni ed è escluso dal backup nel cloud e dal trasferimento tra dispositivi. Le impostazioni possono essere incluse nel backup di Android, secondo le tue impostazioni di sistema.',
  ]),
  PolicySection('Permessi', [
    'Calendario (facoltativo): per mostrare i tuoi prossimi impegni nella card Agenda. Gli eventi vengono letti solo sul telefono e non vengono salvati né inviati.',
    'Accesso alle notifiche (facoltativo): Android lo richiede per controllare la musica in riproduzione nella card In ascolto. libreGLIDE lo usa solo per le sessioni multimediali: non legge, non salva e non invia le notifiche.',
    'Stato della rete: per sapere se sei connesso via Wi-Fi o dati, senza leggere il nome della rete.',
    'Contatti (facoltativo): per mostrare preferiti e più usati nel pannello contatti. I contatti vengono letti solo sul telefono; libreGLIDE ricorda soltanto quante volte apri ciascun contatto dal pannello, per ordinarli.',
    'Posizione precisa (facoltativo): per riconoscere casa, lavoro e luoghi frequenti, solo mentre usi il launcher. Le coordinate e un\'impronta cifrata della rete Wi-Fi (mai il suo nome: un hash con una chiave casuale che esiste solo sul tuo telefono) restano sul dispositivo, vengono cancellate dopo 30 giorni e non vengono mai inviate. Si può disattivare e azzerare in Impostazioni → Luoghi.',
    'Posizione approssimativa (facoltativo): solo per la card Meteo. Le coordinate vengono arrotondate a circa 10 km prima dell\'invio e non vengono salvate.',
    'Dispositivi nelle vicinanze (facoltativo): per riconoscere quando sei collegato all\'autoradio Bluetooth e mostrare la card In auto. Non vengono salvati nomi né indirizzi dei dispositivi.',
    'Posizione in background (facoltativo, spento di default): solo per "Dove ho parcheggiato". Viene letta una volta, quando il telefono si scollega dall\'autoradio Bluetooth; il punto resta sul telefono, viene sostituito al parcheggio successivo e non viene mai inviato.',
    'Accesso ai dati di utilizzo (facoltativo, da concedere nelle impostazioni di Android): per mostrare il tempo di utilizzo di oggi e per imparare anche dalle app aperte fuori da libreGLIDE. Di queste aperture si salvano sul telefono solo l\'app, l\'ora, la fascia oraria e il tipo di giorno, come per le aperture fatte dal launcher; non vengono mai inviate e si possono escludere o cancellare in Impostazioni → Dati e privacy.',
    'Servizio di accessibilità (facoltativo, spento di default): solo per Digital detox. Riceve soltanto il nome dell\'app che passa in primo piano, per mostrare la schermata di blocco se è tra quelle scelte; non può leggere il contenuto dello schermo e non registra nulla. Il PIN è salvato solo come hash, sul telefono.',
    'Widget: se aggiungi widget di altre app, sono quelle app a fornirne il contenuto, secondo le loro informative.',
    'Internet: usato soltanto per lo sfondo Unsplash e per la card Meteo, se li attivi.',
    'Richiesta di disinstallazione: per disinstallare un\'app dal suo menu, sempre con la conferma di sistema.',
  ]),
  PolicySection('Unsplash (facoltativo)', [
    'Se inserisci una tua chiave Unsplash e attivi lo sfondo contestuale, il telefono si collega direttamente ai server di Unsplash per cercare una foto. Vengono inviati: parole chiave generiche legate al momento (per esempio "sunset" o "christmas lights"), la tua chiave, l\'indirizzo IP e i dati tecnici della connessione. Come richiesto dalle regole di Unsplash, viene anche segnalato l\'utilizzo della foto scelta.',
    'Non vengono inviate coordinate GPS né altri dati sul tuo utilizzo del telefono.',
    'Unsplash tratta questi dati come titolare autonomo, secondo la propria informativa: https://unsplash.com/privacy. Puoi disattivare lo sfondo contestuale o cancellare la chiave in qualsiasi momento dalle impostazioni.',
  ]),
  PolicySection('Open-Meteo (facoltativo)', [
    'Se attivi la card Meteo, il telefono chiede le previsioni a Open-Meteo (open-meteo.com) inviando le coordinate arrotondate a circa 10 km, l\'indirizzo IP e i dati tecnici della connessione. Non serve alcun account o chiave.',
    'Open-Meteo tratta questi dati secondo la propria informativa: https://open-meteo.com/en/terms. Puoi disattivare la card in qualsiasi momento.',
  ]),
  PolicySection('Conservazione e cancellazione', [
    'Puoi cancellare lo storico delle aperture in qualsiasi momento da Impostazioni → Dati e privacy. Disinstallando libreGLIDE, Android elimina tutti i dati dell\'app.',
  ]),
  PolicySection('I tuoi diritti', [
    'Il Regolamento (UE) 2016/679 ti riconosce i diritti di accesso, rettifica, cancellazione, limitazione, portabilità e opposizione (artt. 15–22). Poiché i dati restano sul tuo dispositivo e sotto il tuo controllo, puoi consultarli e cancellarli direttamente dall\'app.',
    'Per i dati trattati da Unsplash puoi rivolgerti a Unsplash. Hai inoltre il diritto di proporre reclamo al Garante per la protezione dei dati personali (www.garanteprivacy.it) o all\'autorità di controllo del tuo Paese.',
  ]),
  PolicySection('Modifiche', [
    'Eventuali modifiche a questa informativa saranno indicate nell\'app con una nuova versione e data. Versione $policyVersion del $policyDate.',
  ]),
];

const List<PolicySection> _en = [
  PolicySection('In short', [
    'libreGLIDE does not collect, send or sell personal data. There are no accounts, ads, usage analytics or telemetry.',
    'Everything the launcher learns about your habits stays on your phone. The developer has no access to it.',
    'Internet connections are optional and start only if you turn them on: the contextual wallpaper (Unsplash, with your own key) and the Weather card (Open-Meteo).',
  ]),
  PolicySection('Controller and contact', [
    'libreGLIDE is an open source launcher developed by $controllerName. Contact: $controllerContact.',
    'Since the developer neither receives nor stores users\' personal data, it does not process personal data through the app.',
  ]),
  PolicySection('Data that stays on the phone', [
    'To suggest the right apps, libreGLIDE stores a launch history on the device: which app, when, the time of day, whether it is a workday or a day off, the network type (Wi-Fi, mobile, offline) and the audio output (speaker or headphones). It does not store network names, locations or app content.',
    'It also stores your settings, favorite and hidden apps, the favorite collections chosen at first launch and, if you turn on the contextual wallpaper, the photo in use with its author\'s name.',
    'The launch history is deleted automatically after 180 days and is excluded from cloud backup and device-to-device transfer. Settings may be included in Android backup, depending on your system settings.',
  ]),
  PolicySection('Permissions', [
    'Calendar (optional): to show your upcoming events in the Agenda card. Events are read only on the phone and are never stored or sent.',
    'Notification access (optional): Android requires it to control the music that is playing in the Now playing card. libreGLIDE uses it only for media sessions: it never reads, stores or sends notifications.',
    'Network state: to know whether you are on Wi-Fi or mobile data, without reading the network name.',
    'Contacts (optional): to show favorite and most used contacts in the contacts panel. Contacts are read only on the phone; libreGLIDE only remembers how often you open each contact from the panel, to sort them.',
    'Precise location (optional): to recognize home, work and frequent places, only while you use the launcher. Coordinates and an encrypted fingerprint of the Wi-Fi network (never its name: a hash with a random key that exists only on your phone) stay on the device, are deleted after 30 days and are never sent. You can turn it off and reset it in Settings → Places.',
    'Approximate location (optional): only for the Weather card. Coordinates are rounded to about 10 km before being sent and are not stored.',
    'Nearby devices (optional): to recognize when you are connected to a Bluetooth car stereo and show the In the car card. No device names or addresses are stored.',
    'Background location (optional, off by default): only for "Where I parked". It is read once, when the phone disconnects from the Bluetooth car stereo; the spot stays on the phone, is replaced at the next parking and is never sent.',
    'Usage access (optional, granted in Android settings): to show today\'s screen time and to learn also from apps opened outside libreGLIDE. For these openings only the app, the time, the time slot and the type of day are stored on the phone, as for openings made from the launcher; they are never sent and can be excluded or deleted in Settings → Data & privacy.',
    'Accessibility service (optional, off by default): only for Digital detox. It receives just the name of the app coming to the foreground, to show the lock screen if it is one you chose; it cannot read the content of the screen and records nothing. The PIN is stored only as a hash, on the phone.',
    'Widgets: if you add widgets from other apps, those apps provide their content under their own policies.',
    'Internet: used only for the Unsplash wallpaper and the Weather card, if you turn them on.',
    'Request to uninstall: to uninstall an app from its menu, always with the system confirmation.',
  ]),
  PolicySection('Unsplash (optional)', [
    'If you enter your own Unsplash key and turn on the contextual wallpaper, the phone connects directly to Unsplash servers to look for a photo. What is sent: generic keywords tied to the moment (for example "sunset" or "christmas lights"), your key, your IP address and technical connection data. As required by Unsplash guidelines, the use of the chosen photo is also reported.',
    'No GPS coordinates or other data about your phone usage are sent.',
    'Unsplash processes this data as an independent controller under its own policy: https://unsplash.com/privacy. You can turn off the contextual wallpaper or delete the key at any time in settings.',
  ]),
  PolicySection('Open-Meteo (optional)', [
    'If you turn on the Weather card, the phone asks Open-Meteo (open-meteo.com) for the forecast, sending coordinates rounded to about 10 km, your IP address and technical connection data. No account or key is needed.',
    'Open-Meteo processes this data under its own terms: https://open-meteo.com/en/terms. You can turn the card off at any time.',
  ]),
  PolicySection('Retention and deletion', [
    'You can clear the launch history at any time in Settings → Data & privacy. Uninstalling libreGLIDE makes Android delete all of the app\'s data.',
  ]),
  PolicySection('Your rights', [
    'Regulation (EU) 2016/679 grants you the rights of access, rectification, erasure, restriction, portability and objection (Art. 15–22). Since the data stays on your device and under your control, you can view and delete it directly from the app.',
    'For data processed by Unsplash, contact Unsplash. You also have the right to lodge a complaint with your data protection authority (in Italy, the Garante per la protezione dei dati personali, www.garanteprivacy.it).',
  ]),
  PolicySection('Changes', [
    'Any changes to this policy will be shown in the app with a new version and date. Version $policyVersion, $policyDate.',
  ]),
];
