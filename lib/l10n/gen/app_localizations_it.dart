// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class L10nIt extends L10n {
  L10nIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'libreGLIDE';

  @override
  String get suggestionsTitle => 'Per te adesso';

  @override
  String get learningHint =>
      'libreGLIDE sta imparando le tue abitudini: le app suggerite compariranno dopo qualche apertura.';

  @override
  String get favoritesEmpty =>
      'Tieni premuta un\'app per aggiungerla ai preferiti';

  @override
  String contextChip(Object slot, Object dayType) {
    return '$slot · $dayType';
  }

  @override
  String get notDefaultBanner => 'libreGLIDE non è ancora l\'app Home';

  @override
  String get setAction => 'Imposta';

  @override
  String get slotWakeUp => 'Risveglio';

  @override
  String get slotMorning => 'Mattina';

  @override
  String get slotLunch => 'Pranzo';

  @override
  String get slotAfternoon => 'Pomeriggio';

  @override
  String get slotEvening => 'Sera';

  @override
  String get slotNight => 'Notte';

  @override
  String get dayWorkday => 'feriale';

  @override
  String get dayHoliday => 'festivo';

  @override
  String get pageHome => 'Home';

  @override
  String get pageCollections => 'Collections';

  @override
  String get pageAllApps => 'Tutte le app';

  @override
  String appCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count app',
      one: '1 app',
    );
    return '$_temp0';
  }

  @override
  String get pinCategory => 'Fissa in cima';

  @override
  String get unpinCategory => 'Rimuovi dai fissati';

  @override
  String get hideCategory => 'Nascondi categoria';

  @override
  String get categoryHidden =>
      'Categoria nascosta. Puoi ripristinarla dalle impostazioni.';

  @override
  String get undo => 'Annulla';

  @override
  String get noCollections => 'Nessuna app da mostrare';

  @override
  String get catSocial => 'Social';

  @override
  String get catMessaging => 'Messaggi e chiamate';

  @override
  String get catMusic => 'Musica e audio';

  @override
  String get catVideo => 'Video';

  @override
  String get catPhoto => 'Foto';

  @override
  String get catNews => 'Notizie';

  @override
  String get catMaps => 'Mappe e viaggi';

  @override
  String get catProductivity => 'Produttività';

  @override
  String get catWork => 'Lavoro';

  @override
  String get catEducation => 'Studio';

  @override
  String get catFinance => 'Finanza';

  @override
  String get catShopping => 'Shopping';

  @override
  String get catFood => 'Cibo';

  @override
  String get catHealth => 'Salute e sport';

  @override
  String get catGames => 'Giochi';

  @override
  String get catTools => 'Strumenti';

  @override
  String get catSystem => 'Sistema';

  @override
  String get catOther => 'Altro';

  @override
  String get searchHint => 'Cerca app';

  @override
  String get noResults => 'Nessuna app trovata';

  @override
  String get layoutGrid => 'Griglia';

  @override
  String get layoutList => 'Lista';

  @override
  String get addFavorite => 'Aggiungi ai preferiti';

  @override
  String get removeFavorite => 'Rimuovi dai preferiti';

  @override
  String favoritesFull(int max) {
    return 'Puoi avere al massimo $max preferiti';
  }

  @override
  String get changeCategory => 'Cambia categoria';

  @override
  String get automaticCategory => 'Categoria automatica';

  @override
  String get hideApp => 'Nascondi';

  @override
  String get appInfo => 'Informazioni app';

  @override
  String get uninstall => 'Disinstalla';

  @override
  String appHidden(Object app) {
    return '$app nascosta';
  }

  @override
  String get settingsTitle => 'Impostazioni';

  @override
  String get sectionAppearance => 'Aspetto';

  @override
  String get theme => 'Tema';

  @override
  String get themeSystem => 'Automatico';

  @override
  String get themeLight => 'Chiaro';

  @override
  String get themeDark => 'Scuro';

  @override
  String get colors => 'Colori';

  @override
  String get colorSource => 'Origine del colore';

  @override
  String get colorSystem => 'Sistema';

  @override
  String get colorSystemDesc => 'Segue i colori di Android';

  @override
  String get colorPreset => 'Colore scelto';

  @override
  String get paletteStyle => 'Stile della palette';

  @override
  String get styleTonalSpot => 'Tonale';

  @override
  String get styleVibrant => 'Vivace';

  @override
  String get styleExpressive => 'Espressivo';

  @override
  String get styleNeutral => 'Neutro';

  @override
  String get styleMonochrome => 'Monocromo';

  @override
  String get contrast => 'Contrasto';

  @override
  String get contrastStandard => 'Standard';

  @override
  String get contrastMedium => 'Medio';

  @override
  String get contrastHigh => 'Alto';

  @override
  String get themedIcons => 'Icone a tema';

  @override
  String get themedIconsDesc =>
      'Icone monocromatiche colorate con la palette (Android 13+)';

  @override
  String get preview => 'Anteprima';

  @override
  String get presetLaguna => 'Laguna';

  @override
  String get presetSalvia => 'Salvia';

  @override
  String get presetTerracotta => 'Terracotta';

  @override
  String get presetAmbra => 'Ambra';

  @override
  String get presetLampone => 'Lampone';

  @override
  String get presetLavanda => 'Lavanda';

  @override
  String get presetPetrolio => 'Petrolio';

  @override
  String get presetGrafite => 'Grafite';

  @override
  String get sectionApps => 'App';

  @override
  String get allAppsLayout => 'Vista di Tutte le app';

  @override
  String get showSystemApps => 'Mostra app di sistema';

  @override
  String get showSystemAppsDesc =>
      'Telefono, Fotocamera, Impostazioni e app preinstallate';

  @override
  String get hiddenApps => 'App nascoste';

  @override
  String get hiddenAppsEmpty => 'Nessuna app nascosta';

  @override
  String get restore => 'Ripristina';

  @override
  String get fixedOrder => 'Ordine fisso delle Collections';

  @override
  String get fixedOrderDesc =>
      'Non riordinare card e icone in base al contesto';

  @override
  String get hiddenCategories => 'Categorie nascoste';

  @override
  String get hiddenCategoriesEmpty => 'Nessuna categoria nascosta';

  @override
  String get sectionLanguage => 'Lingua';

  @override
  String get languageSystem => 'Lingua di sistema';

  @override
  String get sectionLauncher => 'Launcher';

  @override
  String get setDefault => 'Imposta libreGLIDE come app Home';

  @override
  String get isDefault => 'libreGLIDE è l\'app Home predefinita';

  @override
  String get androidSettings => 'Impostazioni di Android';

  @override
  String get sectionData => 'Dati e privacy';

  @override
  String launchesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count aperture registrate',
      one: '1 apertura registrata',
      zero: 'Nessuna apertura registrata',
    );
    return '$_temp0';
  }

  @override
  String get privacyNote =>
      'Tutti i dati restano sul telefono ed escono solo se li esporti tu. Il database è escluso dal backup cloud.';

  @override
  String get clearHistory => 'Cancella lo storico delle aperture';

  @override
  String get clearHistoryConfirm =>
      'Cancellare lo storico? Le previsioni ripartiranno da zero.';

  @override
  String get cancel => 'Annulla';

  @override
  String get delete => 'Cancella';

  @override
  String get historyCleared => 'Storico cancellato';

  @override
  String get diagnostics => 'Diagnostica';

  @override
  String get diagnosticsDesc =>
      'Contesto corrente e motivazione delle previsioni';

  @override
  String get currentContext => 'Contesto corrente';

  @override
  String get predictions => 'Previsioni';

  @override
  String get noPredictions =>
      'Servono almeno 3 aperture di un\'app per prevederla.';

  @override
  String get sectionAbout => 'Informazioni';

  @override
  String get aboutDesc => 'Launcher contestuale open source e local-only.';

  @override
  String get tabSpace => 'Space';

  @override
  String get tabCollections => 'Collections';

  @override
  String get tabAllApps => 'A-Z';

  @override
  String get spacesTitle => 'Spaces';

  @override
  String get azHeader => 'A-Z App';

  @override
  String get actionAlarm => 'Sveglia';

  @override
  String get actionDnd => 'Non disturbare';

  @override
  String get infoBanner =>
      'Le informazioni utili compariranno qui durante la giornata.';

  @override
  String get nowAppsHeader => 'Per questo momento';

  @override
  String get nextAlarm => 'Prossima sveglia';

  @override
  String get noAlarm => 'Nessuna sveglia impostata';

  @override
  String get addToDock => 'Aggiungi al dock';

  @override
  String get searchApps => 'Cerca';

  @override
  String get searchTopApps => 'App sopra la ricerca';

  @override
  String get searchTopAppsDesc =>
      'Le più usate in questo contesto, sopra i risultati della ricerca.';

  @override
  String hiddenSummary(int apps, int categories) {
    return '$apps app, $categories categorie';
  }

  @override
  String get languageSystemShort => 'Sistema';

  @override
  String version(Object version) {
    return 'Versione $version';
  }

  @override
  String get agendaToday => 'Oggi';

  @override
  String get agendaTomorrow => 'Domani';

  @override
  String get noEventsToday => 'Nessun evento oggi';

  @override
  String get noEventsTomorrow => 'Nessun evento domani';

  @override
  String get allDay => 'Tutto il giorno';

  @override
  String get agendaPermission =>
      'Mostra qui i tuoi prossimi impegni del calendario.';

  @override
  String get allow => 'Consenti';

  @override
  String get newEvent => 'Nuovo evento';

  @override
  String get navigate => 'Indicazioni';

  @override
  String get nowPlaying => 'In ascolto';

  @override
  String get mediaPermission =>
      'Controlla la musica da qui. Serve l\'accesso alle notifiche: libreGLIDE lo usa solo per i controlli multimediali e non legge né salva le notifiche.';

  @override
  String get play => 'Riproduci';

  @override
  String get pause => 'Pausa';

  @override
  String get next => 'Successivo';

  @override
  String get previous => 'Precedente';

  @override
  String get sectionSpace => 'Space';

  @override
  String get cardAgenda => 'Agenda';

  @override
  String get cardAgendaDesc => 'Prossimi impegni dal calendario del telefono';

  @override
  String get cardMedia => 'In ascolto';

  @override
  String get cardMediaDesc =>
      'Controlli della musica in riproduzione, anche quando colleghi le cuffie';

  @override
  String get privacyPolicy => 'Informativa sulla privacy';

  @override
  String get privacyPolicyDesc => 'Cosa resta sul telefono e cosa no';

  @override
  String get openSource => 'Librerie open source';

  @override
  String get openSourceDesc => 'Licenze dei componenti usati da libreGLIDE';

  @override
  String openSourceCount(int count) {
    return '$count componenti';
  }

  @override
  String licenseCount(int count) {
    return '$count licenze';
  }

  @override
  String get appLicense => 'Licenza di libreGLIDE';

  @override
  String get appLicenseUndefined => 'Da definire prima della pubblicazione';

  @override
  String get unsplashAttribution =>
      'Le foto dello sfondo contestuale sono di autori Unsplash, citati sulla Home';

  @override
  String get showOnboarding => 'Rivedi la presentazione';

  @override
  String get obWelcomeTitle => 'Benvenuto in libreGLIDE';

  @override
  String get obWelcomeText =>
      'Il launcher che cambia con il tuo momento: ti mostra le app e le informazioni giuste, quando servono.';

  @override
  String get obStart => 'Inizia';

  @override
  String get obNext => 'Avanti';

  @override
  String get obBack => 'Indietro';

  @override
  String get obHowTitle => 'Come funziona';

  @override
  String get obHowSpace =>
      'Lo Space mostra agenda, musica e le app adatte a questo momento.';

  @override
  String get obHowHome =>
      'La Home lascia spazio al tuo sfondo, con il dock delle app preferite.';

  @override
  String get obHowCollections =>
      'Le Collections raggruppano le app da sole e mettono prima quelle che usi adesso.';

  @override
  String get obHowSearch =>
      'Swipe verso l\'alto per cercare un\'app, verso il basso per i contatti.';

  @override
  String get obHowDrawer =>
      'Tocca le strisce colorate in alto per scegliere uno Space.';

  @override
  String get obPrivacyTitle => 'La tua privacy';

  @override
  String get obPrivacy1 =>
      'Nessun account, nessuna pubblicità, nessuna telemetria.';

  @override
  String get obPrivacy2 =>
      'Le tue abitudini restano sul telefono: lo sviluppatore non le vede.';

  @override
  String get obPrivacy3 =>
      'Internet solo se scegli lo sfondo Unsplash con una tua chiave.';

  @override
  String get obReadPolicy => 'Leggi l\'informativa completa';

  @override
  String get obCollectionsTitle => 'Le tue raccolte';

  @override
  String get obCollectionsText =>
      'Quali usi di più? Resteranno in cima per le prime settimane, poi conterà come usi davvero il telefono.';

  @override
  String get obCollectionsHint =>
      'Scegline quante vuoi, anche nessuna. L\'ordine di scelta conta.';

  @override
  String get obFinishTitle => 'Ultimi ritocchi';

  @override
  String get obDockPrefill =>
      'Proponi un dock con telefono, messaggi, fotocamera e browser';

  @override
  String get obFinish => 'Fine';

  @override
  String photoBy(Object name) {
    return 'Foto di $name · Unsplash';
  }

  @override
  String get sectionWallpaper => 'Sfondo';

  @override
  String get contextWallpaper => 'Sfondo contestuale';

  @override
  String get contextWallpaperDesc =>
      'Una foto Unsplash che cambia con il momento: festività, viaggi, ora del giorno, musica. Solo dentro libreGLIDE: lo sfondo del telefono non viene toccato.';

  @override
  String get unsplashKey => 'Chiave Unsplash';

  @override
  String get unsplashKeyNone => 'Non impostata';

  @override
  String unsplashKeySet(Object hint) {
    return 'Impostata ($hint)';
  }

  @override
  String get unsplashKeyHelp =>
      'Crea un\'applicazione gratuita su unsplash.com/developers e incolla qui la sua Access Key. La chiave resta sul telefono.';

  @override
  String get unsplashGetKey => 'Ottieni una chiave';

  @override
  String get save => 'Salva';

  @override
  String get remove => 'Rimuovi';

  @override
  String get keyInvalid => 'Chiave non valida';

  @override
  String get keyCheckFailed =>
      'Impossibile verificare la chiave: controlla la connessione';

  @override
  String get changePhoto => 'Cambia foto';

  @override
  String changePhotoDesc(Object moment) {
    return 'Un\'altra foto per questo momento: $moment';
  }

  @override
  String get wallpaperLoading => 'Cerco una foto…';

  @override
  String get wallpaperError =>
      'Foto non disponibile: si vede lo sfondo del telefono';

  @override
  String get wallpaperNetworkNote =>
      'Usa Internet solo quando cambia il momento, con la tua chiave. Senza chiave libreGLIDE non si collega mai.';

  @override
  String get sectionGestures => 'Gesti';

  @override
  String get swipeDownAction => 'Swipe verso il basso';

  @override
  String get swipeUpAction => 'Swipe verso l\'alto';

  @override
  String get gestureSearch => 'Ricerca';

  @override
  String get gestureContacts => 'Contatti';

  @override
  String get gestureNone => 'Niente';

  @override
  String get gesturesDesc =>
      'Sulla Home e, per lo swipe in giù, anche sulla barra in alto.';

  @override
  String get collectionLabels => 'Nomi nelle Collections';

  @override
  String get collectionLabelsDesc =>
      'Mostra il nome sotto le icone anche nelle righe chiuse';

  @override
  String get contactsTitle => 'Contatti';

  @override
  String get contactsFavorites => 'Preferiti e più usati';

  @override
  String get contactsSearchHint => 'Cerca contatti';

  @override
  String get contactsPermission =>
      'Mostra qui i contatti preferiti e quelli che usi di più. I contatti vengono letti solo sul telefono.';

  @override
  String get contactsEmpty =>
      'Aggiungi una stella ai contatti preferiti nell\'app Contatti: compariranno qui, insieme a quelli che apri più spesso.';

  @override
  String get noContactsFound => 'Nessun contatto trovato';

  @override
  String get call => 'Chiama';

  @override
  String get message => 'Messaggio';

  @override
  String get openContact => 'Scheda contatto';

  @override
  String get searchCollections => 'Sfoglia le raccolte';

  @override
  String get cardEvening => 'Buonanotte';

  @override
  String get cardEveningDesc =>
      'Di sera: sveglia di domani, Non disturbare e promemoria di ricarica';

  @override
  String get dndOn => 'Non disturbare attivo';

  @override
  String chargeReminder(int level) {
    return 'Batteria al $level%: mettilo in carica per la notte';
  }

  @override
  String get cardNextPlace => 'Prossima destinazione';

  @override
  String get cardNextPlaceDesc =>
      'Indicazioni per il prossimo impegno con un luogo, nelle 3 ore prima';

  @override
  String get cardTravel => 'In viaggio';

  @override
  String get cardTravelDesc =>
      'Ora di casa e app di viaggio quando sei in un altro fuso orario o in roaming';

  @override
  String homeTime(Object time) {
    return 'A casa sono le $time';
  }

  @override
  String get travelHere => 'Ora vivo qui';

  @override
  String get autoLaunch => 'Apri da sola l\'unica app trovata';

  @override
  String get autoLaunchDesc =>
      'Quando resta una sola app che corrisponde a ciò che scrivi (almeno 2 lettere), si apre automaticamente.';

  @override
  String get sectionSearchGestures => 'Ricerca e gesti';

  @override
  String resultsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count risultati',
      one: '1 risultato',
    );
    return '$_temp0';
  }

  @override
  String get cardWidgets => 'Widget';

  @override
  String get cardWidgetsDesc => 'Widget Android a tutta larghezza nello Space';

  @override
  String get addWidget => 'Aggiungi widget';

  @override
  String get noWidgets => 'Nessun widget nello Space: aggiungine uno.';

  @override
  String get widgetHeight => 'Altezza';

  @override
  String get widgetShorter => 'Più basso';

  @override
  String get widgetTaller => 'Più alto';

  @override
  String get moveUp => 'Sposta su';

  @override
  String get moveDown => 'Sposta giù';

  @override
  String widgetMinSize(int w, int h) {
    return 'Minimo $w×$h dp';
  }

  @override
  String widgetCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count widget',
      one: '1 widget',
      zero: 'Nessun widget',
    );
    return '$_temp0';
  }

  @override
  String get cardWeather => 'Meteo';

  @override
  String get cardWeatherDesc =>
      'Previsioni da Open-Meteo con la posizione approssimativa, arrotondata a circa 10 km. Usa Internet.';

  @override
  String get weatherPermission =>
      'Per il meteo serve la posizione approssimativa: viene arrotondata a circa 10 km prima di chiedere le previsioni.';

  @override
  String get weatherHere => 'Qui';

  @override
  String get weatherSource => 'Dati meteo: Open-Meteo.com (CC BY 4.0)';

  @override
  String get weatherClear => 'Sereno';

  @override
  String get weatherPartly => 'Poco nuvoloso';

  @override
  String get weatherCloudy => 'Nuvoloso';

  @override
  String get weatherFog => 'Nebbia';

  @override
  String get weatherDrizzle => 'Pioviggine';

  @override
  String get weatherRain => 'Pioggia';

  @override
  String get weatherSnow => 'Neve';

  @override
  String get weatherShowers => 'Rovesci';

  @override
  String get weatherStorm => 'Temporale';

  @override
  String get cardCar => 'In auto';

  @override
  String get cardCarDesc =>
      'Mappe, musica e prossima destinazione quando guidi (Android Auto o autoradio Bluetooth)';

  @override
  String get carBluetooth => 'Riconosci l\'autoradio Bluetooth';

  @override
  String get carBluetoothDesc =>
      'Facoltativo: serve il permesso Dispositivi nelle vicinanze. Senza, funziona solo con Android Auto.';

  @override
  String get screenTime => 'Tempo di utilizzo';

  @override
  String get screenTimeDesc =>
      'Quanto hai usato il telefono oggi, come in Olauncher. Serve l\'accesso ai dati di utilizzo; i dati restano sul telefono.';

  @override
  String get screenTimeOff => 'Spento';

  @override
  String get screenTimeHome => 'Home';

  @override
  String get screenTimeSpace => 'Space';

  @override
  String get screenTimeToday => 'Oggi';

  @override
  String get screenTimePermission =>
      'Per mostrare il tempo di utilizzo serve l\'accesso ai dati di utilizzo. I dati restano sul telefono.';

  @override
  String durationHM(int h, int m) {
    return '$h h $m min';
  }

  @override
  String durationM(int m) {
    return '$m min';
  }

  @override
  String get spaceHome => 'Casa';

  @override
  String get spaceWork => 'Lavoro';

  @override
  String get spaceSchool => 'Scuola';

  @override
  String get spaceWorkOrSchool => 'Lavoro/Scuola';

  @override
  String get spaceMoving => 'In movimento';

  @override
  String get spaceListening => 'In ascolto';

  @override
  String get spaceTravel => 'In viaggio';

  @override
  String get spacesContext => 'Dal contesto';

  @override
  String get spacesTime => 'Dall\'ora del giorno';

  @override
  String get actionEmail => 'Email';

  @override
  String get actionToHome => 'Verso casa';

  @override
  String get actionToWork => 'Verso il lavoro';

  @override
  String get actionMaps => 'Mappe';

  @override
  String get sectionPlaces => 'Luoghi';

  @override
  String get placesEnabled => 'Riconosci casa e lavoro';

  @override
  String get placesEnabledDesc =>
      'Gli Space Casa e Lavoro/Scuola si attivano da soli. Usa la posizione precisa solo mentre usi il launcher e il Wi-Fi come impronta cifrata; tutto resta sul telefono.';

  @override
  String get placesPermission =>
      'Per riconoscere casa e lavoro serve la posizione precisa, solo mentre usi il launcher. Coordinate e reti Wi-Fi restano sul telefono e non vengono mai inviate.';

  @override
  String get placeHome => 'Casa';

  @override
  String get placeWork => 'Lavoro/Scuola';

  @override
  String placeRecognized(int percent) {
    return 'Riconosciuto ($percent%)';
  }

  @override
  String get placeByUser => 'Impostato da te';

  @override
  String get placeLearningHome => 'In apprendimento: servono alcune notti';

  @override
  String get placeLearningWork =>
      'In apprendimento: servono alcuni giorni feriali';

  @override
  String get workLabel => 'Nome dello Space di lavoro';

  @override
  String get workLabelAuto => 'Lavoro/Scuola';

  @override
  String get workLabelWork => 'Lavoro';

  @override
  String get workLabelSchool => 'Scuola';

  @override
  String get hereIsHome => 'Questa è casa mia';

  @override
  String get hereIsWork => 'Questo è il mio lavoro/scuola';

  @override
  String get notHome => 'Questa non è casa mia';

  @override
  String get notWork => 'Questo non è il mio lavoro/scuola';

  @override
  String get hereUnknown =>
      'Luogo attuale non ancora noto: torna qui dopo qualche minuto sul launcher.';

  @override
  String get resetPlaces => 'Reimposta i luoghi';

  @override
  String get resetPlacesConfirm =>
      'Dimenticare tutti i luoghi e i campioni di posizione? Casa e lavoro verranno riconosciuti di nuovo.';

  @override
  String placesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count luoghi',
      one: '1 luogo',
      zero: 'Nessun luogo',
    );
    return '$_temp0';
  }

  @override
  String get editHome => 'Modifica i widget';

  @override
  String homeWidgetsFull(int max) {
    return 'Al massimo $max widget sulla Home';
  }

  @override
  String get done => 'Fine';

  @override
  String widgetRows(int rows) {
    String _temp0 = intl.Intl.pluralLogic(
      rows,
      locale: localeName,
      other: '$rows righe',
      one: '1 riga',
    );
    return '$_temp0';
  }

  @override
  String get cardParking => 'Dove ho parcheggiato';

  @override
  String get cardParkingDesc =>
      'Quando ti scolleghi dall\'autoradio Bluetooth salva dove hai lasciato l\'auto. Usa la posizione in background solo in quel momento; resta sul telefono.';

  @override
  String parkedAt(Object time, Object ago) {
    return 'Parcheggiato alle $time · $ago';
  }

  @override
  String parkedImprecise(int meters) {
    return 'Posizione approssimativa ($meters m)';
  }

  @override
  String get forget => 'Dimentica';

  @override
  String agoMinutes(int m) {
    return '$m min fa';
  }

  @override
  String agoHours(int h) {
    return '$h h fa';
  }

  @override
  String get parkingNeedsBluetooth =>
      'Per riconoscere l\'auto serve il permesso Dispositivi nelle vicinanze.';

  @override
  String get parkingNeedsPrecise =>
      'Per salvare il punto serve la posizione precisa.';

  @override
  String get parkingNeedsBackground =>
      'Per salvare il punto quando scendi dall\'auto (con il telefono in tasca) serve la posizione \"Consenti sempre\". Viene usata solo allo scollegamento dall\'autoradio.';

  @override
  String get parkingWaiting =>
      'Il punto verrà salvato la prossima volta che ti scolleghi dall\'autoradio.';

  @override
  String get spaceAutomatic => 'Automatico';

  @override
  String get spaceNow => 'ora';

  @override
  String get workLabelBoth => 'Entrambi';

  @override
  String get groupLook => 'Aspetto e contenuti';

  @override
  String get groupBehavior => 'Comportamento';

  @override
  String get groupSystem => 'Sistema';

  @override
  String get stateOn => 'Attivo';

  @override
  String get stateOff => 'Spento';

  @override
  String cardsActive(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count card attive',
      one: '1 card attiva',
      zero: 'Nessuna card attiva',
    );
    return '$_temp0';
  }

  @override
  String get parkingBackgroundBlocked =>
      'Android non mostra più la richiesta. Apri le impostazioni dell\'app, poi Autorizzazioni › Posizione e scegli \"Consenti sempre\". La posizione viene letta solo quando ti scolleghi dall\'autoradio.';

  @override
  String get openSettings => 'Apri impostazioni';

  @override
  String get turnOff => 'Disattiva';

  @override
  String get obHowDetox =>
      'Digital detox (nelle impostazioni): blocca le app che ti distraggono, tutto il giorno o in una fascia oraria, con un PIN.';

  @override
  String get notNow => 'Non ora';

  @override
  String get ok => 'OK';

  @override
  String get detoxTitle => 'Digital detox';

  @override
  String get detoxDesc =>
      'Blocca le app che scegli, tutto il giorno o in una fascia oraria. Quando le apri compare una schermata nera.';

  @override
  String get detoxServiceTitle => 'Attiva il servizio di blocco';

  @override
  String get detoxServiceExplain =>
      'Per accorgersi di quando apri un\'app bloccata, libreGLIDE usa un servizio di accessibilità. Riceve solo il nome dell\'app che passa in primo piano: non legge lo schermo, non registra nulla e non consuma batteria quando non cambi app.\n\nNelle impostazioni che si aprono, attiva \"libreGLIDE · Digital detox\". Se Android lo mostra disattivato (\"impostazione con restrizioni\"), apri le informazioni dell\'app libreGLIDE, menu ⋮, \"Consenti impostazioni con restrizioni\".';

  @override
  String get detoxServiceOpen => 'Apri impostazioni';

  @override
  String get detoxServiceOff => 'Servizio di blocco non attivo';

  @override
  String get detoxServiceOffDesc =>
      'Le app si bloccano solo se aperte da libreGLIDE. Tocca per attivarlo.';

  @override
  String get detoxServiceOn => 'Servizio di blocco attivo';

  @override
  String get detoxActiveNow => 'Il blocco è attivo adesso.';

  @override
  String detoxStartsAt(String time) {
    return 'Il blocco parte alle $time.';
  }

  @override
  String get detoxPin => 'PIN';

  @override
  String get detoxSetPin => 'Imposta il PIN';

  @override
  String get detoxChangePin => 'Cambia il PIN';

  @override
  String get detoxPinDesc =>
      'Da 8 a 16 caratteri. Serve per sbloccare le app e per cambiare queste impostazioni mentre il detox è acceso.';

  @override
  String get detoxPinLabel => 'PIN';

  @override
  String get detoxOldPin => 'PIN attuale';

  @override
  String get detoxNewPin => 'Nuovo PIN';

  @override
  String get detoxConfirmPin => 'Conferma il PIN';

  @override
  String get detoxPinLength => 'Da 8 a 16 caratteri.';

  @override
  String get detoxPinMismatch => 'I due PIN non coincidono.';

  @override
  String get detoxPinWarning =>
      'Non perderlo: non si può recuperare. Senza PIN l\'unico modo per uscire dal detox è riavviare il telefono in modalità provvisoria.';

  @override
  String get detoxWrongPin => 'PIN sbagliato.';

  @override
  String detoxWait(int seconds) {
    return 'Troppi tentativi. Riprova tra $seconds s.';
  }

  @override
  String get detoxSchedule => 'Orario';

  @override
  String get detoxWhen => 'Quando';

  @override
  String get detoxAllDay => 'Tutto il giorno';

  @override
  String get detoxTimeRange => 'Fascia oraria';

  @override
  String get detoxFrom => 'Dalle';

  @override
  String get detoxTo => 'Alle';

  @override
  String get detoxUnlock => 'Sblocco';

  @override
  String get detoxUnlockTitle => 'Le app bloccate';

  @override
  String get detoxUnlockPin => 'Con il PIN';

  @override
  String get detoxUnlockNever => 'Mai';

  @override
  String get detoxUnlockPinDesc =>
      'Con il PIN l\'app resta aperta finché non la lasci.';

  @override
  String get detoxUnlockNeverDesc =>
      'Nessuno sblocco: si torna solo alla Home.';

  @override
  String get detoxApps => 'App';

  @override
  String get detoxLockedApps => 'App bloccate';

  @override
  String detoxAppsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count app',
      one: '1 app',
      zero: 'Nessuna app',
    );
    return '$_temp0';
  }

  @override
  String get detoxHide => 'Nascondi le app bloccate';

  @override
  String get detoxHideDesc =>
      'Durante il detox spariscono da Collections, A-Z, ricerca e dock. Restano separate dalle app nascoste: finito il detox tornano al loro posto.';

  @override
  String get detoxEmergency =>
      'Se blocchi Impostazioni, per spegnere il detox ti servirà il PIN qui in libreGLIDE. Se lo perdi, riavvia in modalità provvisoria: Android spegne i servizi di accessibilità.';

  @override
  String get detoxSystemGroup => 'Sistema';

  @override
  String get detoxSystemGroupDesc =>
      'Installazione e disinstallazione, Impostazioni, Play Store';

  @override
  String detoxGroupCount(int locked, int total) {
    return '$locked di $total bloccate';
  }

  @override
  String get frostedGlass => 'Vetro smerigliato';

  @override
  String get frostedGlassDesc =>
      'Space, Collections e A-Z diventano semitrasparenti sopra lo sfondo sfocato. La sfocatura la fa Android; in risparmio energetico le pagine tornano piene.';

  @override
  String get dockStyle => 'Dock';

  @override
  String get dockTray => 'Vassoio';

  @override
  String get dockTransparent => 'Trasparente';

  @override
  String get homeCorners => 'Angoli arrotondati sulla Home';

  @override
  String get homeCornersDesc =>
      'Barra e dock incorniciano lo sfondo con angoli appena arrotondati.';

  @override
  String get learnFromUsage => 'Impara anche dalle app aperte altrove';

  @override
  String get learnFromUsageDesc =>
      'Usa la cronologia di utilizzo di Android (notifiche, recenti, link) per suggerire le app giuste da subito. Resta sul telefono; spegnendo si cancella.';

  @override
  String get usageAccessNeeded => 'Consenti l\'accesso ai dati di utilizzo';

  @override
  String get usageAccessNeededDesc =>
      'Serve per leggere la cronologia di utilizzo di Android.';

  @override
  String launchSourcesNote(int usage) {
    return 'di cui $usage dalla cronologia di Android';
  }

  @override
  String get weatherTomorrow => 'Domani';

  @override
  String rainChance(int percent) {
    return 'Probabilità di pioggia $percent%';
  }

  @override
  String get actionAlarmTomorrow => 'Sveglia di domani';

  @override
  String get actionTimer => 'Timer';

  @override
  String get actionFood => 'Dove mangiare';

  @override
  String get foodQuery => 'ristoranti';

  @override
  String get cardShowHere => 'Mostra sempre in questo Space';

  @override
  String get cardHideHere => 'Nascondi in questo Space';

  @override
  String get cardAuto => 'Automatico (come prima)';

  @override
  String get cardCategory => 'App del momento';

  @override
  String get diagnosticsCards => 'Card dello Space';

  @override
  String get spaceCards => 'Card per Space';

  @override
  String get spaceCardsEntryDesc => 'Scegli quali card mostrare in ogni Space';

  @override
  String get spaceCardsDesc =>
      'Automatico segue il momento e il tuo uso. Sempre e Mai valgono solo per quello Space e vincono su tutto.';

  @override
  String spaceCardsCustom(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count scelte personali',
      one: '1 scelta personale',
    );
    return '$_temp0';
  }

  @override
  String get cardAutoShort => 'Automatico';

  @override
  String get cardAlways => 'Sempre';

  @override
  String get cardNever => 'Mai';

  @override
  String get cardDefaultShown => 'Di default visibile';

  @override
  String get cardDefaultHidden => 'Di default nascosta';

  @override
  String get manageSpaceCards => 'Gestisci le card di questo Space…';

  @override
  String unsplashKeyVerified(String suffix) {
    return 'Chiave verificata · $suffix';
  }
}
