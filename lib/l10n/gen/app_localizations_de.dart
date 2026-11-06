// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class L10nDe extends L10n {
  L10nDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'libreGLIDE';

  @override
  String get suggestionsTitle => 'Jetzt für dich';

  @override
  String get learningHint =>
      'libreGLIDE lernt deine Gewohnheiten: Vorgeschlagene Apps erscheinen nach ein paar Starts.';

  @override
  String get favoritesEmpty =>
      'Halte eine App gedrückt, um sie zu den Favoriten hinzuzufügen';

  @override
  String contextChip(Object slot, Object dayType) {
    return '$slot · $dayType';
  }

  @override
  String get notDefaultBanner => 'libreGLIDE ist noch nicht deine Start-App';

  @override
  String get setAction => 'Festlegen';

  @override
  String get slotWakeUp => 'Aufwachen';

  @override
  String get slotMorning => 'Morgen';

  @override
  String get slotLunch => 'Mittag';

  @override
  String get slotAfternoon => 'Nachmittag';

  @override
  String get slotEvening => 'Abend';

  @override
  String get slotNight => 'Nacht';

  @override
  String get dayWorkday => 'Werktag';

  @override
  String get dayHoliday => 'freier Tag';

  @override
  String get pageHome => 'Home';

  @override
  String get pageCollections => 'Collections';

  @override
  String get pageAllApps => 'Alle Apps';

  @override
  String appCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Apps',
      one: '1 App',
    );
    return '$_temp0';
  }

  @override
  String get pinCategory => 'Oben anheften';

  @override
  String get unpinCategory => 'Loslösen';

  @override
  String get hideCategory => 'Kategorie ausblenden';

  @override
  String get categoryHidden =>
      'Kategorie ausgeblendet. Du kannst sie in den Einstellungen wiederherstellen.';

  @override
  String get undo => 'Rückgängig';

  @override
  String get noCollections => 'Keine Apps zum Anzeigen';

  @override
  String get catSocial => 'Social Media';

  @override
  String get catMessaging => 'Nachrichten & Anrufe';

  @override
  String get catMusic => 'Musik & Audio';

  @override
  String get catVideo => 'Video';

  @override
  String get catPhoto => 'Fotos';

  @override
  String get catNews => 'News';

  @override
  String get catMaps => 'Karten & Reisen';

  @override
  String get catProductivity => 'Produktivität';

  @override
  String get catWork => 'Arbeit';

  @override
  String get catEducation => 'Lernen';

  @override
  String get catFinance => 'Finanzen';

  @override
  String get catShopping => 'Shopping';

  @override
  String get catFood => 'Essen';

  @override
  String get catHealth => 'Gesundheit & Fitness';

  @override
  String get catGames => 'Spiele';

  @override
  String get catTools => 'Tools';

  @override
  String get catSystem => 'System';

  @override
  String get catOther => 'Sonstiges';

  @override
  String get searchHint => 'Apps suchen';

  @override
  String get noResults => 'Keine Apps gefunden';

  @override
  String get layoutGrid => 'Raster';

  @override
  String get layoutList => 'Liste';

  @override
  String get addFavorite => 'Zu Favoriten hinzufügen';

  @override
  String get removeFavorite => 'Aus Favoriten entfernen';

  @override
  String favoritesFull(int max) {
    return 'Du kannst bis zu $max Favoriten haben';
  }

  @override
  String get changeCategory => 'Kategorie ändern';

  @override
  String get automaticCategory => 'Automatische Kategorie';

  @override
  String get hideApp => 'Ausblenden';

  @override
  String get appInfo => 'App-Info';

  @override
  String get uninstall => 'Deinstallieren';

  @override
  String appHidden(Object app) {
    return '$app ausgeblendet';
  }

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get sectionAppearance => 'Darstellung';

  @override
  String get theme => 'Design';

  @override
  String get themeSystem => 'Automatisch';

  @override
  String get themeLight => 'Hell';

  @override
  String get themeDark => 'Dunkel';

  @override
  String get colors => 'Farben';

  @override
  String get colorSource => 'Farbquelle';

  @override
  String get colorSystem => 'System';

  @override
  String get colorSystemDesc => 'Übernimmt die Farben von Android';

  @override
  String get colorPreset => 'Eigene Farbe';

  @override
  String get paletteStyle => 'Palettenstil';

  @override
  String get styleTonalSpot => 'Tonal';

  @override
  String get styleVibrant => 'Lebhaft';

  @override
  String get styleExpressive => 'Expressiv';

  @override
  String get styleNeutral => 'Neutral';

  @override
  String get styleMonochrome => 'Monochrom';

  @override
  String get contrast => 'Kontrast';

  @override
  String get contrastStandard => 'Standard';

  @override
  String get contrastMedium => 'Mittel';

  @override
  String get contrastHigh => 'Hoch';

  @override
  String get themedIcons => 'Designsymbole';

  @override
  String get themedIconsDesc =>
      'Einfarbige Symbole in den Farben der Palette (Android 13+)';

  @override
  String get preview => 'Vorschau';

  @override
  String get presetLaguna => 'Lagune';

  @override
  String get presetSalvia => 'Salbei';

  @override
  String get presetTerracotta => 'Terrakotta';

  @override
  String get presetAmbra => 'Bernstein';

  @override
  String get presetLampone => 'Himbeere';

  @override
  String get presetLavanda => 'Lavendel';

  @override
  String get presetPetrolio => 'Petrol';

  @override
  String get presetGrafite => 'Graphit';

  @override
  String get sectionApps => 'Apps';

  @override
  String get allAppsLayout => 'Ansicht „Alle Apps“';

  @override
  String get showSystemApps => 'System-Apps anzeigen';

  @override
  String get showSystemAppsDesc =>
      'Telefon, Kamera, Einstellungen und vorinstallierte Apps';

  @override
  String get hiddenApps => 'Ausgeblendete Apps';

  @override
  String get hiddenAppsEmpty => 'Keine ausgeblendeten Apps';

  @override
  String get restore => 'Wiederherstellen';

  @override
  String get fixedOrder => 'Feste Reihenfolge der Collections';

  @override
  String get fixedOrderDesc =>
      'Karten und Symbole nicht nach Kontext umsortieren';

  @override
  String get hiddenCategories => 'Ausgeblendete Kategorien';

  @override
  String get hiddenCategoriesEmpty => 'Keine ausgeblendeten Kategorien';

  @override
  String get sectionLanguage => 'Sprache';

  @override
  String get languageSystem => 'Systemsprache';

  @override
  String get sectionLauncher => 'Launcher';

  @override
  String get setDefault => 'libreGLIDE als Start-App festlegen';

  @override
  String get isDefault => 'libreGLIDE ist die Standard-Start-App';

  @override
  String get androidSettings => 'Android-Einstellungen';

  @override
  String get sectionData => 'Daten & Datenschutz';

  @override
  String launchesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Starts erfasst',
      one: '1 Start erfasst',
      zero: 'Keine Starts erfasst',
    );
    return '$_temp0';
  }

  @override
  String get privacyNote =>
      'Alle Daten bleiben auf dem Smartphone und verlassen es nur, wenn du sie exportierst. Die Datenbank ist von der Cloud-Sicherung ausgeschlossen.';

  @override
  String get clearHistory => 'Startverlauf löschen';

  @override
  String get clearHistoryConfirm =>
      'Verlauf löschen? Die Vorhersagen beginnen dann von vorn.';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get delete => 'Löschen';

  @override
  String get historyCleared => 'Verlauf gelöscht';

  @override
  String get diagnostics => 'Diagnose';

  @override
  String get diagnosticsDesc =>
      'Aktueller Kontext und warum Apps vorhergesagt werden';

  @override
  String get currentContext => 'Aktueller Kontext';

  @override
  String get predictions => 'Vorhersagen';

  @override
  String get noPredictions =>
      'Eine App braucht mindestens 3 Starts, um vorhergesagt zu werden.';

  @override
  String get sectionAbout => 'Über';

  @override
  String get aboutDesc => 'Kontextbezogener Open-Source-Launcher, rein lokal.';

  @override
  String get tabSpace => 'Space';

  @override
  String get tabCollections => 'Collections';

  @override
  String get tabAllApps => 'A-Z';

  @override
  String get spacesTitle => 'Spaces';

  @override
  String get azHeader => 'A-Z Apps';

  @override
  String get actionAlarm => 'Wecker';

  @override
  String get actionDnd => 'Bitte nicht stören';

  @override
  String get infoBanner =>
      'Hier erscheinen im Laufe des Tages nützliche Infos.';

  @override
  String get nowAppsHeader => 'Für diesen Moment';

  @override
  String get nextAlarm => 'Nächster Wecker';

  @override
  String get noAlarm => 'Kein Wecker gestellt';

  @override
  String get addToDock => 'Zum Dock hinzufügen';

  @override
  String get searchApps => 'Suchen';

  @override
  String get searchTopApps => 'Apps über der Suche';

  @override
  String get searchTopAppsDesc =>
      'Die in diesem Kontext meistgenutzten, über den Suchergebnissen.';

  @override
  String hiddenSummary(int apps, int categories) {
    return '$apps Apps, $categories Kategorien';
  }

  @override
  String get languageSystemShort => 'System';

  @override
  String version(Object version) {
    return 'Version $version';
  }

  @override
  String get agendaToday => 'Heute';

  @override
  String get agendaTomorrow => 'Morgen';

  @override
  String get noEventsToday => 'Heute keine Termine';

  @override
  String get noEventsTomorrow => 'Morgen keine Termine';

  @override
  String get allDay => 'Ganztägig';

  @override
  String get agendaPermission => 'Zeig hier deine nächsten Kalendertermine an.';

  @override
  String get allow => 'Zulassen';

  @override
  String get newEvent => 'Neuer Termin';

  @override
  String get navigate => 'Route';

  @override
  String get nowPlaying => 'Läuft gerade';

  @override
  String get mediaPermission =>
      'Steuere deine Musik von hier aus. Dafür ist Zugriff auf Benachrichtigungen nötig: libreGLIDE nutzt ihn nur für die Mediensteuerung und liest oder speichert nie Benachrichtigungen.';

  @override
  String get play => 'Abspielen';

  @override
  String get pause => 'Pause';

  @override
  String get next => 'Weiter';

  @override
  String get previous => 'Zurück';

  @override
  String get sectionSpace => 'Space';

  @override
  String get cardAgenda => 'Termine';

  @override
  String get cardAgendaDesc =>
      'Nächste Termine aus dem Kalender des Smartphones';

  @override
  String get cardMedia => 'Läuft gerade';

  @override
  String get cardMediaDesc =>
      'Steuerung der laufenden Musik, auch wenn du Kopfhörer anschließt';

  @override
  String get privacyPolicy => 'Datenschutzerklärung';

  @override
  String get privacyPolicyDesc => 'Was auf dem Smartphone bleibt und was nicht';

  @override
  String get openSource => 'Open-Source-Bibliotheken';

  @override
  String get openSourceDesc =>
      'Lizenzen der von libreGLIDE genutzten Komponenten';

  @override
  String openSourceCount(int count) {
    return '$count Komponenten';
  }

  @override
  String licenseCount(int count) {
    return '$count Lizenzen';
  }

  @override
  String get appLicense => 'Lizenz von libreGLIDE';

  @override
  String get appLicenseUndefined => 'Wird vor der Veröffentlichung festgelegt';

  @override
  String get unsplashAttribution =>
      'Die Fotos des kontextbezogenen Hintergrunds stammen von Unsplash-Fotografen, die auf Home genannt werden';

  @override
  String get showOnboarding => 'Einführung erneut anzeigen';

  @override
  String get obWelcomeTitle => 'Willkommen bei libreGLIDE';

  @override
  String get obWelcomeText =>
      'Der Launcher, der sich deinem Moment anpasst: Er zeigt dir die richtigen Apps und Infos, wenn du sie brauchst.';

  @override
  String get obStart => 'Los geht\'s';

  @override
  String get obNext => 'Weiter';

  @override
  String get obBack => 'Zurück';

  @override
  String get obHowTitle => 'So funktioniert\'s';

  @override
  String get obHowSpace =>
      'Der Space zeigt deine Termine, Musik und die Apps, die gerade passen.';

  @override
  String get obHowHome =>
      'Home lässt Platz für deinen Hintergrund, mit einem Dock deiner Lieblings-Apps.';

  @override
  String get obHowCollections =>
      'Collections gruppieren deine Apps automatisch und zeigen die, die du gerade nutzt, zuerst.';

  @override
  String get obHowSearch =>
      'Wisch nach oben, um eine App zu suchen, nach unten für deine Kontakte.';

  @override
  String get obHowDrawer =>
      'Tippe oben auf die farbigen Streifen, um einen Space auszuwählen.';

  @override
  String get obPrivacyTitle => 'Deine Privatsphäre';

  @override
  String get obPrivacy1 => 'Kein Konto, keine Werbung, keine Telemetrie.';

  @override
  String get obPrivacy2 =>
      'Deine Gewohnheiten bleiben auf dem Smartphone: Der Entwickler sieht sie nie.';

  @override
  String get obPrivacy3 =>
      'Internet nur, wenn du den Unsplash-Hintergrund mit deinem eigenen Schlüssel wählst.';

  @override
  String get obReadPolicy => 'Vollständige Erklärung lesen';

  @override
  String get obCollectionsTitle => 'Deine Sammlungen';

  @override
  String get obCollectionsText =>
      'Welche nutzt du am meisten? Sie bleiben in den ersten Wochen oben, danach zählt deine tatsächliche Nutzung.';

  @override
  String get obCollectionsHint =>
      'Wähl so viele du willst, oder keine. Die Reihenfolge der Auswahl zählt.';

  @override
  String get obFinishTitle => 'Letzter Schliff';

  @override
  String get obDockPrefill =>
      'Dock mit Telefon, Nachrichten, Kamera und Browser vorschlagen';

  @override
  String get obFinish => 'Fertig';

  @override
  String photoBy(Object name) {
    return 'Foto von $name · Unsplash';
  }

  @override
  String get sectionWallpaper => 'Hintergrund';

  @override
  String get contextWallpaper => 'Kontextbezogener Hintergrund';

  @override
  String get contextWallpaperDesc =>
      'Ein Unsplash-Foto, das sich mit dem Moment ändert: Feiertage, Reisen, Tageszeit, Musik. Nur in libreGLIDE: Der Hintergrund deines Smartphones bleibt unverändert.';

  @override
  String get unsplashKey => 'Unsplash-Schlüssel';

  @override
  String get unsplashKeyNone => 'Nicht festgelegt';

  @override
  String unsplashKeySet(Object hint) {
    return 'Festgelegt ($hint)';
  }

  @override
  String get unsplashKeyHelp =>
      'Erstelle eine kostenlose Anwendung auf unsplash.com/developers und füge hier ihren Access Key ein. Der Schlüssel bleibt auf dem Smartphone.';

  @override
  String get unsplashGetKey => 'Schlüssel holen';

  @override
  String get save => 'Speichern';

  @override
  String get remove => 'Entfernen';

  @override
  String get keyInvalid => 'Ungültiger Schlüssel';

  @override
  String get keyCheckFailed =>
      'Schlüssel konnte nicht geprüft werden: Prüfe deine Verbindung';

  @override
  String get changePhoto => 'Foto wechseln';

  @override
  String changePhotoDesc(Object moment) {
    return 'Ein anderes Foto für diesen Moment: $moment';
  }

  @override
  String get wallpaperLoading => 'Suche ein Foto…';

  @override
  String get wallpaperError =>
      'Foto nicht verfügbar: Der Hintergrund deines Smartphones wird angezeigt';

  @override
  String get wallpaperNetworkNote =>
      'Nutzt das Internet nur, wenn sich der Moment ändert, mit deinem Schlüssel. Ohne Schlüssel verbindet sich libreGLIDE nie.';

  @override
  String get sectionGestures => 'Gesten';

  @override
  String get swipeDownAction => 'Nach unten wischen';

  @override
  String get swipeUpAction => 'Nach oben wischen';

  @override
  String get gestureSearch => 'Suche';

  @override
  String get gestureContacts => 'Kontakte';

  @override
  String get gestureNone => 'Nichts';

  @override
  String get gesturesDesc =>
      'Auf Home und, beim Wischen nach unten, auch auf der oberen Leiste.';

  @override
  String get collectionLabels => 'Namen in Collections';

  @override
  String get collectionLabelsDesc =>
      'Namen unter den Symbolen auch in eingeklappten Zeilen anzeigen';

  @override
  String get contactsTitle => 'Kontakte';

  @override
  String get contactsFavorites => 'Favoriten und häufig genutzt';

  @override
  String get contactsSearchHint => 'Kontakte suchen';

  @override
  String get contactsPermission =>
      'Zeig hier deine Lieblings- und meistgenutzten Kontakte an. Kontakte werden nur auf dem Smartphone gelesen.';

  @override
  String get contactsEmpty =>
      'Markiere deine Lieblingskontakte in der Kontakte-App mit einem Stern: Sie erscheinen dann hier, zusammen mit denen, die du am häufigsten öffnest.';

  @override
  String get noContactsFound => 'Keine Kontakte gefunden';

  @override
  String get call => 'Anrufen';

  @override
  String get message => 'Nachricht';

  @override
  String get openContact => 'Kontaktdetails';

  @override
  String get searchCollections => 'Sammlungen durchsuchen';

  @override
  String get cardEvening => 'Gute Nacht';

  @override
  String get cardEveningDesc =>
      'Am Abend: Wecker für morgen, Bitte nicht stören und Erinnerung zum Laden';

  @override
  String get dndOn => 'Bitte nicht stören an';

  @override
  String chargeReminder(int level) {
    return 'Akku bei $level %: Lade ihn über Nacht';
  }

  @override
  String get cardNextPlace => 'Nächstes Ziel';

  @override
  String get cardNextPlaceDesc =>
      'Route zu deinem nächsten Termin mit Ort, in den 3 Stunden davor';

  @override
  String get cardTravel => 'Auf Reisen';

  @override
  String get cardTravelDesc =>
      'Uhrzeit zu Hause und Reise-Apps, wenn du in einer anderen Zeitzone oder im Roaming bist';

  @override
  String homeTime(Object time) {
    return 'Zu Hause ist es $time';
  }

  @override
  String get travelHere => 'Ich wohne jetzt hier';

  @override
  String get autoLaunch => 'Einzigen Treffer öffnen';

  @override
  String get autoLaunchDesc =>
      'Wenn nur eine App zu deiner Eingabe passt (mindestens 2 Buchstaben), wird sie automatisch geöffnet.';

  @override
  String get sectionSearchGestures => 'Suche & Gesten';

  @override
  String resultsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Ergebnisse',
      one: '1 Ergebnis',
    );
    return '$_temp0';
  }

  @override
  String get cardWidgets => 'Widgets';

  @override
  String get cardWidgetsDesc => 'Android-Widgets in voller Breite im Space';

  @override
  String get addWidget => 'Widget hinzufügen';

  @override
  String get noWidgets => 'Keine Widgets im Space: Füge eins hinzu.';

  @override
  String get widgetHeight => 'Höhe';

  @override
  String get widgetShorter => 'Niedriger';

  @override
  String get widgetTaller => 'Höher';

  @override
  String get moveUp => 'Nach oben';

  @override
  String get moveDown => 'Nach unten';

  @override
  String widgetMinSize(int w, int h) {
    return 'Mindestens $w×$h dp';
  }

  @override
  String widgetCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Widgets',
      one: '1 Widget',
      zero: 'Keine Widgets',
    );
    return '$_temp0';
  }

  @override
  String get cardWeather => 'Wetter';

  @override
  String get cardWeatherDesc =>
      'Vorhersage von Open-Meteo anhand deines ungefähren Standorts, auf etwa 10 km gerundet. Nutzt das Internet.';

  @override
  String get weatherPermission =>
      'Für das Wetter wird dein ungefährer Standort benötigt: Er wird auf etwa 10 km gerundet, bevor die Vorhersage abgefragt wird.';

  @override
  String get weatherHere => 'Hier';

  @override
  String get weatherSource => 'Wetterdaten: Open-Meteo.com (CC BY 4.0)';

  @override
  String get weatherClear => 'Klar';

  @override
  String get weatherPartly => 'Teilweise bewölkt';

  @override
  String get weatherCloudy => 'Bewölkt';

  @override
  String get weatherFog => 'Nebel';

  @override
  String get weatherDrizzle => 'Nieselregen';

  @override
  String get weatherRain => 'Regen';

  @override
  String get weatherSnow => 'Schnee';

  @override
  String get weatherShowers => 'Schauer';

  @override
  String get weatherStorm => 'Gewitter';

  @override
  String get cardCar => 'Im Auto';

  @override
  String get cardCarDesc =>
      'Karten, Musik und dein nächstes Ziel beim Fahren (Android Auto oder Bluetooth-Autoradio)';

  @override
  String get carBluetooth => 'Bluetooth-Autoradio erkennen';

  @override
  String get carBluetoothDesc =>
      'Optional: Benötigt die Berechtigung „Geräte in der Nähe“. Ohne sie wird nur Android Auto erkannt.';

  @override
  String get screenTime => 'Bildschirmzeit';

  @override
  String get screenTimeDesc =>
      'Wie lange du das Smartphone heute genutzt hast, wie in Olauncher. Benötigt Zugriff auf Nutzungsdaten; die Daten bleiben auf dem Smartphone.';

  @override
  String get screenTimeOff => 'Aus';

  @override
  String get screenTimeHome => 'Home';

  @override
  String get screenTimeSpace => 'Space';

  @override
  String get screenTimeToday => 'Heute';

  @override
  String get screenTimePermission =>
      'Für die Bildschirmzeit ist Zugriff auf Nutzungsdaten nötig. Die Daten bleiben auf dem Smartphone.';

  @override
  String durationHM(int h, int m) {
    return '$h Std. $m Min.';
  }

  @override
  String durationM(int m) {
    return '$m Min.';
  }

  @override
  String get spaceHome => 'Zuhause';

  @override
  String get spaceWork => 'Arbeit';

  @override
  String get spaceSchool => 'Schule';

  @override
  String get spaceWorkOrSchool => 'Arbeit/Schule';

  @override
  String get spaceMoving => 'Unterwegs';

  @override
  String get spaceListening => 'Musik hören';

  @override
  String get spaceTravel => 'Auf Reisen';

  @override
  String get spacesContext => 'Nach Kontext';

  @override
  String get spacesTime => 'Nach Tageszeit';

  @override
  String get actionEmail => 'E-Mail';

  @override
  String get actionToHome => 'Nach Hause';

  @override
  String get actionToWork => 'Zur Arbeit';

  @override
  String get actionMaps => 'Karten';

  @override
  String get sectionPlaces => 'Orte';

  @override
  String get placesEnabled => 'Zuhause und Arbeit erkennen';

  @override
  String get placesEnabledDesc =>
      'Die Spaces Zuhause und Arbeit/Schule schalten sich von selbst ein. Nutzt den genauen Standort nur, während du den Launcher verwendest, und Wi-Fi als verschlüsselten Fingerabdruck; alles bleibt auf dem Smartphone.';

  @override
  String get placesPermission =>
      'Um Zuhause und Arbeit zu erkennen, wird der genaue Standort nur während der Nutzung des Launchers benötigt. Koordinaten und Wi-Fi-Netze bleiben auf dem Smartphone und werden nie gesendet.';

  @override
  String get placeHome => 'Zuhause';

  @override
  String get placeWork => 'Arbeit/Schule';

  @override
  String placeRecognized(int percent) {
    return 'Erkannt ($percent %)';
  }

  @override
  String get placeByUser => 'Von dir festgelegt';

  @override
  String get placeLearningHome => 'Lernphase: Ein paar Nächte sind nötig';

  @override
  String get placeLearningWork => 'Lernphase: Ein paar Werktage sind nötig';

  @override
  String get workLabel => 'Name des Arbeits-Space';

  @override
  String get workLabelAuto => 'Arbeit/Schule';

  @override
  String get workLabelWork => 'Arbeit';

  @override
  String get workLabelSchool => 'Schule';

  @override
  String get hereIsHome => 'Hier wohne ich';

  @override
  String get hereIsWork => 'Hier arbeite/lerne ich';

  @override
  String get notHome => 'Hier wohne ich nicht';

  @override
  String get notWork => 'Hier arbeite/lerne ich nicht';

  @override
  String get hereUnknown =>
      'Aktueller Ort noch unbekannt: Schau nach ein paar Minuten im Launcher wieder vorbei.';

  @override
  String get resetPlaces => 'Orte zurücksetzen';

  @override
  String get resetPlacesConfirm =>
      'Alle Orte und Standortproben vergessen? Zuhause und Arbeit werden dann neu erkannt.';

  @override
  String placesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Orte',
      one: '1 Ort',
      zero: 'Keine Orte',
    );
    return '$_temp0';
  }

  @override
  String get editHome => 'Widgets bearbeiten';

  @override
  String homeWidgetsFull(int max) {
    return 'Bis zu $max Widgets auf Home';
  }

  @override
  String get done => 'Fertig';

  @override
  String widgetRows(int rows) {
    String _temp0 = intl.Intl.pluralLogic(
      rows,
      locale: localeName,
      other: '$rows Zeilen',
      one: '1 Zeile',
    );
    return '$_temp0';
  }

  @override
  String get cardParking => 'Wo ich geparkt habe';

  @override
  String get cardParkingDesc =>
      'Speichert beim Trennen vom Bluetooth-Autoradio, wo du das Auto abgestellt hast. Nutzt den Standort im Hintergrund nur in diesem Moment; er bleibt auf dem Smartphone.';

  @override
  String parkedAt(Object time, Object ago) {
    return 'Geparkt um $time · $ago';
  }

  @override
  String parkedImprecise(int meters) {
    return 'Ungefähre Position ($meters m)';
  }

  @override
  String get forget => 'Vergessen';

  @override
  String agoMinutes(int m) {
    return 'vor $m Min.';
  }

  @override
  String agoHours(int h) {
    return 'vor $h Std.';
  }

  @override
  String get parkingNeedsBluetooth =>
      'Um das Auto zu erkennen, wird die Berechtigung „Geräte in der Nähe“ benötigt.';

  @override
  String get parkingNeedsPrecise =>
      'Um den Parkplatz zu speichern, wird der genaue Standort benötigt.';

  @override
  String get parkingNeedsBackground =>
      'Um den Parkplatz beim Aussteigen zu speichern (Smartphone in der Tasche), wird der Standort mit \"Immer zulassen\" benötigt. Er wird nur beim Trennen vom Autoradio genutzt.';

  @override
  String get parkingWaiting =>
      'Der Parkplatz wird gespeichert, wenn du dich das nächste Mal vom Autoradio trennst.';

  @override
  String get spaceAutomatic => 'Automatisch';

  @override
  String get spaceNow => 'jetzt';

  @override
  String get workLabelBoth => 'Beides';

  @override
  String get groupLook => 'Aussehen & Inhalte';

  @override
  String get groupBehavior => 'Verhalten';

  @override
  String get groupSystem => 'System';

  @override
  String get stateOn => 'An';

  @override
  String get stateOff => 'Aus';

  @override
  String cardsActive(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count aktive Karten',
      one: '1 aktive Karte',
      zero: 'Keine aktiven Karten',
    );
    return '$_temp0';
  }

  @override
  String get parkingBackgroundBlocked =>
      'Android zeigt die Anfrage nicht mehr an. Öffne die App-Einstellungen, dann Berechtigungen › Standort, und wähle \"Immer zulassen\". Der Standort wird nur beim Trennen vom Autoradio gelesen.';

  @override
  String get openSettings => 'Einstellungen öffnen';

  @override
  String get turnOff => 'Deaktivieren';

  @override
  String get obHowDetox =>
      'Digital detox (in den Einstellungen): Sperrt ablenkende Apps per PIN, den ganzen Tag oder in einem Zeitraum.';

  @override
  String get notNow => 'Nicht jetzt';

  @override
  String get ok => 'OK';

  @override
  String get detoxTitle => 'Digital detox';

  @override
  String get detoxDesc =>
      'Sperrt die Apps deiner Wahl, den ganzen Tag oder in einem Zeitraum. Wenn du sie öffnest, erscheint ein schwarzer Bildschirm.';

  @override
  String get detoxServiceTitle => 'Sperrdienst aktivieren';

  @override
  String get detoxServiceExplain =>
      'Um zu erkennen, wann du eine gesperrte App öffnest, nutzt libreGLIDE einen Bedienungshilfendienst. Er erhält nur den Namen der App, die in den Vordergrund kommt: Er liest den Bildschirm nicht, zeichnet nichts auf und verbraucht keinen Akku, solange du nicht die App wechselst.\n\nAktiviere in den Einstellungen, die sich öffnen, \"libreGLIDE · Digital detox\". Wenn Android ihn als deaktiviert anzeigt (\"eingeschränkte Einstellung\"), öffne die App-Info von libreGLIDE, Menü ⋮, \"Eingeschränkte Einstellungen zulassen\".';

  @override
  String get detoxServiceOpen => 'Einstellungen öffnen';

  @override
  String get detoxServiceOff => 'Sperrdienst ist aus';

  @override
  String get detoxServiceOffDesc =>
      'Apps werden nur gesperrt, wenn sie über libreGLIDE geöffnet werden. Tippe, um ihn zu aktivieren.';

  @override
  String get detoxServiceOn => 'Sperrdienst ist an';

  @override
  String get detoxActiveNow => 'Die Sperre ist jetzt aktiv.';

  @override
  String detoxStartsAt(String time) {
    return 'Die Sperre beginnt um $time.';
  }

  @override
  String get detoxPin => 'PIN';

  @override
  String get detoxSetPin => 'PIN festlegen';

  @override
  String get detoxChangePin => 'PIN ändern';

  @override
  String get detoxPinDesc =>
      '8 bis 16 Zeichen. Wird benötigt, um Apps zu entsperren und diese Einstellungen bei aktivem Detox zu ändern.';

  @override
  String get detoxPinLabel => 'PIN';

  @override
  String get detoxOldPin => 'Aktuelle PIN';

  @override
  String get detoxNewPin => 'Neue PIN';

  @override
  String get detoxConfirmPin => 'PIN bestätigen';

  @override
  String get detoxPinLength => '8 bis 16 Zeichen.';

  @override
  String get detoxPinMismatch => 'Die beiden PINs stimmen nicht überein.';

  @override
  String get detoxPinWarning =>
      'Verlier sie nicht: Sie kann nicht wiederhergestellt werden. Ohne PIN kommst du nur aus dem Detox heraus, indem du das Smartphone im abgesicherten Modus neu startest.';

  @override
  String get detoxWrongPin => 'Falsche PIN.';

  @override
  String detoxWait(int seconds) {
    return 'Zu viele Versuche. Versuch es in $seconds s erneut.';
  }

  @override
  String get detoxSchedule => 'Zeitplan';

  @override
  String get detoxWhen => 'Wann';

  @override
  String get detoxAllDay => 'Ganztägig';

  @override
  String get detoxTimeRange => 'Zeitraum';

  @override
  String get detoxFrom => 'Von';

  @override
  String get detoxTo => 'Bis';

  @override
  String get detoxUnlock => 'Entsperren';

  @override
  String get detoxUnlockTitle => 'Gesperrte Apps';

  @override
  String get detoxUnlockPin => 'Mit PIN';

  @override
  String get detoxUnlockNever => 'Nie';

  @override
  String get detoxUnlockPinDesc =>
      'Mit der PIN bleibt die App geöffnet, bis du sie verlässt.';

  @override
  String get detoxUnlockNeverDesc =>
      'Kein Entsperren: Du kannst nur zurück zu Home.';

  @override
  String get detoxApps => 'Apps';

  @override
  String get detoxLockedApps => 'Gesperrte Apps';

  @override
  String detoxAppsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Apps',
      one: '1 App',
      zero: 'Keine Apps',
    );
    return '$_temp0';
  }

  @override
  String get detoxHide => 'Gesperrte Apps ausblenden';

  @override
  String get detoxHideDesc =>
      'Während des Detox verschwinden sie aus Collections, A-Z, Suche und Dock. Sie werden getrennt von ausgeblendeten Apps verwaltet: Nach dem Detox sind sie wieder an ihrem Platz.';

  @override
  String get detoxEmergency =>
      'Wenn du die Einstellungen sperrst, brauchst du die PIN hier in libreGLIDE, um den Detox auszuschalten. Falls du sie verlierst, starte im abgesicherten Modus neu: Android schaltet dann die Bedienungshilfendienste aus.';

  @override
  String get detoxSystemGroup => 'System';

  @override
  String get detoxSystemGroupDesc =>
      'Installieren und Deinstallieren, Einstellungen, Play Store';

  @override
  String detoxGroupCount(int locked, int total) {
    return '$locked von $total gesperrt';
  }

  @override
  String get frostedGlass => 'Milchglas';

  @override
  String get frostedGlassDesc =>
      'Space, Collections und A-Z werden über dem unscharfen Hintergrund durchscheinend. Android übernimmt die Unschärfe; im Energiesparmodus werden die Seiten wieder deckend.';

  @override
  String get dockStyle => 'Dock';

  @override
  String get dockTray => 'Fläche';

  @override
  String get dockTransparent => 'Transparent';

  @override
  String get homeCorners => 'Abgerundete Ecken auf Home';

  @override
  String get homeCornersDesc =>
      'Leiste und Dock rahmen den Hintergrund mit leicht abgerundeten Ecken ein.';

  @override
  String get learnFromUsage => 'Auch aus anderswo geöffneten Apps lernen';

  @override
  String get learnFromUsageDesc =>
      'Nutzt den Android-Nutzungsverlauf (Benachrichtigungen, zuletzt verwendet, Links), um sofort passende Apps vorzuschlagen. Bleibt auf dem Gerät; beim Ausschalten wird er gelöscht.';

  @override
  String get usageAccessNeeded => 'Zugriff auf Nutzungsdaten erlauben';

  @override
  String get usageAccessNeededDesc =>
      'Wird benötigt, um den Android-Nutzungsverlauf zu lesen.';

  @override
  String launchSourcesNote(int usage) {
    return 'davon $usage aus dem Android-Verlauf';
  }

  @override
  String get weatherTomorrow => 'Morgen';

  @override
  String rainChance(int percent) {
    return 'Regenwahrscheinlichkeit $percent %';
  }

  @override
  String get actionAlarmTomorrow => 'Wecker für morgen';

  @override
  String get actionTimer => 'Timer';

  @override
  String get actionFood => 'Essen gehen';

  @override
  String get foodQuery => 'Restaurants';

  @override
  String get cardShowHere => 'In diesem Space immer zeigen';

  @override
  String get cardHideHere => 'In diesem Space ausblenden';

  @override
  String get cardAuto => 'Automatisch (wie vorher)';

  @override
  String get cardCategory => 'Apps für den Moment';

  @override
  String get diagnosticsCards => 'Space-Karten';

  @override
  String get spaceCards => 'Karten pro Space';

  @override
  String get spaceCardsEntryDesc => 'Wähle, welche Karten jeder Space zeigt';

  @override
  String get spaceCardsDesc =>
      'Automatisch folgt dem Moment und deiner Nutzung. Immer und Nie gelten nur für diesen Space und haben Vorrang.';

  @override
  String spaceCardsCustom(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count eigene Auswahlen',
      one: '1 eigene Auswahl',
    );
    return '$_temp0';
  }

  @override
  String get cardAutoShort => 'Automatisch';

  @override
  String get cardAlways => 'Immer';

  @override
  String get cardNever => 'Nie';

  @override
  String get cardDefaultShown => 'Standardmäßig sichtbar';

  @override
  String get cardDefaultHidden => 'Standardmäßig ausgeblendet';

  @override
  String get manageSpaceCards => 'Karten dieses Space verwalten…';

  @override
  String unsplashKeyVerified(String suffix) {
    return 'Schlüssel geprüft · $suffix';
  }
}
