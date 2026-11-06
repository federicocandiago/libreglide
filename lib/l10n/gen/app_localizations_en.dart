// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class L10nEn extends L10n {
  L10nEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'libreGLIDE';

  @override
  String get suggestionsTitle => 'For you now';

  @override
  String get learningHint =>
      'libreGLIDE is learning your habits: suggested apps will appear after a few launches.';

  @override
  String get favoritesEmpty => 'Long-press an app to add it to favorites';

  @override
  String contextChip(Object slot, Object dayType) {
    return '$slot · $dayType';
  }

  @override
  String get notDefaultBanner => 'libreGLIDE is not your Home app yet';

  @override
  String get setAction => 'Set';

  @override
  String get slotWakeUp => 'Wake-up';

  @override
  String get slotMorning => 'Morning';

  @override
  String get slotLunch => 'Lunch';

  @override
  String get slotAfternoon => 'Afternoon';

  @override
  String get slotEvening => 'Evening';

  @override
  String get slotNight => 'Night';

  @override
  String get dayWorkday => 'workday';

  @override
  String get dayHoliday => 'day off';

  @override
  String get pageHome => 'Home';

  @override
  String get pageCollections => 'Collections';

  @override
  String get pageAllApps => 'All apps';

  @override
  String appCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count apps',
      one: '1 app',
    );
    return '$_temp0';
  }

  @override
  String get pinCategory => 'Pin to top';

  @override
  String get unpinCategory => 'Unpin';

  @override
  String get hideCategory => 'Hide category';

  @override
  String get categoryHidden =>
      'Category hidden. You can restore it in settings.';

  @override
  String get undo => 'Undo';

  @override
  String get noCollections => 'No apps to show';

  @override
  String get catSocial => 'Social';

  @override
  String get catMessaging => 'Messages & calls';

  @override
  String get catMusic => 'Music & audio';

  @override
  String get catVideo => 'Video';

  @override
  String get catPhoto => 'Photos';

  @override
  String get catNews => 'News';

  @override
  String get catMaps => 'Maps & travel';

  @override
  String get catProductivity => 'Productivity';

  @override
  String get catWork => 'Work';

  @override
  String get catEducation => 'Study';

  @override
  String get catFinance => 'Finance';

  @override
  String get catShopping => 'Shopping';

  @override
  String get catFood => 'Food';

  @override
  String get catHealth => 'Health & fitness';

  @override
  String get catGames => 'Games';

  @override
  String get catTools => 'Tools';

  @override
  String get catSystem => 'System';

  @override
  String get catOther => 'Other';

  @override
  String get searchHint => 'Search apps';

  @override
  String get noResults => 'No apps found';

  @override
  String get layoutGrid => 'Grid';

  @override
  String get layoutList => 'List';

  @override
  String get addFavorite => 'Add to favorites';

  @override
  String get removeFavorite => 'Remove from favorites';

  @override
  String favoritesFull(int max) {
    return 'You can have up to $max favorites';
  }

  @override
  String get changeCategory => 'Change category';

  @override
  String get automaticCategory => 'Automatic category';

  @override
  String get hideApp => 'Hide';

  @override
  String get appInfo => 'App info';

  @override
  String get uninstall => 'Uninstall';

  @override
  String appHidden(Object app) {
    return '$app hidden';
  }

  @override
  String get settingsTitle => 'Settings';

  @override
  String get sectionAppearance => 'Appearance';

  @override
  String get theme => 'Theme';

  @override
  String get themeSystem => 'Automatic';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get colors => 'Colors';

  @override
  String get colorSource => 'Color source';

  @override
  String get colorSystem => 'System';

  @override
  String get colorSystemDesc => 'Follows Android\'s colors';

  @override
  String get colorPreset => 'Chosen color';

  @override
  String get paletteStyle => 'Palette style';

  @override
  String get styleTonalSpot => 'Tonal';

  @override
  String get styleVibrant => 'Vibrant';

  @override
  String get styleExpressive => 'Expressive';

  @override
  String get styleNeutral => 'Neutral';

  @override
  String get styleMonochrome => 'Monochrome';

  @override
  String get contrast => 'Contrast';

  @override
  String get contrastStandard => 'Standard';

  @override
  String get contrastMedium => 'Medium';

  @override
  String get contrastHigh => 'High';

  @override
  String get themedIcons => 'Themed icons';

  @override
  String get themedIconsDesc =>
      'Monochrome icons tinted with the palette (Android 13+)';

  @override
  String get preview => 'Preview';

  @override
  String get presetLaguna => 'Lagoon';

  @override
  String get presetSalvia => 'Sage';

  @override
  String get presetTerracotta => 'Terracotta';

  @override
  String get presetAmbra => 'Amber';

  @override
  String get presetLampone => 'Raspberry';

  @override
  String get presetLavanda => 'Lavender';

  @override
  String get presetPetrolio => 'Teal';

  @override
  String get presetGrafite => 'Graphite';

  @override
  String get sectionApps => 'Apps';

  @override
  String get allAppsLayout => 'All apps view';

  @override
  String get showSystemApps => 'Show system apps';

  @override
  String get showSystemAppsDesc =>
      'Phone, Camera, Settings and preinstalled apps';

  @override
  String get hiddenApps => 'Hidden apps';

  @override
  String get hiddenAppsEmpty => 'No hidden apps';

  @override
  String get restore => 'Restore';

  @override
  String get fixedOrder => 'Fixed Collections order';

  @override
  String get fixedOrderDesc => 'Don\'t reorder cards and icons by context';

  @override
  String get hiddenCategories => 'Hidden categories';

  @override
  String get hiddenCategoriesEmpty => 'No hidden categories';

  @override
  String get sectionLanguage => 'Language';

  @override
  String get languageSystem => 'System language';

  @override
  String get sectionLauncher => 'Launcher';

  @override
  String get setDefault => 'Set libreGLIDE as Home app';

  @override
  String get isDefault => 'libreGLIDE is the default Home app';

  @override
  String get androidSettings => 'Android settings';

  @override
  String get sectionData => 'Data & privacy';

  @override
  String launchesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count launches recorded',
      one: '1 launch recorded',
      zero: 'No launches recorded',
    );
    return '$_temp0';
  }

  @override
  String get privacyNote =>
      'All data stays on the phone and leaves it only if you export it. The database is excluded from cloud backup.';

  @override
  String get clearHistory => 'Clear launch history';

  @override
  String get clearHistoryConfirm =>
      'Clear history? Predictions will start from scratch.';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Clear';

  @override
  String get historyCleared => 'History cleared';

  @override
  String get diagnostics => 'Diagnostics';

  @override
  String get diagnosticsDesc => 'Current context and why apps are predicted';

  @override
  String get currentContext => 'Current context';

  @override
  String get predictions => 'Predictions';

  @override
  String get noPredictions =>
      'An app needs at least 3 launches to be predicted.';

  @override
  String get sectionAbout => 'About';

  @override
  String get aboutDesc => 'Open source, local-only contextual launcher.';

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
  String get actionAlarm => 'Alarm';

  @override
  String get actionDnd => 'Do not disturb';

  @override
  String get infoBanner =>
      'Useful information will appear here throughout the day.';

  @override
  String get nowAppsHeader => 'For this moment';

  @override
  String get nextAlarm => 'Next alarm';

  @override
  String get noAlarm => 'No alarm set';

  @override
  String get addToDock => 'Add to dock';

  @override
  String get searchApps => 'Search';

  @override
  String get searchTopApps => 'Apps above search';

  @override
  String get searchTopAppsDesc =>
      'The most used in this context, above the search results.';

  @override
  String hiddenSummary(int apps, int categories) {
    return '$apps apps, $categories categories';
  }

  @override
  String get languageSystemShort => 'System';

  @override
  String version(Object version) {
    return 'Version $version';
  }

  @override
  String get agendaToday => 'Today';

  @override
  String get agendaTomorrow => 'Tomorrow';

  @override
  String get noEventsToday => 'No events today';

  @override
  String get noEventsTomorrow => 'No events tomorrow';

  @override
  String get allDay => 'All day';

  @override
  String get agendaPermission => 'Show your upcoming calendar events here.';

  @override
  String get allow => 'Allow';

  @override
  String get newEvent => 'New event';

  @override
  String get navigate => 'Directions';

  @override
  String get nowPlaying => 'Now playing';

  @override
  String get mediaPermission =>
      'Control your music from here. Notification access is needed: libreGLIDE uses it only for media controls and never reads or stores notifications.';

  @override
  String get play => 'Play';

  @override
  String get pause => 'Pause';

  @override
  String get next => 'Next';

  @override
  String get previous => 'Previous';

  @override
  String get sectionSpace => 'Space';

  @override
  String get cardAgenda => 'Agenda';

  @override
  String get cardAgendaDesc => 'Upcoming events from the phone\'s calendar';

  @override
  String get cardMedia => 'Now playing';

  @override
  String get cardMediaDesc =>
      'Controls for the music that\'s playing, also when you plug in headphones';

  @override
  String get privacyPolicy => 'Privacy policy';

  @override
  String get privacyPolicyDesc => 'What stays on the phone and what doesn\'t';

  @override
  String get openSource => 'Open source libraries';

  @override
  String get openSourceDesc => 'Licenses of the components used by libreGLIDE';

  @override
  String openSourceCount(int count) {
    return '$count components';
  }

  @override
  String licenseCount(int count) {
    return '$count licenses';
  }

  @override
  String get appLicense => 'libreGLIDE license';

  @override
  String get appLicenseUndefined => 'To be defined before release';

  @override
  String get unsplashAttribution =>
      'Contextual wallpaper photos are by Unsplash authors, credited on Home';

  @override
  String get showOnboarding => 'Show the introduction again';

  @override
  String get obWelcomeTitle => 'Welcome to libreGLIDE';

  @override
  String get obWelcomeText =>
      'The launcher that changes with your moment: it shows the right apps and information when you need them.';

  @override
  String get obStart => 'Start';

  @override
  String get obNext => 'Next';

  @override
  String get obBack => 'Back';

  @override
  String get obHowTitle => 'How it works';

  @override
  String get obHowSpace =>
      'The Space shows your agenda, music and the apps that fit this moment.';

  @override
  String get obHowHome =>
      'Home leaves room for your wallpaper, with a dock of your favorite apps.';

  @override
  String get obHowCollections =>
      'Collections group your apps automatically and put the ones you use now first.';

  @override
  String get obHowSearch =>
      'Swipe up to search for an app, down for your contacts.';

  @override
  String get obHowDrawer =>
      'Tap the colored stripes at the top to pick a Space.';

  @override
  String get obPrivacyTitle => 'Your privacy';

  @override
  String get obPrivacy1 => 'No account, no ads, no telemetry.';

  @override
  String get obPrivacy2 =>
      'Your habits stay on the phone: the developer never sees them.';

  @override
  String get obPrivacy3 =>
      'Internet only if you choose the Unsplash wallpaper with your own key.';

  @override
  String get obReadPolicy => 'Read the full policy';

  @override
  String get obCollectionsTitle => 'Your collections';

  @override
  String get obCollectionsText =>
      'Which ones do you use most? They will stay on top for the first weeks, then your real usage takes over.';

  @override
  String get obCollectionsHint =>
      'Pick as many as you like, or none. The order you pick them in matters.';

  @override
  String get obFinishTitle => 'Final touches';

  @override
  String get obDockPrefill =>
      'Suggest a dock with phone, messages, camera and browser';

  @override
  String get obFinish => 'Done';

  @override
  String photoBy(Object name) {
    return 'Photo by $name · Unsplash';
  }

  @override
  String get sectionWallpaper => 'Wallpaper';

  @override
  String get contextWallpaper => 'Contextual wallpaper';

  @override
  String get contextWallpaperDesc =>
      'An Unsplash photo that changes with the moment: holidays, travel, time of day, music. Only inside libreGLIDE: your phone\'s wallpaper is never touched.';

  @override
  String get unsplashKey => 'Unsplash key';

  @override
  String get unsplashKeyNone => 'Not set';

  @override
  String unsplashKeySet(Object hint) {
    return 'Set ($hint)';
  }

  @override
  String get unsplashKeyHelp =>
      'Create a free application at unsplash.com/developers and paste its Access Key here. The key stays on the phone.';

  @override
  String get unsplashGetKey => 'Get a key';

  @override
  String get save => 'Save';

  @override
  String get remove => 'Remove';

  @override
  String get keyInvalid => 'Invalid key';

  @override
  String get keyCheckFailed =>
      'Couldn\'t verify the key: check your connection';

  @override
  String get changePhoto => 'Change photo';

  @override
  String changePhotoDesc(Object moment) {
    return 'Another photo for this moment: $moment';
  }

  @override
  String get wallpaperLoading => 'Looking for a photo…';

  @override
  String get wallpaperError =>
      'Photo not available: your phone\'s wallpaper is shown';

  @override
  String get wallpaperNetworkNote =>
      'Uses the Internet only when the moment changes, with your key. Without a key libreGLIDE never connects.';

  @override
  String get sectionGestures => 'Gestures';

  @override
  String get swipeDownAction => 'Swipe down';

  @override
  String get swipeUpAction => 'Swipe up';

  @override
  String get gestureSearch => 'Search';

  @override
  String get gestureContacts => 'Contacts';

  @override
  String get gestureNone => 'Nothing';

  @override
  String get gesturesDesc =>
      'On Home and, for swipe down, also on the top bar.';

  @override
  String get collectionLabels => 'Names in Collections';

  @override
  String get collectionLabelsDesc =>
      'Show names under icons also in collapsed rows';

  @override
  String get contactsTitle => 'Contacts';

  @override
  String get contactsFavorites => 'Favorites and most used';

  @override
  String get contactsSearchHint => 'Search contacts';

  @override
  String get contactsPermission =>
      'Show your favorite and most used contacts here. Contacts are read only on the phone.';

  @override
  String get contactsEmpty =>
      'Star your favorite contacts in the Contacts app: they\'ll show up here, along with the ones you open most.';

  @override
  String get noContactsFound => 'No contacts found';

  @override
  String get call => 'Call';

  @override
  String get message => 'Message';

  @override
  String get openContact => 'Contact details';

  @override
  String get searchCollections => 'Browse collections';

  @override
  String get cardEvening => 'Good night';

  @override
  String get cardEveningDesc =>
      'In the evening: tomorrow\'s alarm, Do not disturb and a charging reminder';

  @override
  String get dndOn => 'Do not disturb on';

  @override
  String chargeReminder(int level) {
    return 'Battery at $level%: charge it overnight';
  }

  @override
  String get cardNextPlace => 'Next destination';

  @override
  String get cardNextPlaceDesc =>
      'Directions to your next event with a place, in the 3 hours before';

  @override
  String get cardTravel => 'Travelling';

  @override
  String get cardTravelDesc =>
      'Home time and travel apps when you\'re in another time zone or roaming';

  @override
  String homeTime(Object time) {
    return 'At home it\'s $time';
  }

  @override
  String get travelHere => 'I live here now';

  @override
  String get autoLaunch => 'Open the only matching app';

  @override
  String get autoLaunchDesc =>
      'When only one app matches what you type (at least 2 letters), it opens automatically.';

  @override
  String get sectionSearchGestures => 'Search & gestures';

  @override
  String resultsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count results',
      one: '1 result',
    );
    return '$_temp0';
  }

  @override
  String get cardWidgets => 'Widgets';

  @override
  String get cardWidgetsDesc => 'Full-width Android widgets in the Space';

  @override
  String get addWidget => 'Add widget';

  @override
  String get noWidgets => 'No widgets in the Space: add one.';

  @override
  String get widgetHeight => 'Height';

  @override
  String get widgetShorter => 'Shorter';

  @override
  String get widgetTaller => 'Taller';

  @override
  String get moveUp => 'Move up';

  @override
  String get moveDown => 'Move down';

  @override
  String widgetMinSize(int w, int h) {
    return 'At least $w×$h dp';
  }

  @override
  String widgetCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count widgets',
      one: '1 widget',
      zero: 'No widgets',
    );
    return '$_temp0';
  }

  @override
  String get cardWeather => 'Weather';

  @override
  String get cardWeatherDesc =>
      'Forecast from Open-Meteo using your approximate location, rounded to about 10 km. Uses the Internet.';

  @override
  String get weatherPermission =>
      'Weather needs your approximate location: it\'s rounded to about 10 km before asking for the forecast.';

  @override
  String get weatherHere => 'Here';

  @override
  String get weatherSource => 'Weather data: Open-Meteo.com (CC BY 4.0)';

  @override
  String get weatherClear => 'Clear';

  @override
  String get weatherPartly => 'Partly cloudy';

  @override
  String get weatherCloudy => 'Cloudy';

  @override
  String get weatherFog => 'Fog';

  @override
  String get weatherDrizzle => 'Drizzle';

  @override
  String get weatherRain => 'Rain';

  @override
  String get weatherSnow => 'Snow';

  @override
  String get weatherShowers => 'Showers';

  @override
  String get weatherStorm => 'Thunderstorm';

  @override
  String get cardCar => 'In the car';

  @override
  String get cardCarDesc =>
      'Maps, music and your next destination while driving (Android Auto or Bluetooth car stereo)';

  @override
  String get carBluetooth => 'Recognize the Bluetooth car stereo';

  @override
  String get carBluetoothDesc =>
      'Optional: needs the Nearby devices permission. Without it, only Android Auto is recognized.';

  @override
  String get screenTime => 'Screen time';

  @override
  String get screenTimeDesc =>
      'How much you used the phone today, like in Olauncher. Needs usage access; data stays on the phone.';

  @override
  String get screenTimeOff => 'Off';

  @override
  String get screenTimeHome => 'Home';

  @override
  String get screenTimeSpace => 'Space';

  @override
  String get screenTimeToday => 'Today';

  @override
  String get screenTimePermission =>
      'To show screen time, usage access is needed. Data stays on the phone.';

  @override
  String durationHM(int h, int m) {
    return '$h h $m min';
  }

  @override
  String durationM(int m) {
    return '$m min';
  }

  @override
  String get spaceHome => 'Home';

  @override
  String get spaceWork => 'Work';

  @override
  String get spaceSchool => 'School';

  @override
  String get spaceWorkOrSchool => 'Work/School';

  @override
  String get spaceMoving => 'On the move';

  @override
  String get spaceListening => 'Listening';

  @override
  String get spaceTravel => 'Travelling';

  @override
  String get spacesContext => 'From context';

  @override
  String get spacesTime => 'From time of day';

  @override
  String get actionEmail => 'Email';

  @override
  String get actionToHome => 'Go home';

  @override
  String get actionToWork => 'Go to work';

  @override
  String get actionMaps => 'Maps';

  @override
  String get sectionPlaces => 'Places';

  @override
  String get placesEnabled => 'Recognize home and work';

  @override
  String get placesEnabledDesc =>
      'The Home and Work/School Spaces turn on by themselves. Uses precise location only while you use the launcher, and Wi-Fi as an encrypted fingerprint; everything stays on the phone.';

  @override
  String get placesPermission =>
      'To recognize home and work, precise location is needed only while you use the launcher. Coordinates and Wi-Fi networks stay on the phone and are never sent.';

  @override
  String get placeHome => 'Home';

  @override
  String get placeWork => 'Work/School';

  @override
  String placeRecognized(int percent) {
    return 'Recognized ($percent%)';
  }

  @override
  String get placeByUser => 'Set by you';

  @override
  String get placeLearningHome => 'Learning: a few nights are needed';

  @override
  String get placeLearningWork => 'Learning: a few workdays are needed';

  @override
  String get workLabel => 'Name of the work Space';

  @override
  String get workLabelAuto => 'Work/School';

  @override
  String get workLabelWork => 'Work';

  @override
  String get workLabelSchool => 'School';

  @override
  String get hereIsHome => 'This is my home';

  @override
  String get hereIsWork => 'This is my work/school';

  @override
  String get notHome => 'This is not my home';

  @override
  String get notWork => 'This is not my work/school';

  @override
  String get hereUnknown =>
      'Current place not known yet: come back after a few minutes on the launcher.';

  @override
  String get resetPlaces => 'Reset places';

  @override
  String get resetPlacesConfirm =>
      'Forget all places and location samples? Home and work will be recognized again.';

  @override
  String placesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count places',
      one: '1 place',
      zero: 'No places',
    );
    return '$_temp0';
  }

  @override
  String get editHome => 'Edit widgets';

  @override
  String homeWidgetsFull(int max) {
    return 'Up to $max widgets on Home';
  }

  @override
  String get done => 'Done';

  @override
  String widgetRows(int rows) {
    String _temp0 = intl.Intl.pluralLogic(
      rows,
      locale: localeName,
      other: '$rows rows',
      one: '1 row',
    );
    return '$_temp0';
  }

  @override
  String get cardParking => 'Where I parked';

  @override
  String get cardParkingDesc =>
      'When you disconnect from the Bluetooth car stereo, saves where you left the car. Uses background location only at that moment; it stays on the phone.';

  @override
  String parkedAt(Object time, Object ago) {
    return 'Parked at $time · $ago';
  }

  @override
  String parkedImprecise(int meters) {
    return 'Approximate position ($meters m)';
  }

  @override
  String get forget => 'Forget';

  @override
  String agoMinutes(int m) {
    return '$m min ago';
  }

  @override
  String agoHours(int h) {
    return '$h h ago';
  }

  @override
  String get parkingNeedsBluetooth =>
      'To recognize the car, the Nearby devices permission is needed.';

  @override
  String get parkingNeedsPrecise =>
      'To save the spot, precise location is needed.';

  @override
  String get parkingNeedsBackground =>
      'To save the spot when you get out of the car (phone in your pocket), location \"Allow all the time\" is needed. It\'s used only when disconnecting from the car stereo.';

  @override
  String get parkingWaiting =>
      'The spot will be saved the next time you disconnect from the car stereo.';

  @override
  String get spaceAutomatic => 'Automatic';

  @override
  String get spaceNow => 'now';

  @override
  String get workLabelBoth => 'Both';

  @override
  String get groupLook => 'Look & content';

  @override
  String get groupBehavior => 'Behavior';

  @override
  String get groupSystem => 'System';

  @override
  String get stateOn => 'On';

  @override
  String get stateOff => 'Off';

  @override
  String cardsActive(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count active cards',
      one: '1 active card',
      zero: 'No active cards',
    );
    return '$_temp0';
  }

  @override
  String get parkingBackgroundBlocked =>
      'Android no longer shows the request. Open the app settings, then Permissions › Location and choose \"Allow all the time\". Location is read only when you disconnect from the car stereo.';

  @override
  String get openSettings => 'Open settings';

  @override
  String get turnOff => 'Turn off';

  @override
  String get obHowDetox =>
      'Digital detox (in settings): locks the apps that distract you, all day or in a time range, with a PIN.';

  @override
  String get notNow => 'Not now';

  @override
  String get ok => 'OK';

  @override
  String get detoxTitle => 'Digital detox';

  @override
  String get detoxDesc =>
      'Locks the apps you choose, all day or in a time range. When you open them a black screen appears.';

  @override
  String get detoxServiceTitle => 'Turn on the lock service';

  @override
  String get detoxServiceExplain =>
      'To notice when you open a locked app, libreGLIDE uses an accessibility service. It receives only the name of the app coming to the foreground: it doesn\'t read the screen, records nothing and uses no battery when you don\'t switch apps.\n\nIn the settings that open, turn on \"libreGLIDE · Digital detox\". If Android shows it disabled (\"restricted setting\"), open libreGLIDE\'s app info, ⋮ menu, \"Allow restricted settings\".';

  @override
  String get detoxServiceOpen => 'Open settings';

  @override
  String get detoxServiceOff => 'Lock service is off';

  @override
  String get detoxServiceOffDesc =>
      'Apps are locked only when opened from libreGLIDE. Tap to turn it on.';

  @override
  String get detoxServiceOn => 'Lock service is on';

  @override
  String get detoxActiveNow => 'The lock is active now.';

  @override
  String detoxStartsAt(String time) {
    return 'The lock starts at $time.';
  }

  @override
  String get detoxPin => 'PIN';

  @override
  String get detoxSetPin => 'Set PIN';

  @override
  String get detoxChangePin => 'Change PIN';

  @override
  String get detoxPinDesc =>
      '8 to 16 characters. Needed to unlock apps and to change these settings while detox is on.';

  @override
  String get detoxPinLabel => 'PIN';

  @override
  String get detoxOldPin => 'Current PIN';

  @override
  String get detoxNewPin => 'New PIN';

  @override
  String get detoxConfirmPin => 'Confirm PIN';

  @override
  String get detoxPinLength => '8 to 16 characters.';

  @override
  String get detoxPinMismatch => 'The two PINs don\'t match.';

  @override
  String get detoxPinWarning =>
      'Don\'t lose it: it can\'t be recovered. Without the PIN the only way out of detox is restarting the phone in safe mode.';

  @override
  String get detoxWrongPin => 'Wrong PIN.';

  @override
  String detoxWait(int seconds) {
    return 'Too many attempts. Try again in $seconds s.';
  }

  @override
  String get detoxSchedule => 'Schedule';

  @override
  String get detoxWhen => 'When';

  @override
  String get detoxAllDay => 'All day';

  @override
  String get detoxTimeRange => 'Time range';

  @override
  String get detoxFrom => 'From';

  @override
  String get detoxTo => 'To';

  @override
  String get detoxUnlock => 'Unlock';

  @override
  String get detoxUnlockTitle => 'Locked apps';

  @override
  String get detoxUnlockPin => 'With PIN';

  @override
  String get detoxUnlockNever => 'Never';

  @override
  String get detoxUnlockPinDesc =>
      'With the PIN the app stays open until you leave it.';

  @override
  String get detoxUnlockNeverDesc => 'No unlocking: you can only go back Home.';

  @override
  String get detoxApps => 'Apps';

  @override
  String get detoxLockedApps => 'Locked apps';

  @override
  String detoxAppsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count apps',
      one: '1 app',
      zero: 'No apps',
    );
    return '$_temp0';
  }

  @override
  String get detoxHide => 'Hide locked apps';

  @override
  String get detoxHideDesc =>
      'During detox they disappear from Collections, A-Z, search and dock. They are kept apart from hidden apps: when detox ends they\'re back in place.';

  @override
  String get detoxEmergency =>
      'If you lock Settings, you\'ll need the PIN here in libreGLIDE to turn detox off. If you lose it, restart in safe mode: Android turns off accessibility services.';

  @override
  String get detoxSystemGroup => 'System';

  @override
  String get detoxSystemGroupDesc =>
      'Install and uninstall, Settings, Play Store';

  @override
  String detoxGroupCount(int locked, int total) {
    return '$locked of $total locked';
  }

  @override
  String get frostedGlass => 'Frosted glass';

  @override
  String get frostedGlassDesc =>
      'Space, Collections and A-Z become translucent over the blurred wallpaper. Android does the blur; in battery saver pages turn solid again.';

  @override
  String get dockStyle => 'Dock';

  @override
  String get dockTray => 'Tray';

  @override
  String get dockTransparent => 'Transparent';

  @override
  String get homeCorners => 'Rounded corners on Home';

  @override
  String get homeCornersDesc =>
      'The bar and dock frame the wallpaper with slightly rounded corners.';
}
