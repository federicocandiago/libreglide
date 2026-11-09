import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of L10n
/// returned by `L10n.of(context)`.
///
/// Applications need to include `L10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: L10n.localizationsDelegates,
///   supportedLocales: L10n.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the L10n.supportedLocales
/// property.
abstract class L10n {
  L10n(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static L10n of(BuildContext context) {
    return Localizations.of<L10n>(context, L10n)!;
  }

  static const LocalizationsDelegate<L10n> delegate = _L10nDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('it'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In it, this message translates to:
  /// **'libreGLIDE'**
  String get appTitle;

  /// No description provided for @suggestionsTitle.
  ///
  /// In it, this message translates to:
  /// **'Per te adesso'**
  String get suggestionsTitle;

  /// No description provided for @learningHint.
  ///
  /// In it, this message translates to:
  /// **'libreGLIDE sta imparando le tue abitudini: le app suggerite compariranno dopo qualche apertura.'**
  String get learningHint;

  /// No description provided for @favoritesEmpty.
  ///
  /// In it, this message translates to:
  /// **'Tieni premuta un\'app per aggiungerla ai preferiti'**
  String get favoritesEmpty;

  /// No description provided for @contextChip.
  ///
  /// In it, this message translates to:
  /// **'{slot} · {dayType}'**
  String contextChip(Object slot, Object dayType);

  /// No description provided for @notDefaultBanner.
  ///
  /// In it, this message translates to:
  /// **'libreGLIDE non è ancora l\'app Home'**
  String get notDefaultBanner;

  /// No description provided for @setAction.
  ///
  /// In it, this message translates to:
  /// **'Imposta'**
  String get setAction;

  /// No description provided for @slotWakeUp.
  ///
  /// In it, this message translates to:
  /// **'Risveglio'**
  String get slotWakeUp;

  /// No description provided for @slotMorning.
  ///
  /// In it, this message translates to:
  /// **'Mattina'**
  String get slotMorning;

  /// No description provided for @slotLunch.
  ///
  /// In it, this message translates to:
  /// **'Pranzo'**
  String get slotLunch;

  /// No description provided for @slotAfternoon.
  ///
  /// In it, this message translates to:
  /// **'Pomeriggio'**
  String get slotAfternoon;

  /// No description provided for @slotEvening.
  ///
  /// In it, this message translates to:
  /// **'Sera'**
  String get slotEvening;

  /// No description provided for @slotNight.
  ///
  /// In it, this message translates to:
  /// **'Notte'**
  String get slotNight;

  /// No description provided for @dayWorkday.
  ///
  /// In it, this message translates to:
  /// **'feriale'**
  String get dayWorkday;

  /// No description provided for @dayHoliday.
  ///
  /// In it, this message translates to:
  /// **'festivo'**
  String get dayHoliday;

  /// No description provided for @pageHome.
  ///
  /// In it, this message translates to:
  /// **'Home'**
  String get pageHome;

  /// No description provided for @pageCollections.
  ///
  /// In it, this message translates to:
  /// **'Collections'**
  String get pageCollections;

  /// No description provided for @pageAllApps.
  ///
  /// In it, this message translates to:
  /// **'Tutte le app'**
  String get pageAllApps;

  /// No description provided for @appCount.
  ///
  /// In it, this message translates to:
  /// **'{count, plural, =1{1 app} other{{count} app}}'**
  String appCount(int count);

  /// No description provided for @pinCategory.
  ///
  /// In it, this message translates to:
  /// **'Fissa in cima'**
  String get pinCategory;

  /// No description provided for @unpinCategory.
  ///
  /// In it, this message translates to:
  /// **'Rimuovi dai fissati'**
  String get unpinCategory;

  /// No description provided for @hideCategory.
  ///
  /// In it, this message translates to:
  /// **'Nascondi categoria'**
  String get hideCategory;

  /// No description provided for @categoryHidden.
  ///
  /// In it, this message translates to:
  /// **'Categoria nascosta. Puoi ripristinarla dalle impostazioni.'**
  String get categoryHidden;

  /// No description provided for @undo.
  ///
  /// In it, this message translates to:
  /// **'Annulla'**
  String get undo;

  /// No description provided for @noCollections.
  ///
  /// In it, this message translates to:
  /// **'Nessuna app da mostrare'**
  String get noCollections;

  /// No description provided for @catSocial.
  ///
  /// In it, this message translates to:
  /// **'Social'**
  String get catSocial;

  /// No description provided for @catMessaging.
  ///
  /// In it, this message translates to:
  /// **'Messaggi e chiamate'**
  String get catMessaging;

  /// No description provided for @catMusic.
  ///
  /// In it, this message translates to:
  /// **'Musica e audio'**
  String get catMusic;

  /// No description provided for @catVideo.
  ///
  /// In it, this message translates to:
  /// **'Video'**
  String get catVideo;

  /// No description provided for @catPhoto.
  ///
  /// In it, this message translates to:
  /// **'Foto'**
  String get catPhoto;

  /// No description provided for @catNews.
  ///
  /// In it, this message translates to:
  /// **'Notizie'**
  String get catNews;

  /// No description provided for @catMaps.
  ///
  /// In it, this message translates to:
  /// **'Mappe e viaggi'**
  String get catMaps;

  /// No description provided for @catProductivity.
  ///
  /// In it, this message translates to:
  /// **'Produttività'**
  String get catProductivity;

  /// No description provided for @catWork.
  ///
  /// In it, this message translates to:
  /// **'Lavoro'**
  String get catWork;

  /// No description provided for @catEducation.
  ///
  /// In it, this message translates to:
  /// **'Studio'**
  String get catEducation;

  /// No description provided for @catFinance.
  ///
  /// In it, this message translates to:
  /// **'Finanza'**
  String get catFinance;

  /// No description provided for @catShopping.
  ///
  /// In it, this message translates to:
  /// **'Shopping'**
  String get catShopping;

  /// No description provided for @catFood.
  ///
  /// In it, this message translates to:
  /// **'Cibo'**
  String get catFood;

  /// No description provided for @catHealth.
  ///
  /// In it, this message translates to:
  /// **'Salute e sport'**
  String get catHealth;

  /// No description provided for @catGames.
  ///
  /// In it, this message translates to:
  /// **'Giochi'**
  String get catGames;

  /// No description provided for @catTools.
  ///
  /// In it, this message translates to:
  /// **'Strumenti'**
  String get catTools;

  /// No description provided for @catSystem.
  ///
  /// In it, this message translates to:
  /// **'Sistema'**
  String get catSystem;

  /// No description provided for @catOther.
  ///
  /// In it, this message translates to:
  /// **'Altro'**
  String get catOther;

  /// No description provided for @searchHint.
  ///
  /// In it, this message translates to:
  /// **'Cerca app'**
  String get searchHint;

  /// No description provided for @noResults.
  ///
  /// In it, this message translates to:
  /// **'Nessuna app trovata'**
  String get noResults;

  /// No description provided for @bestMatch.
  ///
  /// In it, this message translates to:
  /// **'Miglior risultato'**
  String get bestMatch;

  /// No description provided for @otherResults.
  ///
  /// In it, this message translates to:
  /// **'Altri risultati'**
  String get otherResults;

  /// No description provided for @searchWeb.
  ///
  /// In it, this message translates to:
  /// **'Cerca «{query}» sul web'**
  String searchWeb(String query);

  /// No description provided for @layoutGrid.
  ///
  /// In it, this message translates to:
  /// **'Griglia'**
  String get layoutGrid;

  /// No description provided for @layoutList.
  ///
  /// In it, this message translates to:
  /// **'Lista'**
  String get layoutList;

  /// No description provided for @addFavorite.
  ///
  /// In it, this message translates to:
  /// **'Aggiungi ai preferiti'**
  String get addFavorite;

  /// No description provided for @removeFavorite.
  ///
  /// In it, this message translates to:
  /// **'Rimuovi dai preferiti'**
  String get removeFavorite;

  /// No description provided for @favoritesFull.
  ///
  /// In it, this message translates to:
  /// **'Puoi avere al massimo {max} preferiti'**
  String favoritesFull(int max);

  /// No description provided for @changeCategory.
  ///
  /// In it, this message translates to:
  /// **'Cambia categoria'**
  String get changeCategory;

  /// No description provided for @automaticCategory.
  ///
  /// In it, this message translates to:
  /// **'Categoria automatica'**
  String get automaticCategory;

  /// No description provided for @hideApp.
  ///
  /// In it, this message translates to:
  /// **'Nascondi'**
  String get hideApp;

  /// No description provided for @appInfo.
  ///
  /// In it, this message translates to:
  /// **'Informazioni app'**
  String get appInfo;

  /// No description provided for @uninstall.
  ///
  /// In it, this message translates to:
  /// **'Disinstalla'**
  String get uninstall;

  /// No description provided for @appHidden.
  ///
  /// In it, this message translates to:
  /// **'{app} nascosta'**
  String appHidden(Object app);

  /// No description provided for @settingsTitle.
  ///
  /// In it, this message translates to:
  /// **'Impostazioni'**
  String get settingsTitle;

  /// No description provided for @sectionAppearance.
  ///
  /// In it, this message translates to:
  /// **'Aspetto'**
  String get sectionAppearance;

  /// No description provided for @theme.
  ///
  /// In it, this message translates to:
  /// **'Tema'**
  String get theme;

  /// No description provided for @themeSystem.
  ///
  /// In it, this message translates to:
  /// **'Automatico'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In it, this message translates to:
  /// **'Chiaro'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In it, this message translates to:
  /// **'Scuro'**
  String get themeDark;

  /// No description provided for @colors.
  ///
  /// In it, this message translates to:
  /// **'Colori'**
  String get colors;

  /// No description provided for @colorSource.
  ///
  /// In it, this message translates to:
  /// **'Origine del colore'**
  String get colorSource;

  /// No description provided for @colorSystem.
  ///
  /// In it, this message translates to:
  /// **'Sistema'**
  String get colorSystem;

  /// No description provided for @colorSystemDesc.
  ///
  /// In it, this message translates to:
  /// **'Segue i colori di Android'**
  String get colorSystemDesc;

  /// No description provided for @colorPreset.
  ///
  /// In it, this message translates to:
  /// **'Colore scelto'**
  String get colorPreset;

  /// No description provided for @paletteStyle.
  ///
  /// In it, this message translates to:
  /// **'Stile della palette'**
  String get paletteStyle;

  /// No description provided for @styleTonalSpot.
  ///
  /// In it, this message translates to:
  /// **'Tonale'**
  String get styleTonalSpot;

  /// No description provided for @styleVibrant.
  ///
  /// In it, this message translates to:
  /// **'Vivace'**
  String get styleVibrant;

  /// No description provided for @styleExpressive.
  ///
  /// In it, this message translates to:
  /// **'Espressivo'**
  String get styleExpressive;

  /// No description provided for @styleNeutral.
  ///
  /// In it, this message translates to:
  /// **'Neutro'**
  String get styleNeutral;

  /// No description provided for @styleMonochrome.
  ///
  /// In it, this message translates to:
  /// **'Monocromo'**
  String get styleMonochrome;

  /// No description provided for @contrast.
  ///
  /// In it, this message translates to:
  /// **'Contrasto'**
  String get contrast;

  /// No description provided for @contrastStandard.
  ///
  /// In it, this message translates to:
  /// **'Standard'**
  String get contrastStandard;

  /// No description provided for @contrastMedium.
  ///
  /// In it, this message translates to:
  /// **'Medio'**
  String get contrastMedium;

  /// No description provided for @contrastHigh.
  ///
  /// In it, this message translates to:
  /// **'Alto'**
  String get contrastHigh;

  /// No description provided for @themedIcons.
  ///
  /// In it, this message translates to:
  /// **'Icone a tema'**
  String get themedIcons;

  /// No description provided for @themedIconsDesc.
  ///
  /// In it, this message translates to:
  /// **'Icone monocromatiche colorate con la palette (Android 13+)'**
  String get themedIconsDesc;

  /// No description provided for @preview.
  ///
  /// In it, this message translates to:
  /// **'Anteprima'**
  String get preview;

  /// No description provided for @presetLaguna.
  ///
  /// In it, this message translates to:
  /// **'Laguna'**
  String get presetLaguna;

  /// No description provided for @presetSalvia.
  ///
  /// In it, this message translates to:
  /// **'Salvia'**
  String get presetSalvia;

  /// No description provided for @presetTerracotta.
  ///
  /// In it, this message translates to:
  /// **'Terracotta'**
  String get presetTerracotta;

  /// No description provided for @presetAmbra.
  ///
  /// In it, this message translates to:
  /// **'Ambra'**
  String get presetAmbra;

  /// No description provided for @presetLampone.
  ///
  /// In it, this message translates to:
  /// **'Lampone'**
  String get presetLampone;

  /// No description provided for @presetLavanda.
  ///
  /// In it, this message translates to:
  /// **'Lavanda'**
  String get presetLavanda;

  /// No description provided for @presetPetrolio.
  ///
  /// In it, this message translates to:
  /// **'Petrolio'**
  String get presetPetrolio;

  /// No description provided for @presetGrafite.
  ///
  /// In it, this message translates to:
  /// **'Grafite'**
  String get presetGrafite;

  /// No description provided for @sectionApps.
  ///
  /// In it, this message translates to:
  /// **'App'**
  String get sectionApps;

  /// No description provided for @allAppsLayout.
  ///
  /// In it, this message translates to:
  /// **'Vista di Tutte le app'**
  String get allAppsLayout;

  /// No description provided for @showSystemApps.
  ///
  /// In it, this message translates to:
  /// **'Mostra app di sistema'**
  String get showSystemApps;

  /// No description provided for @showSystemAppsDesc.
  ///
  /// In it, this message translates to:
  /// **'Telefono, Fotocamera, Impostazioni e app preinstallate'**
  String get showSystemAppsDesc;

  /// No description provided for @hiddenApps.
  ///
  /// In it, this message translates to:
  /// **'App nascoste'**
  String get hiddenApps;

  /// No description provided for @hiddenAppsEmpty.
  ///
  /// In it, this message translates to:
  /// **'Nessuna app nascosta'**
  String get hiddenAppsEmpty;

  /// No description provided for @restore.
  ///
  /// In it, this message translates to:
  /// **'Ripristina'**
  String get restore;

  /// No description provided for @fixedOrder.
  ///
  /// In it, this message translates to:
  /// **'Ordine fisso delle Collections'**
  String get fixedOrder;

  /// No description provided for @fixedOrderDesc.
  ///
  /// In it, this message translates to:
  /// **'Non riordinare card e icone in base al contesto'**
  String get fixedOrderDesc;

  /// No description provided for @hiddenCategories.
  ///
  /// In it, this message translates to:
  /// **'Categorie nascoste'**
  String get hiddenCategories;

  /// No description provided for @hiddenCategoriesEmpty.
  ///
  /// In it, this message translates to:
  /// **'Nessuna categoria nascosta'**
  String get hiddenCategoriesEmpty;

  /// No description provided for @sectionLanguage.
  ///
  /// In it, this message translates to:
  /// **'Lingua'**
  String get sectionLanguage;

  /// No description provided for @languageSystem.
  ///
  /// In it, this message translates to:
  /// **'Lingua di sistema'**
  String get languageSystem;

  /// No description provided for @sectionLauncher.
  ///
  /// In it, this message translates to:
  /// **'Launcher'**
  String get sectionLauncher;

  /// No description provided for @setDefault.
  ///
  /// In it, this message translates to:
  /// **'Imposta libreGLIDE come app Home'**
  String get setDefault;

  /// No description provided for @isDefault.
  ///
  /// In it, this message translates to:
  /// **'libreGLIDE è l\'app Home predefinita'**
  String get isDefault;

  /// No description provided for @androidSettings.
  ///
  /// In it, this message translates to:
  /// **'Impostazioni di Android'**
  String get androidSettings;

  /// No description provided for @sectionData.
  ///
  /// In it, this message translates to:
  /// **'Dati e privacy'**
  String get sectionData;

  /// No description provided for @launchesCount.
  ///
  /// In it, this message translates to:
  /// **'{count, plural, =0{Nessuna apertura registrata} =1{1 apertura registrata} other{{count} aperture registrate}}'**
  String launchesCount(int count);

  /// No description provided for @privacyNote.
  ///
  /// In it, this message translates to:
  /// **'Tutti i dati restano sul telefono ed escono solo se li esporti tu. Il database è escluso dal backup cloud.'**
  String get privacyNote;

  /// No description provided for @clearHistory.
  ///
  /// In it, this message translates to:
  /// **'Cancella lo storico delle aperture'**
  String get clearHistory;

  /// No description provided for @clearHistoryConfirm.
  ///
  /// In it, this message translates to:
  /// **'Cancellare lo storico? Le previsioni ripartiranno da zero.'**
  String get clearHistoryConfirm;

  /// No description provided for @cancel.
  ///
  /// In it, this message translates to:
  /// **'Annulla'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In it, this message translates to:
  /// **'Cancella'**
  String get delete;

  /// No description provided for @historyCleared.
  ///
  /// In it, this message translates to:
  /// **'Storico cancellato'**
  String get historyCleared;

  /// No description provided for @diagnostics.
  ///
  /// In it, this message translates to:
  /// **'Diagnostica'**
  String get diagnostics;

  /// No description provided for @diagnosticsDesc.
  ///
  /// In it, this message translates to:
  /// **'Contesto corrente e motivazione delle previsioni'**
  String get diagnosticsDesc;

  /// No description provided for @currentContext.
  ///
  /// In it, this message translates to:
  /// **'Contesto corrente'**
  String get currentContext;

  /// No description provided for @predictions.
  ///
  /// In it, this message translates to:
  /// **'Previsioni'**
  String get predictions;

  /// No description provided for @noPredictions.
  ///
  /// In it, this message translates to:
  /// **'Servono almeno 3 aperture di un\'app per prevederla.'**
  String get noPredictions;

  /// No description provided for @sectionAbout.
  ///
  /// In it, this message translates to:
  /// **'Informazioni'**
  String get sectionAbout;

  /// No description provided for @aboutDesc.
  ///
  /// In it, this message translates to:
  /// **'Launcher contestuale open source e local-only.'**
  String get aboutDesc;

  /// No description provided for @tabSpace.
  ///
  /// In it, this message translates to:
  /// **'Space'**
  String get tabSpace;

  /// No description provided for @tabCollections.
  ///
  /// In it, this message translates to:
  /// **'Collections'**
  String get tabCollections;

  /// No description provided for @tabAllApps.
  ///
  /// In it, this message translates to:
  /// **'A-Z'**
  String get tabAllApps;

  /// No description provided for @spacesTitle.
  ///
  /// In it, this message translates to:
  /// **'Spaces'**
  String get spacesTitle;

  /// No description provided for @azHeader.
  ///
  /// In it, this message translates to:
  /// **'A-Z App'**
  String get azHeader;

  /// No description provided for @actionAlarm.
  ///
  /// In it, this message translates to:
  /// **'Sveglia'**
  String get actionAlarm;

  /// No description provided for @actionDnd.
  ///
  /// In it, this message translates to:
  /// **'Non disturbare'**
  String get actionDnd;

  /// No description provided for @infoBanner.
  ///
  /// In it, this message translates to:
  /// **'Le informazioni utili compariranno qui durante la giornata.'**
  String get infoBanner;

  /// No description provided for @nowAppsHeader.
  ///
  /// In it, this message translates to:
  /// **'Per questo momento'**
  String get nowAppsHeader;

  /// No description provided for @nextAlarm.
  ///
  /// In it, this message translates to:
  /// **'Prossima sveglia'**
  String get nextAlarm;

  /// No description provided for @noAlarm.
  ///
  /// In it, this message translates to:
  /// **'Nessuna sveglia impostata'**
  String get noAlarm;

  /// No description provided for @addToDock.
  ///
  /// In it, this message translates to:
  /// **'Aggiungi al dock'**
  String get addToDock;

  /// No description provided for @searchApps.
  ///
  /// In it, this message translates to:
  /// **'Cerca'**
  String get searchApps;

  /// No description provided for @searchTopApps.
  ///
  /// In it, this message translates to:
  /// **'App sopra la ricerca'**
  String get searchTopApps;

  /// No description provided for @searchTopAppsDesc.
  ///
  /// In it, this message translates to:
  /// **'Le più usate in questo contesto, sopra i risultati della ricerca.'**
  String get searchTopAppsDesc;

  /// No description provided for @hiddenSummary.
  ///
  /// In it, this message translates to:
  /// **'{apps} app, {categories} categorie'**
  String hiddenSummary(int apps, int categories);

  /// No description provided for @languageSystemShort.
  ///
  /// In it, this message translates to:
  /// **'Sistema'**
  String get languageSystemShort;

  /// No description provided for @version.
  ///
  /// In it, this message translates to:
  /// **'Versione {version}'**
  String version(Object version);

  /// No description provided for @agendaToday.
  ///
  /// In it, this message translates to:
  /// **'Oggi'**
  String get agendaToday;

  /// No description provided for @agendaTomorrow.
  ///
  /// In it, this message translates to:
  /// **'Domani'**
  String get agendaTomorrow;

  /// No description provided for @noEventsToday.
  ///
  /// In it, this message translates to:
  /// **'Nessun evento oggi'**
  String get noEventsToday;

  /// No description provided for @noEventsTomorrow.
  ///
  /// In it, this message translates to:
  /// **'Nessun evento domani'**
  String get noEventsTomorrow;

  /// No description provided for @allDay.
  ///
  /// In it, this message translates to:
  /// **'Tutto il giorno'**
  String get allDay;

  /// No description provided for @agendaPermission.
  ///
  /// In it, this message translates to:
  /// **'Mostra qui i tuoi prossimi impegni del calendario.'**
  String get agendaPermission;

  /// No description provided for @allow.
  ///
  /// In it, this message translates to:
  /// **'Consenti'**
  String get allow;

  /// No description provided for @newEvent.
  ///
  /// In it, this message translates to:
  /// **'Nuovo evento'**
  String get newEvent;

  /// No description provided for @navigate.
  ///
  /// In it, this message translates to:
  /// **'Indicazioni'**
  String get navigate;

  /// No description provided for @nowPlaying.
  ///
  /// In it, this message translates to:
  /// **'In ascolto'**
  String get nowPlaying;

  /// No description provided for @mediaPermission.
  ///
  /// In it, this message translates to:
  /// **'Controlla la musica da qui. Serve l\'accesso alle notifiche: libreGLIDE lo usa solo per i controlli multimediali e non legge né salva le notifiche.'**
  String get mediaPermission;

  /// No description provided for @play.
  ///
  /// In it, this message translates to:
  /// **'Riproduci'**
  String get play;

  /// No description provided for @pause.
  ///
  /// In it, this message translates to:
  /// **'Pausa'**
  String get pause;

  /// No description provided for @next.
  ///
  /// In it, this message translates to:
  /// **'Successivo'**
  String get next;

  /// No description provided for @previous.
  ///
  /// In it, this message translates to:
  /// **'Precedente'**
  String get previous;

  /// No description provided for @sectionSpace.
  ///
  /// In it, this message translates to:
  /// **'Space'**
  String get sectionSpace;

  /// No description provided for @cardAgenda.
  ///
  /// In it, this message translates to:
  /// **'Agenda'**
  String get cardAgenda;

  /// No description provided for @cardAgendaDesc.
  ///
  /// In it, this message translates to:
  /// **'Prossimi impegni dal calendario del telefono'**
  String get cardAgendaDesc;

  /// No description provided for @cardMedia.
  ///
  /// In it, this message translates to:
  /// **'In ascolto'**
  String get cardMedia;

  /// No description provided for @cardMediaDesc.
  ///
  /// In it, this message translates to:
  /// **'Controlli della musica in riproduzione, anche quando colleghi le cuffie'**
  String get cardMediaDesc;

  /// No description provided for @privacyPolicy.
  ///
  /// In it, this message translates to:
  /// **'Informativa sulla privacy'**
  String get privacyPolicy;

  /// No description provided for @privacyPolicyDesc.
  ///
  /// In it, this message translates to:
  /// **'Cosa resta sul telefono e cosa no'**
  String get privacyPolicyDesc;

  /// No description provided for @openSource.
  ///
  /// In it, this message translates to:
  /// **'Librerie open source'**
  String get openSource;

  /// No description provided for @openSourceDesc.
  ///
  /// In it, this message translates to:
  /// **'Licenze dei componenti usati da libreGLIDE'**
  String get openSourceDesc;

  /// No description provided for @openSourceCount.
  ///
  /// In it, this message translates to:
  /// **'{count} componenti'**
  String openSourceCount(int count);

  /// No description provided for @licenseCount.
  ///
  /// In it, this message translates to:
  /// **'{count} licenze'**
  String licenseCount(int count);

  /// No description provided for @appLicense.
  ///
  /// In it, this message translates to:
  /// **'Licenza di libreGLIDE'**
  String get appLicense;

  /// No description provided for @appLicenseUndefined.
  ///
  /// In it, this message translates to:
  /// **'Da definire prima della pubblicazione'**
  String get appLicenseUndefined;

  /// No description provided for @unsplashAttribution.
  ///
  /// In it, this message translates to:
  /// **'Le foto degli sfondi sono di autori Unsplash, citati sulla Home e nello Space'**
  String get unsplashAttribution;

  /// No description provided for @showOnboarding.
  ///
  /// In it, this message translates to:
  /// **'Rivedi la presentazione'**
  String get showOnboarding;

  /// No description provided for @obWelcomeTitle.
  ///
  /// In it, this message translates to:
  /// **'Benvenuto in libreGLIDE'**
  String get obWelcomeTitle;

  /// No description provided for @obWelcomeText.
  ///
  /// In it, this message translates to:
  /// **'Il launcher che cambia con il tuo momento: ti mostra le app e le informazioni giuste, quando servono.'**
  String get obWelcomeText;

  /// No description provided for @obStart.
  ///
  /// In it, this message translates to:
  /// **'Inizia'**
  String get obStart;

  /// No description provided for @obNext.
  ///
  /// In it, this message translates to:
  /// **'Avanti'**
  String get obNext;

  /// No description provided for @obBack.
  ///
  /// In it, this message translates to:
  /// **'Indietro'**
  String get obBack;

  /// No description provided for @obHowTitle.
  ///
  /// In it, this message translates to:
  /// **'Come funziona'**
  String get obHowTitle;

  /// No description provided for @obHowSpace.
  ///
  /// In it, this message translates to:
  /// **'Lo Space mostra agenda, musica e le app adatte a questo momento.'**
  String get obHowSpace;

  /// No description provided for @obHowHome.
  ///
  /// In it, this message translates to:
  /// **'La Home lascia spazio al tuo sfondo, con il dock delle app preferite.'**
  String get obHowHome;

  /// No description provided for @obHowCollections.
  ///
  /// In it, this message translates to:
  /// **'Le Collections raggruppano le app da sole e mettono prima quelle che usi adesso.'**
  String get obHowCollections;

  /// No description provided for @obHowSearch.
  ///
  /// In it, this message translates to:
  /// **'Swipe verso l\'alto per cercare un\'app, verso il basso per i contatti.'**
  String get obHowSearch;

  /// No description provided for @obHowDrawer.
  ///
  /// In it, this message translates to:
  /// **'Tocca le strisce colorate in alto per scegliere uno Space.'**
  String get obHowDrawer;

  /// No description provided for @obPrivacyTitle.
  ///
  /// In it, this message translates to:
  /// **'La tua privacy'**
  String get obPrivacyTitle;

  /// No description provided for @obPrivacy1.
  ///
  /// In it, this message translates to:
  /// **'Nessun account, nessuna pubblicità, nessuna telemetria.'**
  String get obPrivacy1;

  /// No description provided for @obPrivacy2.
  ///
  /// In it, this message translates to:
  /// **'Le tue abitudini restano sul telefono: lo sviluppatore non le vede.'**
  String get obPrivacy2;

  /// No description provided for @obPrivacy3.
  ///
  /// In it, this message translates to:
  /// **'Internet solo se scegli lo sfondo Unsplash con una tua chiave.'**
  String get obPrivacy3;

  /// No description provided for @obReadPolicy.
  ///
  /// In it, this message translates to:
  /// **'Leggi l\'informativa completa'**
  String get obReadPolicy;

  /// No description provided for @obCollectionsTitle.
  ///
  /// In it, this message translates to:
  /// **'Le tue raccolte'**
  String get obCollectionsTitle;

  /// No description provided for @obCollectionsText.
  ///
  /// In it, this message translates to:
  /// **'Quali usi di più? Resteranno in cima per le prime settimane, poi conterà come usi davvero il telefono.'**
  String get obCollectionsText;

  /// No description provided for @obCollectionsHint.
  ///
  /// In it, this message translates to:
  /// **'Scegline quante vuoi, anche nessuna. L\'ordine di scelta conta.'**
  String get obCollectionsHint;

  /// No description provided for @obFinishTitle.
  ///
  /// In it, this message translates to:
  /// **'Ultimi ritocchi'**
  String get obFinishTitle;

  /// No description provided for @obDockPrefill.
  ///
  /// In it, this message translates to:
  /// **'Proponi un dock con telefono, messaggi, fotocamera e browser'**
  String get obDockPrefill;

  /// No description provided for @obFinish.
  ///
  /// In it, this message translates to:
  /// **'Fine'**
  String get obFinish;

  /// No description provided for @photoBy.
  ///
  /// In it, this message translates to:
  /// **'Foto di {name} · Unsplash'**
  String photoBy(Object name);

  /// No description provided for @sectionWallpaper.
  ///
  /// In it, this message translates to:
  /// **'Sfondo'**
  String get sectionWallpaper;

  /// No description provided for @contextWallpaper.
  ///
  /// In it, this message translates to:
  /// **'Sfondo contestuale'**
  String get contextWallpaper;

  /// No description provided for @contextWallpaperDesc.
  ///
  /// In it, this message translates to:
  /// **'Nello Space, una foto Unsplash che cambia con il momento: festività, viaggi, meteo, ora del giorno, musica. Solo dentro libreGLIDE: lo sfondo del telefono non viene toccato.'**
  String get contextWallpaperDesc;

  /// No description provided for @spaceHeaderBlur.
  ///
  /// In it, this message translates to:
  /// **'Sfoca la foto dello Space'**
  String get spaceHeaderBlur;

  /// No description provided for @spaceHeaderBlurDesc.
  ///
  /// In it, this message translates to:
  /// **'Leggermente sfocata dietro data e nome dello Space, per leggerli meglio.'**
  String get spaceHeaderBlurDesc;

  /// No description provided for @creditHome.
  ///
  /// In it, this message translates to:
  /// **'Crediti sulla Home'**
  String get creditHome;

  /// No description provided for @creditSpace.
  ///
  /// In it, this message translates to:
  /// **'Crediti nello Space'**
  String get creditSpace;

  /// No description provided for @creditDesc.
  ///
  /// In it, this message translates to:
  /// **'Nome del fotografo e Unsplash sulla foto, come chiedono le regole di Unsplash. Se li nascondi, restano qui sotto.'**
  String get creditDesc;

  /// No description provided for @currentPhotoHome.
  ///
  /// In it, this message translates to:
  /// **'Foto della Home'**
  String get currentPhotoHome;

  /// No description provided for @currentPhotoSpace.
  ///
  /// In it, this message translates to:
  /// **'Foto dello Space'**
  String get currentPhotoSpace;

  /// No description provided for @dailyWallpaper.
  ///
  /// In it, this message translates to:
  /// **'Sfondo giornaliero'**
  String get dailyWallpaper;

  /// No description provided for @dailyWallpaperDesc.
  ///
  /// In it, this message translates to:
  /// **'Una nuova foto Unsplash ogni giorno sulla Home, scelta la prima volta che la apri.'**
  String get dailyWallpaperDesc;

  /// No description provided for @changeDailyPhoto.
  ///
  /// In it, this message translates to:
  /// **'Cambia la foto di oggi'**
  String get changeDailyPhoto;

  /// No description provided for @wallpaperStyle.
  ///
  /// In it, this message translates to:
  /// **'Stile delle foto'**
  String get wallpaperStyle;

  /// No description provided for @photoStyleNone.
  ///
  /// In it, this message translates to:
  /// **'Nessuno'**
  String get photoStyleNone;

  /// No description provided for @photoStyleAesthetic.
  ///
  /// In it, this message translates to:
  /// **'Aesthetic'**
  String get photoStyleAesthetic;

  /// No description provided for @photoStyleNature.
  ///
  /// In it, this message translates to:
  /// **'Natura'**
  String get photoStyleNature;

  /// No description provided for @photoStyleMinimal.
  ///
  /// In it, this message translates to:
  /// **'Minimal'**
  String get photoStyleMinimal;

  /// No description provided for @photoStyleAbstract.
  ///
  /// In it, this message translates to:
  /// **'Astratto'**
  String get photoStyleAbstract;

  /// No description provided for @photoStyleArchitecture.
  ///
  /// In it, this message translates to:
  /// **'Architettura'**
  String get photoStyleArchitecture;

  /// No description provided for @photoStyleDark.
  ///
  /// In it, this message translates to:
  /// **'Scuro'**
  String get photoStyleDark;

  /// No description provided for @unsplashKey.
  ///
  /// In it, this message translates to:
  /// **'Chiave Unsplash'**
  String get unsplashKey;

  /// No description provided for @unsplashKeyNone.
  ///
  /// In it, this message translates to:
  /// **'Non impostata'**
  String get unsplashKeyNone;

  /// No description provided for @unsplashKeySet.
  ///
  /// In it, this message translates to:
  /// **'Impostata ({hint})'**
  String unsplashKeySet(Object hint);

  /// No description provided for @unsplashKeyHelp.
  ///
  /// In it, this message translates to:
  /// **'Crea un\'applicazione gratuita su unsplash.com/developers e incolla qui la sua Access Key. La chiave resta sul telefono.'**
  String get unsplashKeyHelp;

  /// No description provided for @unsplashGetKey.
  ///
  /// In it, this message translates to:
  /// **'Ottieni una chiave'**
  String get unsplashGetKey;

  /// No description provided for @save.
  ///
  /// In it, this message translates to:
  /// **'Salva'**
  String get save;

  /// No description provided for @remove.
  ///
  /// In it, this message translates to:
  /// **'Rimuovi'**
  String get remove;

  /// No description provided for @keyInvalid.
  ///
  /// In it, this message translates to:
  /// **'Chiave non valida'**
  String get keyInvalid;

  /// No description provided for @keyCheckFailed.
  ///
  /// In it, this message translates to:
  /// **'Impossibile verificare la chiave: controlla la connessione'**
  String get keyCheckFailed;

  /// No description provided for @changePhoto.
  ///
  /// In it, this message translates to:
  /// **'Cambia foto'**
  String get changePhoto;

  /// No description provided for @changePhotoDesc.
  ///
  /// In it, this message translates to:
  /// **'Un\'altra foto per questo momento: {moment}'**
  String changePhotoDesc(Object moment);

  /// No description provided for @wallpaperError.
  ///
  /// In it, this message translates to:
  /// **'Foto non disponibile: si vede lo sfondo del telefono'**
  String get wallpaperError;

  /// No description provided for @wallpaperNetworkNote.
  ///
  /// In it, this message translates to:
  /// **'Usa Internet solo quando cambia il momento, con la tua chiave. Senza chiave libreGLIDE non si collega mai.'**
  String get wallpaperNetworkNote;

  /// No description provided for @sectionGestures.
  ///
  /// In it, this message translates to:
  /// **'Gesti'**
  String get sectionGestures;

  /// No description provided for @swipeDownAction.
  ///
  /// In it, this message translates to:
  /// **'Swipe verso il basso'**
  String get swipeDownAction;

  /// No description provided for @swipeUpAction.
  ///
  /// In it, this message translates to:
  /// **'Swipe verso l\'alto'**
  String get swipeUpAction;

  /// No description provided for @gestureSearch.
  ///
  /// In it, this message translates to:
  /// **'Ricerca'**
  String get gestureSearch;

  /// No description provided for @gestureContacts.
  ///
  /// In it, this message translates to:
  /// **'Contatti'**
  String get gestureContacts;

  /// No description provided for @gestureNone.
  ///
  /// In it, this message translates to:
  /// **'Niente'**
  String get gestureNone;

  /// No description provided for @gesturesDesc.
  ///
  /// In it, this message translates to:
  /// **'Sulla Home e, per lo swipe in giù, anche sulla barra in alto. Nella ricerca e nei contatti, lo swipe opposto chiude e torna alla Home.'**
  String get gesturesDesc;

  /// No description provided for @collectionLabels.
  ///
  /// In it, this message translates to:
  /// **'Nomi nelle Collections'**
  String get collectionLabels;

  /// No description provided for @collectionLabelsDesc.
  ///
  /// In it, this message translates to:
  /// **'Mostra il nome sotto le icone nelle righe chiuse e nelle app dello Space'**
  String get collectionLabelsDesc;

  /// No description provided for @contactsTitle.
  ///
  /// In it, this message translates to:
  /// **'Contatti'**
  String get contactsTitle;

  /// No description provided for @contactsFavorites.
  ///
  /// In it, this message translates to:
  /// **'Preferiti e più usati'**
  String get contactsFavorites;

  /// No description provided for @contactsSearchHint.
  ///
  /// In it, this message translates to:
  /// **'Cerca contatti'**
  String get contactsSearchHint;

  /// No description provided for @contactsPermission.
  ///
  /// In it, this message translates to:
  /// **'Mostra qui i contatti preferiti e quelli che usi di più. I contatti vengono letti solo sul telefono.'**
  String get contactsPermission;

  /// No description provided for @contactsEmpty.
  ///
  /// In it, this message translates to:
  /// **'Aggiungi una stella ai contatti preferiti nell\'app Contatti: compariranno qui, insieme a quelli che apri più spesso.'**
  String get contactsEmpty;

  /// No description provided for @noContactsFound.
  ///
  /// In it, this message translates to:
  /// **'Nessun contatto trovato'**
  String get noContactsFound;

  /// No description provided for @call.
  ///
  /// In it, this message translates to:
  /// **'Chiama'**
  String get call;

  /// No description provided for @message.
  ///
  /// In it, this message translates to:
  /// **'Messaggio'**
  String get message;

  /// No description provided for @openContact.
  ///
  /// In it, this message translates to:
  /// **'Scheda contatto'**
  String get openContact;

  /// No description provided for @searchCollections.
  ///
  /// In it, this message translates to:
  /// **'Sfoglia le raccolte'**
  String get searchCollections;

  /// No description provided for @cardEvening.
  ///
  /// In it, this message translates to:
  /// **'Buonanotte'**
  String get cardEvening;

  /// No description provided for @cardEveningDesc.
  ///
  /// In it, this message translates to:
  /// **'Di sera: sveglia di domani, Non disturbare e promemoria di ricarica'**
  String get cardEveningDesc;

  /// No description provided for @dndOn.
  ///
  /// In it, this message translates to:
  /// **'Non disturbare attivo'**
  String get dndOn;

  /// No description provided for @chargeReminder.
  ///
  /// In it, this message translates to:
  /// **'Batteria al {level}%: mettilo in carica per la notte'**
  String chargeReminder(int level);

  /// No description provided for @cardNextPlace.
  ///
  /// In it, this message translates to:
  /// **'Prossima destinazione'**
  String get cardNextPlace;

  /// No description provided for @cardNextPlaceDesc.
  ///
  /// In it, this message translates to:
  /// **'Indicazioni per il prossimo impegno con un luogo, nelle 3 ore prima'**
  String get cardNextPlaceDesc;

  /// No description provided for @cardTravel.
  ///
  /// In it, this message translates to:
  /// **'In viaggio'**
  String get cardTravel;

  /// No description provided for @cardTravelDesc.
  ///
  /// In it, this message translates to:
  /// **'Ora di casa e app di viaggio quando sei in un altro fuso orario o in roaming'**
  String get cardTravelDesc;

  /// No description provided for @homeTime.
  ///
  /// In it, this message translates to:
  /// **'A casa sono le {time}'**
  String homeTime(Object time);

  /// No description provided for @travelHere.
  ///
  /// In it, this message translates to:
  /// **'Ora vivo qui'**
  String get travelHere;

  /// No description provided for @autoLaunch.
  ///
  /// In it, this message translates to:
  /// **'Apri da sola l\'unica app trovata'**
  String get autoLaunch;

  /// No description provided for @autoLaunchDesc.
  ///
  /// In it, this message translates to:
  /// **'Quando resta una sola app che corrisponde a ciò che scrivi (almeno 2 lettere), si apre automaticamente.'**
  String get autoLaunchDesc;

  /// No description provided for @sectionSearchGestures.
  ///
  /// In it, this message translates to:
  /// **'Ricerca e gesti'**
  String get sectionSearchGestures;

  /// No description provided for @resultsCount.
  ///
  /// In it, this message translates to:
  /// **'{count, plural, =1{1 risultato} other{{count} risultati}}'**
  String resultsCount(int count);

  /// No description provided for @cardWidgets.
  ///
  /// In it, this message translates to:
  /// **'Widget'**
  String get cardWidgets;

  /// No description provided for @cardWidgetsDesc.
  ///
  /// In it, this message translates to:
  /// **'Widget Android a tutta larghezza nello Space'**
  String get cardWidgetsDesc;

  /// No description provided for @addWidget.
  ///
  /// In it, this message translates to:
  /// **'Aggiungi widget'**
  String get addWidget;

  /// No description provided for @noWidgets.
  ///
  /// In it, this message translates to:
  /// **'Nessun widget nello Space: aggiungine uno.'**
  String get noWidgets;

  /// No description provided for @widgetHeight.
  ///
  /// In it, this message translates to:
  /// **'Altezza'**
  String get widgetHeight;

  /// No description provided for @widgetShorter.
  ///
  /// In it, this message translates to:
  /// **'Più basso'**
  String get widgetShorter;

  /// No description provided for @widgetTaller.
  ///
  /// In it, this message translates to:
  /// **'Più alto'**
  String get widgetTaller;

  /// No description provided for @moveUp.
  ///
  /// In it, this message translates to:
  /// **'Sposta su'**
  String get moveUp;

  /// No description provided for @moveDown.
  ///
  /// In it, this message translates to:
  /// **'Sposta giù'**
  String get moveDown;

  /// No description provided for @widgetMinSize.
  ///
  /// In it, this message translates to:
  /// **'Minimo {w}×{h} dp'**
  String widgetMinSize(int w, int h);

  /// No description provided for @widgetCount.
  ///
  /// In it, this message translates to:
  /// **'{count, plural, =0{Nessun widget} =1{1 widget} other{{count} widget}}'**
  String widgetCount(int count);

  /// No description provided for @cardWeather.
  ///
  /// In it, this message translates to:
  /// **'Meteo'**
  String get cardWeather;

  /// No description provided for @cardWeatherDesc.
  ///
  /// In it, this message translates to:
  /// **'Previsioni da Open-Meteo con la posizione approssimativa, arrotondata a circa 10 km. Usa Internet.'**
  String get cardWeatherDesc;

  /// No description provided for @weatherPermission.
  ///
  /// In it, this message translates to:
  /// **'Per il meteo serve la posizione approssimativa: viene arrotondata a circa 10 km prima di chiedere le previsioni.'**
  String get weatherPermission;

  /// No description provided for @weatherHere.
  ///
  /// In it, this message translates to:
  /// **'Qui'**
  String get weatherHere;

  /// No description provided for @weatherSource.
  ///
  /// In it, this message translates to:
  /// **'Dati meteo: Open-Meteo.com (CC BY 4.0)'**
  String get weatherSource;

  /// No description provided for @weatherClear.
  ///
  /// In it, this message translates to:
  /// **'Sereno'**
  String get weatherClear;

  /// No description provided for @weatherPartly.
  ///
  /// In it, this message translates to:
  /// **'Poco nuvoloso'**
  String get weatherPartly;

  /// No description provided for @weatherCloudy.
  ///
  /// In it, this message translates to:
  /// **'Nuvoloso'**
  String get weatherCloudy;

  /// No description provided for @weatherFog.
  ///
  /// In it, this message translates to:
  /// **'Nebbia'**
  String get weatherFog;

  /// No description provided for @weatherDrizzle.
  ///
  /// In it, this message translates to:
  /// **'Pioviggine'**
  String get weatherDrizzle;

  /// No description provided for @weatherRain.
  ///
  /// In it, this message translates to:
  /// **'Pioggia'**
  String get weatherRain;

  /// No description provided for @weatherSnow.
  ///
  /// In it, this message translates to:
  /// **'Neve'**
  String get weatherSnow;

  /// No description provided for @weatherShowers.
  ///
  /// In it, this message translates to:
  /// **'Rovesci'**
  String get weatherShowers;

  /// No description provided for @weatherStorm.
  ///
  /// In it, this message translates to:
  /// **'Temporale'**
  String get weatherStorm;

  /// No description provided for @cardCar.
  ///
  /// In it, this message translates to:
  /// **'In auto'**
  String get cardCar;

  /// No description provided for @cardCarDesc.
  ///
  /// In it, this message translates to:
  /// **'Mappe, musica e prossima destinazione quando guidi (Android Auto o autoradio Bluetooth)'**
  String get cardCarDesc;

  /// No description provided for @carBluetooth.
  ///
  /// In it, this message translates to:
  /// **'Riconosci l\'autoradio Bluetooth'**
  String get carBluetooth;

  /// No description provided for @carBluetoothDesc.
  ///
  /// In it, this message translates to:
  /// **'Facoltativo: serve il permesso Dispositivi nelle vicinanze. Senza, funziona solo con Android Auto.'**
  String get carBluetoothDesc;

  /// No description provided for @screenTime.
  ///
  /// In it, this message translates to:
  /// **'Tempo di utilizzo'**
  String get screenTime;

  /// No description provided for @screenTimeDesc.
  ///
  /// In it, this message translates to:
  /// **'Quanto hai usato il telefono oggi, come in Olauncher. Serve l\'accesso ai dati di utilizzo; i dati restano sul telefono.'**
  String get screenTimeDesc;

  /// No description provided for @screenTimeOff.
  ///
  /// In it, this message translates to:
  /// **'Spento'**
  String get screenTimeOff;

  /// No description provided for @screenTimeHome.
  ///
  /// In it, this message translates to:
  /// **'Home'**
  String get screenTimeHome;

  /// No description provided for @screenTimeSpace.
  ///
  /// In it, this message translates to:
  /// **'Space'**
  String get screenTimeSpace;

  /// No description provided for @screenTimeToday.
  ///
  /// In it, this message translates to:
  /// **'Oggi'**
  String get screenTimeToday;

  /// No description provided for @screenTimePermission.
  ///
  /// In it, this message translates to:
  /// **'Per mostrare il tempo di utilizzo serve l\'accesso ai dati di utilizzo. I dati restano sul telefono.'**
  String get screenTimePermission;

  /// No description provided for @durationHM.
  ///
  /// In it, this message translates to:
  /// **'{h} h {m} min'**
  String durationHM(int h, int m);

  /// No description provided for @durationM.
  ///
  /// In it, this message translates to:
  /// **'{m} min'**
  String durationM(int m);

  /// No description provided for @spaceHome.
  ///
  /// In it, this message translates to:
  /// **'Casa'**
  String get spaceHome;

  /// No description provided for @spaceWork.
  ///
  /// In it, this message translates to:
  /// **'Lavoro'**
  String get spaceWork;

  /// No description provided for @spaceSchool.
  ///
  /// In it, this message translates to:
  /// **'Scuola'**
  String get spaceSchool;

  /// No description provided for @spaceWorkOrSchool.
  ///
  /// In it, this message translates to:
  /// **'Lavoro/Scuola'**
  String get spaceWorkOrSchool;

  /// No description provided for @spaceMoving.
  ///
  /// In it, this message translates to:
  /// **'In movimento'**
  String get spaceMoving;

  /// No description provided for @spaceListening.
  ///
  /// In it, this message translates to:
  /// **'In ascolto'**
  String get spaceListening;

  /// No description provided for @spaceTravel.
  ///
  /// In it, this message translates to:
  /// **'In viaggio'**
  String get spaceTravel;

  /// No description provided for @spaceNightOut.
  ///
  /// In it, this message translates to:
  /// **'Serata fuori'**
  String get spaceNightOut;

  /// No description provided for @spaceExercise.
  ///
  /// In it, this message translates to:
  /// **'Attività fisica'**
  String get spaceExercise;

  /// No description provided for @exerciseSpaceDesc.
  ///
  /// In it, this message translates to:
  /// **'Uno Space per corsa e camminata veloce, riconosciute dal contapassi del telefono quando apri il launcher. Nessun servizio in background.'**
  String get exerciseSpaceDesc;

  /// No description provided for @spacesPlaces.
  ///
  /// In it, this message translates to:
  /// **'Dai luoghi'**
  String get spacesPlaces;

  /// No description provided for @spacesContext.
  ///
  /// In it, this message translates to:
  /// **'Dal contesto'**
  String get spacesContext;

  /// No description provided for @spacesTime.
  ///
  /// In it, this message translates to:
  /// **'Dall\'ora del giorno'**
  String get spacesTime;

  /// No description provided for @actionEmail.
  ///
  /// In it, this message translates to:
  /// **'Email'**
  String get actionEmail;

  /// No description provided for @actionToHome.
  ///
  /// In it, this message translates to:
  /// **'Verso casa'**
  String get actionToHome;

  /// No description provided for @actionToWork.
  ///
  /// In it, this message translates to:
  /// **'Verso il lavoro'**
  String get actionToWork;

  /// No description provided for @actionMaps.
  ///
  /// In it, this message translates to:
  /// **'Mappe'**
  String get actionMaps;

  /// No description provided for @sectionPlaces.
  ///
  /// In it, this message translates to:
  /// **'Luoghi'**
  String get sectionPlaces;

  /// No description provided for @placesEnabled.
  ///
  /// In it, this message translates to:
  /// **'Riconosci casa e lavoro'**
  String get placesEnabled;

  /// No description provided for @placesEnabledDesc.
  ///
  /// In it, this message translates to:
  /// **'Gli Space Casa e Lavoro/Scuola si attivano da soli. Usa la posizione precisa solo mentre usi il launcher e il Wi-Fi come impronta cifrata; tutto resta sul telefono.'**
  String get placesEnabledDesc;

  /// No description provided for @placesPermission.
  ///
  /// In it, this message translates to:
  /// **'Per riconoscere casa e lavoro serve la posizione precisa, solo mentre usi il launcher. Coordinate e reti Wi-Fi restano sul telefono e non vengono mai inviate.'**
  String get placesPermission;

  /// No description provided for @placeHome.
  ///
  /// In it, this message translates to:
  /// **'Casa'**
  String get placeHome;

  /// No description provided for @placeWork.
  ///
  /// In it, this message translates to:
  /// **'Lavoro/Scuola'**
  String get placeWork;

  /// No description provided for @placeRecognized.
  ///
  /// In it, this message translates to:
  /// **'Riconosciuto ({percent}%)'**
  String placeRecognized(int percent);

  /// No description provided for @placeByUser.
  ///
  /// In it, this message translates to:
  /// **'Impostato da te'**
  String get placeByUser;

  /// No description provided for @placeLearningHome.
  ///
  /// In it, this message translates to:
  /// **'In apprendimento: servono alcune notti'**
  String get placeLearningHome;

  /// No description provided for @placeLearningWork.
  ///
  /// In it, this message translates to:
  /// **'In apprendimento: servono alcuni giorni feriali'**
  String get placeLearningWork;

  /// No description provided for @workLabel.
  ///
  /// In it, this message translates to:
  /// **'Nome dello Space di lavoro'**
  String get workLabel;

  /// No description provided for @workLabelWork.
  ///
  /// In it, this message translates to:
  /// **'Lavoro'**
  String get workLabelWork;

  /// No description provided for @workLabelSchool.
  ///
  /// In it, this message translates to:
  /// **'Scuola'**
  String get workLabelSchool;

  /// No description provided for @hereIsHome.
  ///
  /// In it, this message translates to:
  /// **'Questa è casa mia'**
  String get hereIsHome;

  /// No description provided for @hereIsWork.
  ///
  /// In it, this message translates to:
  /// **'Questo è il mio lavoro/scuola'**
  String get hereIsWork;

  /// No description provided for @notHome.
  ///
  /// In it, this message translates to:
  /// **'Questa non è casa mia'**
  String get notHome;

  /// No description provided for @notWork.
  ///
  /// In it, this message translates to:
  /// **'Questo non è il mio lavoro/scuola'**
  String get notWork;

  /// No description provided for @hereUnknown.
  ///
  /// In it, this message translates to:
  /// **'Luogo attuale non ancora noto: torna qui dopo qualche minuto sul launcher.'**
  String get hereUnknown;

  /// No description provided for @resetPlaces.
  ///
  /// In it, this message translates to:
  /// **'Reimposta i luoghi'**
  String get resetPlaces;

  /// No description provided for @resetPlacesConfirm.
  ///
  /// In it, this message translates to:
  /// **'Dimenticare tutti i luoghi e i campioni di posizione? Casa e lavoro verranno riconosciuti di nuovo.'**
  String get resetPlacesConfirm;

  /// No description provided for @placesCount.
  ///
  /// In it, this message translates to:
  /// **'{count, plural, =0{Nessun luogo} =1{1 luogo} other{{count} luoghi}}'**
  String placesCount(int count);

  /// No description provided for @editHome.
  ///
  /// In it, this message translates to:
  /// **'Modifica i widget'**
  String get editHome;

  /// No description provided for @homeWidgetsFull.
  ///
  /// In it, this message translates to:
  /// **'Al massimo {max} widget sulla Home'**
  String homeWidgetsFull(int max);

  /// No description provided for @done.
  ///
  /// In it, this message translates to:
  /// **'Fine'**
  String get done;

  /// No description provided for @widgetRows.
  ///
  /// In it, this message translates to:
  /// **'{rows, plural, =1{1 riga} other{{rows} righe}}'**
  String widgetRows(int rows);

  /// No description provided for @cardParking.
  ///
  /// In it, this message translates to:
  /// **'Dove ho parcheggiato'**
  String get cardParking;

  /// No description provided for @cardParkingDesc.
  ///
  /// In it, this message translates to:
  /// **'Quando ti scolleghi dall\'autoradio Bluetooth salva dove hai lasciato l\'auto. Usa la posizione in background solo in quel momento; resta sul telefono.'**
  String get cardParkingDesc;

  /// No description provided for @parkedAt.
  ///
  /// In it, this message translates to:
  /// **'Parcheggiato alle {time} · {ago}'**
  String parkedAt(Object time, Object ago);

  /// No description provided for @parkedImprecise.
  ///
  /// In it, this message translates to:
  /// **'Posizione approssimativa ({meters} m)'**
  String parkedImprecise(int meters);

  /// No description provided for @forget.
  ///
  /// In it, this message translates to:
  /// **'Dimentica'**
  String get forget;

  /// No description provided for @agoMinutes.
  ///
  /// In it, this message translates to:
  /// **'{m} min fa'**
  String agoMinutes(int m);

  /// No description provided for @agoHours.
  ///
  /// In it, this message translates to:
  /// **'{h} h fa'**
  String agoHours(int h);

  /// No description provided for @parkingNeedsBluetooth.
  ///
  /// In it, this message translates to:
  /// **'Per riconoscere l\'auto serve il permesso Dispositivi nelle vicinanze.'**
  String get parkingNeedsBluetooth;

  /// No description provided for @parkingNeedsPrecise.
  ///
  /// In it, this message translates to:
  /// **'Per salvare il punto serve la posizione precisa.'**
  String get parkingNeedsPrecise;

  /// No description provided for @parkingNeedsBackground.
  ///
  /// In it, this message translates to:
  /// **'Per salvare il punto quando scendi dall\'auto (con il telefono in tasca) serve la posizione \"Consenti sempre\". Viene usata solo allo scollegamento dall\'autoradio.'**
  String get parkingNeedsBackground;

  /// No description provided for @parkingWaiting.
  ///
  /// In it, this message translates to:
  /// **'Il punto verrà salvato la prossima volta che ti scolleghi dall\'autoradio.'**
  String get parkingWaiting;

  /// No description provided for @spaceAutomatic.
  ///
  /// In it, this message translates to:
  /// **'Automatico'**
  String get spaceAutomatic;

  /// No description provided for @spaceNow.
  ///
  /// In it, this message translates to:
  /// **'ora'**
  String get spaceNow;

  /// No description provided for @workLabelAutomatic.
  ///
  /// In it, this message translates to:
  /// **'Automatico'**
  String get workLabelAutomatic;

  /// No description provided for @workKindLearning.
  ///
  /// In it, this message translates to:
  /// **'Dopo qualche giorno capisce dagli orari se è lavoro (mattina e pomeriggio) o scuola (solo mattina).'**
  String get workKindLearning;

  /// No description provided for @workKindDetected.
  ///
  /// In it, this message translates to:
  /// **'Rilevato dagli orari: {kind}'**
  String workKindDetected(String kind);

  /// No description provided for @groupLook.
  ///
  /// In it, this message translates to:
  /// **'Aspetto e contenuti'**
  String get groupLook;

  /// No description provided for @groupBehavior.
  ///
  /// In it, this message translates to:
  /// **'Comportamento'**
  String get groupBehavior;

  /// No description provided for @groupSystem.
  ///
  /// In it, this message translates to:
  /// **'Sistema'**
  String get groupSystem;

  /// No description provided for @stateOn.
  ///
  /// In it, this message translates to:
  /// **'Attivo'**
  String get stateOn;

  /// No description provided for @stateOff.
  ///
  /// In it, this message translates to:
  /// **'Spento'**
  String get stateOff;

  /// No description provided for @cardsActive.
  ///
  /// In it, this message translates to:
  /// **'{count, plural, =0{Nessuna card attiva} =1{1 card attiva} other{{count} card attive}}'**
  String cardsActive(int count);

  /// No description provided for @parkingBackgroundBlocked.
  ///
  /// In it, this message translates to:
  /// **'Android non mostra più la richiesta. Apri le impostazioni dell\'app, poi Autorizzazioni › Posizione e scegli \"Consenti sempre\". La posizione viene letta solo quando ti scolleghi dall\'autoradio.'**
  String get parkingBackgroundBlocked;

  /// No description provided for @openSettings.
  ///
  /// In it, this message translates to:
  /// **'Apri impostazioni'**
  String get openSettings;

  /// No description provided for @turnOff.
  ///
  /// In it, this message translates to:
  /// **'Disattiva'**
  String get turnOff;

  /// No description provided for @obHowDetox.
  ///
  /// In it, this message translates to:
  /// **'Digital detox (nelle impostazioni): blocca le app che ti distraggono, tutto il giorno o in una fascia oraria, con un PIN.'**
  String get obHowDetox;

  /// No description provided for @notNow.
  ///
  /// In it, this message translates to:
  /// **'Non ora'**
  String get notNow;

  /// No description provided for @ok.
  ///
  /// In it, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @detoxTitle.
  ///
  /// In it, this message translates to:
  /// **'Digital detox'**
  String get detoxTitle;

  /// No description provided for @detoxDesc.
  ///
  /// In it, this message translates to:
  /// **'Blocca le app che scegli, tutto il giorno o in una fascia oraria. Quando le apri compare una schermata nera.'**
  String get detoxDesc;

  /// No description provided for @detoxServiceTitle.
  ///
  /// In it, this message translates to:
  /// **'Attiva il servizio di blocco'**
  String get detoxServiceTitle;

  /// No description provided for @detoxServiceExplain.
  ///
  /// In it, this message translates to:
  /// **'Per accorgersi di quando apri un\'app bloccata, libreGLIDE usa un servizio di accessibilità. Riceve solo il nome dell\'app che passa in primo piano: non legge lo schermo, non registra nulla e non consuma batteria quando non cambi app.\n\nNelle impostazioni che si aprono, attiva \"libreGLIDE · Digital detox\". Se Android lo mostra disattivato (\"impostazione con restrizioni\"), apri le informazioni dell\'app libreGLIDE, menu ⋮, \"Consenti impostazioni con restrizioni\".'**
  String get detoxServiceExplain;

  /// No description provided for @detoxServiceOpen.
  ///
  /// In it, this message translates to:
  /// **'Apri impostazioni'**
  String get detoxServiceOpen;

  /// No description provided for @detoxServiceOff.
  ///
  /// In it, this message translates to:
  /// **'Servizio di blocco non attivo'**
  String get detoxServiceOff;

  /// No description provided for @detoxServiceOffDesc.
  ///
  /// In it, this message translates to:
  /// **'Le app si bloccano solo se aperte da libreGLIDE. Tocca per attivarlo.'**
  String get detoxServiceOffDesc;

  /// No description provided for @detoxServiceOn.
  ///
  /// In it, this message translates to:
  /// **'Servizio di blocco attivo'**
  String get detoxServiceOn;

  /// No description provided for @detoxActiveNow.
  ///
  /// In it, this message translates to:
  /// **'Il blocco è attivo adesso.'**
  String get detoxActiveNow;

  /// No description provided for @detoxStartsAt.
  ///
  /// In it, this message translates to:
  /// **'Il blocco parte alle {time}.'**
  String detoxStartsAt(String time);

  /// No description provided for @detoxPin.
  ///
  /// In it, this message translates to:
  /// **'PIN'**
  String get detoxPin;

  /// No description provided for @detoxSetPin.
  ///
  /// In it, this message translates to:
  /// **'Imposta il PIN'**
  String get detoxSetPin;

  /// No description provided for @detoxChangePin.
  ///
  /// In it, this message translates to:
  /// **'Cambia il PIN'**
  String get detoxChangePin;

  /// No description provided for @detoxPinDesc.
  ///
  /// In it, this message translates to:
  /// **'Da 8 a 16 caratteri. Serve per sbloccare le app e per cambiare queste impostazioni mentre il detox è acceso.'**
  String get detoxPinDesc;

  /// No description provided for @detoxPinLabel.
  ///
  /// In it, this message translates to:
  /// **'PIN'**
  String get detoxPinLabel;

  /// No description provided for @detoxOldPin.
  ///
  /// In it, this message translates to:
  /// **'PIN attuale'**
  String get detoxOldPin;

  /// No description provided for @detoxNewPin.
  ///
  /// In it, this message translates to:
  /// **'Nuovo PIN'**
  String get detoxNewPin;

  /// No description provided for @detoxConfirmPin.
  ///
  /// In it, this message translates to:
  /// **'Conferma il PIN'**
  String get detoxConfirmPin;

  /// No description provided for @detoxPinLength.
  ///
  /// In it, this message translates to:
  /// **'Da 8 a 16 caratteri.'**
  String get detoxPinLength;

  /// No description provided for @detoxPinMismatch.
  ///
  /// In it, this message translates to:
  /// **'I due PIN non coincidono.'**
  String get detoxPinMismatch;

  /// No description provided for @detoxPinWarning.
  ///
  /// In it, this message translates to:
  /// **'Non perderlo: non si può recuperare. Senza PIN l\'unico modo per uscire dal detox è riavviare il telefono in modalità provvisoria.'**
  String get detoxPinWarning;

  /// No description provided for @detoxWrongPin.
  ///
  /// In it, this message translates to:
  /// **'PIN sbagliato.'**
  String get detoxWrongPin;

  /// No description provided for @detoxWait.
  ///
  /// In it, this message translates to:
  /// **'Troppi tentativi. Riprova tra {seconds} s.'**
  String detoxWait(int seconds);

  /// No description provided for @detoxSchedule.
  ///
  /// In it, this message translates to:
  /// **'Orario'**
  String get detoxSchedule;

  /// No description provided for @detoxWhen.
  ///
  /// In it, this message translates to:
  /// **'Quando'**
  String get detoxWhen;

  /// No description provided for @detoxAllDay.
  ///
  /// In it, this message translates to:
  /// **'Tutto il giorno'**
  String get detoxAllDay;

  /// No description provided for @detoxTimeRange.
  ///
  /// In it, this message translates to:
  /// **'Fascia oraria'**
  String get detoxTimeRange;

  /// No description provided for @detoxFrom.
  ///
  /// In it, this message translates to:
  /// **'Dalle'**
  String get detoxFrom;

  /// No description provided for @detoxTo.
  ///
  /// In it, this message translates to:
  /// **'Alle'**
  String get detoxTo;

  /// No description provided for @detoxUnlock.
  ///
  /// In it, this message translates to:
  /// **'Sblocco'**
  String get detoxUnlock;

  /// No description provided for @detoxUnlockTitle.
  ///
  /// In it, this message translates to:
  /// **'Le app bloccate'**
  String get detoxUnlockTitle;

  /// No description provided for @detoxUnlockPin.
  ///
  /// In it, this message translates to:
  /// **'Con il PIN'**
  String get detoxUnlockPin;

  /// No description provided for @detoxUnlockNever.
  ///
  /// In it, this message translates to:
  /// **'Mai'**
  String get detoxUnlockNever;

  /// No description provided for @detoxUnlockPinDesc.
  ///
  /// In it, this message translates to:
  /// **'Con il PIN l\'app resta aperta finché non la lasci.'**
  String get detoxUnlockPinDesc;

  /// No description provided for @detoxUnlockNeverDesc.
  ///
  /// In it, this message translates to:
  /// **'Nessuno sblocco: si torna solo alla Home.'**
  String get detoxUnlockNeverDesc;

  /// No description provided for @detoxApps.
  ///
  /// In it, this message translates to:
  /// **'App'**
  String get detoxApps;

  /// No description provided for @detoxLockedApps.
  ///
  /// In it, this message translates to:
  /// **'App bloccate'**
  String get detoxLockedApps;

  /// No description provided for @detoxAppsCount.
  ///
  /// In it, this message translates to:
  /// **'{count, plural, =0{Nessuna app} =1{1 app} other{{count} app}}'**
  String detoxAppsCount(int count);

  /// No description provided for @detoxHide.
  ///
  /// In it, this message translates to:
  /// **'Nascondi le app bloccate'**
  String get detoxHide;

  /// No description provided for @detoxHideDesc.
  ///
  /// In it, this message translates to:
  /// **'Durante il detox spariscono da Collections, A-Z, ricerca e dock. Restano separate dalle app nascoste: finito il detox tornano al loro posto.'**
  String get detoxHideDesc;

  /// No description provided for @detoxEmergency.
  ///
  /// In it, this message translates to:
  /// **'Se blocchi Impostazioni, per spegnere il detox ti servirà il PIN qui in libreGLIDE. Se lo perdi, riavvia in modalità provvisoria: Android spegne i servizi di accessibilità.'**
  String get detoxEmergency;

  /// No description provided for @detoxSystemGroup.
  ///
  /// In it, this message translates to:
  /// **'Sistema'**
  String get detoxSystemGroup;

  /// No description provided for @detoxSystemGroupDesc.
  ///
  /// In it, this message translates to:
  /// **'Installazione e disinstallazione, Impostazioni, Play Store'**
  String get detoxSystemGroupDesc;

  /// No description provided for @detoxGroupCount.
  ///
  /// In it, this message translates to:
  /// **'{locked} di {total} bloccate'**
  String detoxGroupCount(int locked, int total);

  /// No description provided for @frostedGlass.
  ///
  /// In it, this message translates to:
  /// **'Vetro smerigliato'**
  String get frostedGlass;

  /// No description provided for @frostedGlassDesc.
  ///
  /// In it, this message translates to:
  /// **'Space, Collections e A-Z diventano semitrasparenti sopra lo sfondo sfocato. La sfocatura la fa Android; in risparmio energetico le pagine tornano piene.'**
  String get frostedGlassDesc;

  /// No description provided for @dockStyle.
  ///
  /// In it, this message translates to:
  /// **'Dock'**
  String get dockStyle;

  /// No description provided for @homeTabLabel.
  ///
  /// In it, this message translates to:
  /// **'Scheda Home'**
  String get homeTabLabel;

  /// No description provided for @homeTabDate.
  ///
  /// In it, this message translates to:
  /// **'Data'**
  String get homeTabDate;

  /// No description provided for @homeTabWeather.
  ///
  /// In it, this message translates to:
  /// **'Meteo'**
  String get homeTabWeather;

  /// No description provided for @homeTabWeatherOff.
  ///
  /// In it, this message translates to:
  /// **'Per il meteo attiva la card Meteo nelle impostazioni dello Space.'**
  String get homeTabWeatherOff;

  /// No description provided for @dockTray.
  ///
  /// In it, this message translates to:
  /// **'Vassoio'**
  String get dockTray;

  /// No description provided for @dockTransparent.
  ///
  /// In it, this message translates to:
  /// **'Trasparente'**
  String get dockTransparent;

  /// No description provided for @homeCorners.
  ///
  /// In it, this message translates to:
  /// **'Angoli arrotondati sulla Home'**
  String get homeCorners;

  /// No description provided for @homeCornersDesc.
  ///
  /// In it, this message translates to:
  /// **'Barra e dock incorniciano lo sfondo con angoli appena arrotondati.'**
  String get homeCornersDesc;

  /// No description provided for @lockPortrait.
  ///
  /// In it, this message translates to:
  /// **'Blocca in verticale'**
  String get lockPortrait;

  /// No description provided for @lockPortraitDesc.
  ///
  /// In it, this message translates to:
  /// **'Il launcher resta in verticale anche se ruoti il telefono. Disattivalo per seguire la rotazione automatica.'**
  String get lockPortraitDesc;

  /// No description provided for @learnFromUsage.
  ///
  /// In it, this message translates to:
  /// **'Impara anche dalle app aperte altrove'**
  String get learnFromUsage;

  /// No description provided for @learnFromUsageDesc.
  ///
  /// In it, this message translates to:
  /// **'Usa la cronologia di utilizzo di Android (notifiche, recenti, link) per suggerire le app giuste da subito. Resta sul telefono; spegnendo si cancella.'**
  String get learnFromUsageDesc;

  /// No description provided for @usageAccessNeeded.
  ///
  /// In it, this message translates to:
  /// **'Consenti l\'accesso ai dati di utilizzo'**
  String get usageAccessNeeded;

  /// No description provided for @usageAccessNeededDesc.
  ///
  /// In it, this message translates to:
  /// **'Serve per leggere la cronologia di utilizzo di Android.'**
  String get usageAccessNeededDesc;

  /// No description provided for @launchSourcesNote.
  ///
  /// In it, this message translates to:
  /// **'di cui {usage} dalla cronologia di Android'**
  String launchSourcesNote(int usage);

  /// No description provided for @weatherTomorrow.
  ///
  /// In it, this message translates to:
  /// **'Domani'**
  String get weatherTomorrow;

  /// No description provided for @rainChance.
  ///
  /// In it, this message translates to:
  /// **'Probabilità di pioggia {percent}%'**
  String rainChance(int percent);

  /// No description provided for @actionAlarmTomorrow.
  ///
  /// In it, this message translates to:
  /// **'Sveglia di domani'**
  String get actionAlarmTomorrow;

  /// No description provided for @actionTimer.
  ///
  /// In it, this message translates to:
  /// **'Timer'**
  String get actionTimer;

  /// No description provided for @actionFood.
  ///
  /// In it, this message translates to:
  /// **'Dove mangiare'**
  String get actionFood;

  /// No description provided for @foodQuery.
  ///
  /// In it, this message translates to:
  /// **'ristoranti'**
  String get foodQuery;

  /// No description provided for @cardShowHere.
  ///
  /// In it, this message translates to:
  /// **'Mostra sempre in questo Space'**
  String get cardShowHere;

  /// No description provided for @cardHideHere.
  ///
  /// In it, this message translates to:
  /// **'Nascondi in questo Space'**
  String get cardHideHere;

  /// No description provided for @cardAuto.
  ///
  /// In it, this message translates to:
  /// **'Automatico (come prima)'**
  String get cardAuto;

  /// No description provided for @cardCategory.
  ///
  /// In it, this message translates to:
  /// **'App del momento'**
  String get cardCategory;

  /// No description provided for @diagnosticsCards.
  ///
  /// In it, this message translates to:
  /// **'Card dello Space'**
  String get diagnosticsCards;

  /// No description provided for @spaceCards.
  ///
  /// In it, this message translates to:
  /// **'Card per Space'**
  String get spaceCards;

  /// No description provided for @spaceCardsEntryDesc.
  ///
  /// In it, this message translates to:
  /// **'Scegli quali card mostrare in ogni Space'**
  String get spaceCardsEntryDesc;

  /// No description provided for @spaceCardsDesc.
  ///
  /// In it, this message translates to:
  /// **'Automatico segue il momento e il tuo uso. Sempre e Mai valgono solo per quello Space e vincono su tutto.'**
  String get spaceCardsDesc;

  /// No description provided for @spaceCardsCustom.
  ///
  /// In it, this message translates to:
  /// **'{count, plural, =1{1 scelta personale} other{{count} scelte personali}}'**
  String spaceCardsCustom(int count);

  /// No description provided for @cardAutoShort.
  ///
  /// In it, this message translates to:
  /// **'Automatico'**
  String get cardAutoShort;

  /// No description provided for @cardAlways.
  ///
  /// In it, this message translates to:
  /// **'Sempre'**
  String get cardAlways;

  /// No description provided for @cardNever.
  ///
  /// In it, this message translates to:
  /// **'Mai'**
  String get cardNever;

  /// No description provided for @cardDefaultShown.
  ///
  /// In it, this message translates to:
  /// **'Di default visibile'**
  String get cardDefaultShown;

  /// No description provided for @cardDefaultHidden.
  ///
  /// In it, this message translates to:
  /// **'Di default nascosta'**
  String get cardDefaultHidden;

  /// No description provided for @manageSpaceCards.
  ///
  /// In it, this message translates to:
  /// **'Gestisci le card di questo Space…'**
  String get manageSpaceCards;

  /// No description provided for @unsplashKeyVerified.
  ///
  /// In it, this message translates to:
  /// **'Chiave verificata · {suffix}'**
  String unsplashKeyVerified(String suffix);
}

class _L10nDelegate extends LocalizationsDelegate<L10n> {
  const _L10nDelegate();

  @override
  Future<L10n> load(Locale locale) {
    return SynchronousFuture<L10n>(lookupL10n(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en', 'es', 'fr', 'it'].contains(locale.languageCode);

  @override
  bool shouldReload(_L10nDelegate old) => false;
}

L10n lookupL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return L10nDe();
    case 'en':
      return L10nEn();
    case 'es':
      return L10nEs();
    case 'fr':
      return L10nFr();
    case 'it':
      return L10nIt();
  }

  throw FlutterError(
    'L10n.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
