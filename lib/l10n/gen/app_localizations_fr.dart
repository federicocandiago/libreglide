// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class L10nFr extends L10n {
  L10nFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'libreGLIDE';

  @override
  String get suggestionsTitle => 'Pour toi maintenant';

  @override
  String get learningHint =>
      'libreGLIDE apprend tes habitudes : les apps suggérées apparaîtront après quelques lancements.';

  @override
  String get favoritesEmpty =>
      'Appuie longuement sur une app pour l’ajouter aux favoris';

  @override
  String contextChip(Object slot, Object dayType) {
    return '$slot · $dayType';
  }

  @override
  String get notDefaultBanner =>
      'libreGLIDE n’est pas encore ton app d’accueil';

  @override
  String get setAction => 'Définir';

  @override
  String get slotWakeUp => 'Réveil';

  @override
  String get slotMorning => 'Matin';

  @override
  String get slotLunch => 'Midi';

  @override
  String get slotAfternoon => 'Après-midi';

  @override
  String get slotEvening => 'Soir';

  @override
  String get slotNight => 'Nuit';

  @override
  String get dayWorkday => 'jour ouvré';

  @override
  String get dayHoliday => 'jour de repos';

  @override
  String get pageHome => 'Accueil';

  @override
  String get pageCollections => 'Collections';

  @override
  String get pageAllApps => 'Toutes les apps';

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
  String get pinCategory => 'Épingler en haut';

  @override
  String get unpinCategory => 'Désépingler';

  @override
  String get hideCategory => 'Masquer la catégorie';

  @override
  String get categoryHidden =>
      'Catégorie masquée. Tu peux la restaurer dans les paramètres.';

  @override
  String get undo => 'Annuler';

  @override
  String get noCollections => 'Aucune app à afficher';

  @override
  String get catSocial => 'Réseaux sociaux';

  @override
  String get catMessaging => 'Messages et appels';

  @override
  String get catMusic => 'Musique et audio';

  @override
  String get catVideo => 'Vidéo';

  @override
  String get catPhoto => 'Photos';

  @override
  String get catNews => 'Actualités';

  @override
  String get catMaps => 'Cartes et voyages';

  @override
  String get catProductivity => 'Productivité';

  @override
  String get catWork => 'Travail';

  @override
  String get catEducation => 'Études';

  @override
  String get catFinance => 'Finance';

  @override
  String get catShopping => 'Shopping';

  @override
  String get catFood => 'Alimentation';

  @override
  String get catHealth => 'Santé et sport';

  @override
  String get catGames => 'Jeux';

  @override
  String get catTools => 'Outils';

  @override
  String get catSystem => 'Système';

  @override
  String get catOther => 'Autres';

  @override
  String get searchHint => 'Rechercher des apps';

  @override
  String get noResults => 'Aucune app trouvée';

  @override
  String get bestMatch => 'Meilleur résultat';

  @override
  String get otherResults => 'Autres résultats';

  @override
  String searchWeb(String query) {
    return 'Rechercher « $query » sur le web';
  }

  @override
  String get layoutGrid => 'Grille';

  @override
  String get layoutList => 'Liste';

  @override
  String get addFavorite => 'Ajouter aux favoris';

  @override
  String get removeFavorite => 'Retirer des favoris';

  @override
  String favoritesFull(int max) {
    return 'Tu peux avoir jusqu’à $max favoris';
  }

  @override
  String get changeCategory => 'Changer de catégorie';

  @override
  String get automaticCategory => 'Catégorie automatique';

  @override
  String get hideApp => 'Masquer';

  @override
  String get appInfo => 'Infos sur l’app';

  @override
  String get uninstall => 'Désinstaller';

  @override
  String appHidden(Object app) {
    return '$app masquée';
  }

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get sectionAppearance => 'Apparence';

  @override
  String get theme => 'Thème';

  @override
  String get themeSystem => 'Automatique';

  @override
  String get themeLight => 'Clair';

  @override
  String get themeDark => 'Sombre';

  @override
  String get colors => 'Couleurs';

  @override
  String get colorSource => 'Source des couleurs';

  @override
  String get colorSystem => 'Système';

  @override
  String get colorSystemDesc => 'Suit les couleurs d’Android';

  @override
  String get colorPreset => 'Couleur choisie';

  @override
  String get paletteStyle => 'Style de palette';

  @override
  String get styleTonalSpot => 'Tonal';

  @override
  String get styleVibrant => 'Vif';

  @override
  String get styleExpressive => 'Expressif';

  @override
  String get styleNeutral => 'Neutre';

  @override
  String get styleMonochrome => 'Monochrome';

  @override
  String get contrast => 'Contraste';

  @override
  String get contrastStandard => 'Standard';

  @override
  String get contrastMedium => 'Moyen';

  @override
  String get contrastHigh => 'Élevé';

  @override
  String get themedIcons => 'Icônes thématiques';

  @override
  String get themedIconsDesc =>
      'Icônes monochromes teintées avec la palette (Android 13+)';

  @override
  String get preview => 'Aperçu';

  @override
  String get presetLaguna => 'Lagune';

  @override
  String get presetSalvia => 'Sauge';

  @override
  String get presetTerracotta => 'Terre cuite';

  @override
  String get presetAmbra => 'Ambre';

  @override
  String get presetLampone => 'Framboise';

  @override
  String get presetLavanda => 'Lavande';

  @override
  String get presetPetrolio => 'Bleu canard';

  @override
  String get presetGrafite => 'Graphite';

  @override
  String get sectionApps => 'Apps';

  @override
  String get allAppsLayout => 'Vue Toutes les apps';

  @override
  String get showSystemApps => 'Afficher les apps système';

  @override
  String get showSystemAppsDesc =>
      'Téléphone, Appareil photo, Paramètres et apps préinstallées';

  @override
  String get hiddenApps => 'Apps masquées';

  @override
  String get hiddenAppsEmpty => 'Aucune app masquée';

  @override
  String get restore => 'Restaurer';

  @override
  String get fixedOrder => 'Ordre fixe des Collections';

  @override
  String get fixedOrderDesc =>
      'Ne pas réorganiser cartes et icônes selon le contexte';

  @override
  String get hiddenCategories => 'Catégories masquées';

  @override
  String get hiddenCategoriesEmpty => 'Aucune catégorie masquée';

  @override
  String get sectionLanguage => 'Langue';

  @override
  String get languageSystem => 'Langue du système';

  @override
  String get sectionLauncher => 'Launcher';

  @override
  String get setDefault => 'Définir libreGLIDE comme app d’accueil';

  @override
  String get isDefault => 'libreGLIDE est l’app d’accueil par défaut';

  @override
  String get androidSettings => 'Paramètres Android';

  @override
  String get sectionData => 'Données et confidentialité';

  @override
  String launchesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lancements enregistrés',
      one: '1 lancement enregistré',
      zero: 'Aucun lancement enregistré',
    );
    return '$_temp0';
  }

  @override
  String get privacyNote =>
      'Toutes les données restent sur le téléphone et n’en sortent que si tu les exportes. La base de données est exclue de la sauvegarde cloud.';

  @override
  String get clearHistory => 'Effacer l’historique des lancements';

  @override
  String get clearHistoryConfirm =>
      'Effacer l’historique ? Les prédictions repartiront de zéro.';

  @override
  String get cancel => 'Annuler';

  @override
  String get delete => 'Effacer';

  @override
  String get historyCleared => 'Historique effacé';

  @override
  String get diagnostics => 'Diagnostic';

  @override
  String get diagnosticsDesc => 'Contexte actuel et raisons des prédictions';

  @override
  String get currentContext => 'Contexte actuel';

  @override
  String get predictions => 'Prédictions';

  @override
  String get noPredictions =>
      'Une app doit être lancée au moins 3 fois pour être prédite.';

  @override
  String get sectionAbout => 'À propos';

  @override
  String get aboutDesc => 'Launcher contextuel open source et 100 % local.';

  @override
  String get tabSpace => 'Space';

  @override
  String get tabCollections => 'Collections';

  @override
  String get tabAllApps => 'A-Z';

  @override
  String get spacesTitle => 'Spaces';

  @override
  String get azHeader => 'Apps A-Z';

  @override
  String get actionAlarm => 'Alarme';

  @override
  String get actionDnd => 'Ne pas déranger';

  @override
  String get infoBanner =>
      'Des infos utiles apparaîtront ici au fil de la journée.';

  @override
  String get nowAppsHeader => 'Pour ce moment';

  @override
  String get nextAlarm => 'Prochaine alarme';

  @override
  String get noAlarm => 'Aucune alarme définie';

  @override
  String get addToDock => 'Ajouter au dock';

  @override
  String get searchApps => 'Rechercher';

  @override
  String get searchTopApps => 'Apps au-dessus de la recherche';

  @override
  String get searchTopAppsDesc =>
      'Les plus utilisées dans ce contexte, au-dessus des résultats de recherche.';

  @override
  String hiddenSummary(int apps, int categories) {
    return '$apps apps, $categories catégories';
  }

  @override
  String get languageSystemShort => 'Système';

  @override
  String version(Object version) {
    return 'Version $version';
  }

  @override
  String get agendaToday => 'Aujourd’hui';

  @override
  String get agendaTomorrow => 'Demain';

  @override
  String get noEventsToday => 'Aucun événement aujourd’hui';

  @override
  String get noEventsTomorrow => 'Aucun événement demain';

  @override
  String get allDay => 'Toute la journée';

  @override
  String get agendaPermission =>
      'Affiche ici tes prochains événements d’agenda.';

  @override
  String get allow => 'Autoriser';

  @override
  String get newEvent => 'Nouvel événement';

  @override
  String get navigate => 'Itinéraire';

  @override
  String get nowPlaying => 'En écoute';

  @override
  String get mediaPermission =>
      'Contrôle ta musique d’ici. L’accès aux notifications est nécessaire : libreGLIDE l’utilise uniquement pour les commandes multimédias et ne lit ni n’enregistre jamais les notifications.';

  @override
  String get play => 'Lecture';

  @override
  String get pause => 'Pause';

  @override
  String get next => 'Suivant';

  @override
  String get previous => 'Précédent';

  @override
  String get sectionSpace => 'Space';

  @override
  String get cardAgenda => 'Agenda';

  @override
  String get cardAgendaDesc => 'Prochains événements de l’agenda du téléphone';

  @override
  String get cardMedia => 'En écoute';

  @override
  String get cardMediaDesc =>
      'Commandes de la musique en cours, aussi quand tu branches un casque';

  @override
  String get privacyPolicy => 'Politique de confidentialité';

  @override
  String get privacyPolicyDesc =>
      'Ce qui reste sur le téléphone, et ce qui n’y reste pas';

  @override
  String get openSource => 'Bibliothèques open source';

  @override
  String get openSourceDesc =>
      'Licences des composants utilisés par libreGLIDE';

  @override
  String openSourceCount(int count) {
    return '$count composants';
  }

  @override
  String licenseCount(int count) {
    return '$count licences';
  }

  @override
  String get appLicense => 'Licence de libreGLIDE';

  @override
  String get appLicenseUndefined => 'À définir avant la publication';

  @override
  String get unsplashAttribution =>
      'Les photos des fonds d’écran sont d’auteurs Unsplash, crédités sur l’accueil et dans le Space';

  @override
  String get showOnboarding => 'Revoir la présentation';

  @override
  String get obWelcomeTitle => 'Bienvenue dans libreGLIDE';

  @override
  String get obWelcomeText =>
      'Le launcher qui change avec ton moment : il te montre les bonnes apps et infos quand tu en as besoin.';

  @override
  String get obStart => 'Commencer';

  @override
  String get obNext => 'Suivant';

  @override
  String get obBack => 'Retour';

  @override
  String get obHowTitle => 'Comment ça marche';

  @override
  String get obHowSpace =>
      'Le Space affiche ton agenda, ta musique et les apps adaptées à ce moment.';

  @override
  String get obHowHome =>
      'L’accueil laisse de la place à ton fond d’écran, avec un dock de tes apps préférées.';

  @override
  String get obHowCollections =>
      'Les Collections regroupent tes apps automatiquement et placent en premier celles que tu utilises maintenant.';

  @override
  String get obHowSearch =>
      'Balaie vers le haut pour chercher une app, vers le bas pour tes contacts.';

  @override
  String get obHowDrawer =>
      'Touche les bandes colorées en haut pour choisir un Space.';

  @override
  String get obPrivacyTitle => 'Ta vie privée';

  @override
  String get obPrivacy1 => 'Pas de compte, pas de pub, pas de télémétrie.';

  @override
  String get obPrivacy2 =>
      'Tes habitudes restent sur le téléphone : le développeur ne les voit jamais.';

  @override
  String get obPrivacy3 =>
      'Internet uniquement si tu choisis le fond d’écran Unsplash avec ta propre clé.';

  @override
  String get obReadPolicy => 'Lire la politique complète';

  @override
  String get obCollectionsTitle => 'Tes collections';

  @override
  String get obCollectionsText =>
      'Lesquelles utilises-tu le plus ? Elles resteront en haut les premières semaines, puis ton usage réel prendra le relais.';

  @override
  String get obCollectionsHint =>
      'Choisis-en autant que tu veux, ou aucune. L’ordre de sélection compte.';

  @override
  String get obFinishTitle => 'Dernières retouches';

  @override
  String get obDockPrefill =>
      'Proposer un dock avec téléphone, messages, appareil photo et navigateur';

  @override
  String get obFinish => 'Terminé';

  @override
  String photoBy(Object name) {
    return 'Photo de $name · Unsplash';
  }

  @override
  String get sectionWallpaper => 'Fond d’écran';

  @override
  String get contextWallpaper => 'Fond d’écran contextuel';

  @override
  String get contextWallpaperDesc =>
      'Dans le Space, une photo Unsplash qui change avec le moment : fêtes, voyages, météo, heure du jour, musique. Seulement dans libreGLIDE : le fond d’écran du téléphone n’est jamais modifié.';

  @override
  String get spaceHeaderBlur => 'Flouter la photo du Space';

  @override
  String get spaceHeaderBlurDesc =>
      'Légèrement floutée derrière la date et le nom du Space, pour mieux les lire.';

  @override
  String get creditHome => 'Crédits sur l’accueil';

  @override
  String get creditSpace => 'Crédits dans le Space';

  @override
  String get creditDesc =>
      'Photographe et Unsplash sur la photo, comme le demandent les règles d’Unsplash. Si tu les masques, ils restent ci-dessous.';

  @override
  String get currentPhotoHome => 'Photo de l’accueil';

  @override
  String get currentPhotoSpace => 'Photo du Space';

  @override
  String get dailyWallpaper => 'Fond d’écran du jour';

  @override
  String get dailyWallpaperDesc =>
      'Une nouvelle photo Unsplash chaque jour sur l’accueil, choisie à la première ouverture.';

  @override
  String get changeDailyPhoto => 'Changer la photo du jour';

  @override
  String get wallpaperStyle => 'Style des photos';

  @override
  String get photoStyleNone => 'Aucun';

  @override
  String get photoStyleAesthetic => 'Aesthetic';

  @override
  String get photoStyleNature => 'Nature';

  @override
  String get photoStyleMinimal => 'Minimaliste';

  @override
  String get photoStyleAbstract => 'Abstrait';

  @override
  String get photoStyleArchitecture => 'Architecture';

  @override
  String get photoStyleDark => 'Sombre';

  @override
  String get unsplashKey => 'Clé Unsplash';

  @override
  String get unsplashKeyNone => 'Non définie';

  @override
  String unsplashKeySet(Object hint) {
    return 'Définie ($hint)';
  }

  @override
  String get unsplashKeyHelp =>
      'Crée une application gratuite sur unsplash.com/developers et colle ici son Access Key. La clé reste sur le téléphone.';

  @override
  String get unsplashGetKey => 'Obtenir une clé';

  @override
  String get save => 'Enregistrer';

  @override
  String get remove => 'Supprimer';

  @override
  String get keyInvalid => 'Clé non valide';

  @override
  String get keyCheckFailed =>
      'Impossible de vérifier la clé : vérifie ta connexion';

  @override
  String get changePhoto => 'Changer de photo';

  @override
  String changePhotoDesc(Object moment) {
    return 'Une autre photo pour ce moment : $moment';
  }

  @override
  String get wallpaperError =>
      'Photo indisponible : le fond d’écran du téléphone est affiché';

  @override
  String get wallpaperNetworkNote =>
      'Utilise Internet uniquement quand le moment change, avec ta clé. Sans clé, libreGLIDE ne se connecte jamais.';

  @override
  String get sectionGestures => 'Gestes';

  @override
  String get swipeDownAction => 'Balayer vers le bas';

  @override
  String get swipeUpAction => 'Balayer vers le haut';

  @override
  String get gestureSearch => 'Recherche';

  @override
  String get gestureContacts => 'Contacts';

  @override
  String get gestureNone => 'Rien';

  @override
  String get gesturesDesc =>
      'Sur l’accueil et, pour le balayage vers le bas, aussi sur la barre du haut. Dans la recherche et les contacts, le balayage inverse ferme et revient à l’accueil.';

  @override
  String get collectionLabels => 'Noms dans les Collections';

  @override
  String get collectionLabelsDesc =>
      'Afficher les noms sous les icônes dans les rangées repliées et les apps de l\'Espace';

  @override
  String get contactsTitle => 'Contacts';

  @override
  String get contactsFavorites => 'Favoris et plus utilisés';

  @override
  String get contactsSearchHint => 'Rechercher des contacts';

  @override
  String get contactsPermission =>
      'Affiche ici tes contacts favoris et les plus utilisés. Les contacts sont lus uniquement sur le téléphone.';

  @override
  String get contactsEmpty =>
      'Ajoute une étoile à tes contacts favoris dans l’app Contacts : ils apparaîtront ici, avec ceux que tu ouvres le plus.';

  @override
  String get noContactsFound => 'Aucun contact trouvé';

  @override
  String get call => 'Appeler';

  @override
  String get message => 'Message';

  @override
  String get openContact => 'Fiche du contact';

  @override
  String get searchCollections => 'Parcourir les collections';

  @override
  String get cardEvening => 'Bonne nuit';

  @override
  String get cardEveningDesc =>
      'Le soir : l’alarme de demain, Ne pas déranger et un rappel de recharge';

  @override
  String get dndOn => 'Ne pas déranger activé';

  @override
  String chargeReminder(int level) {
    return 'Batterie à $level % : mets-le en charge pour la nuit';
  }

  @override
  String get cardNextPlace => 'Prochaine destination';

  @override
  String get cardNextPlaceDesc =>
      'Itinéraire vers ton prochain événement avec un lieu, dans les 3 heures avant';

  @override
  String get cardTravel => 'En voyage';

  @override
  String get cardTravelDesc =>
      'Heure de chez toi et apps de voyage quand tu es dans un autre fuseau horaire ou en roaming';

  @override
  String homeTime(Object time) {
    return 'Chez toi, il est $time';
  }

  @override
  String get travelHere => 'J’habite ici maintenant';

  @override
  String get autoLaunch => 'Ouvrir la seule app trouvée';

  @override
  String get autoLaunchDesc =>
      'Quand une seule app correspond à ta saisie (au moins 2 lettres), elle s’ouvre automatiquement.';

  @override
  String get sectionSearchGestures => 'Recherche et gestes';

  @override
  String resultsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count résultats',
      one: '1 résultat',
    );
    return '$_temp0';
  }

  @override
  String get cardWidgets => 'Widgets';

  @override
  String get cardWidgetsDesc => 'Widgets Android pleine largeur dans le Space';

  @override
  String get addWidget => 'Ajouter un widget';

  @override
  String get noWidgets => 'Aucun widget dans le Space : ajoutes-en un.';

  @override
  String get widgetHeight => 'Hauteur';

  @override
  String get widgetShorter => 'Moins haut';

  @override
  String get widgetTaller => 'Plus haut';

  @override
  String get moveUp => 'Monter';

  @override
  String get moveDown => 'Descendre';

  @override
  String widgetMinSize(int w, int h) {
    return 'Au moins $w×$h dp';
  }

  @override
  String widgetCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count widgets',
      one: '1 widget',
      zero: 'Aucun widget',
    );
    return '$_temp0';
  }

  @override
  String get cardWeather => 'Météo';

  @override
  String get cardWeatherDesc =>
      'Prévisions Open-Meteo selon ta position approximative, arrondie à environ 10 km. Utilise Internet.';

  @override
  String get weatherPermission =>
      'La météo a besoin de ta position approximative : elle est arrondie à environ 10 km avant de demander les prévisions.';

  @override
  String get weatherHere => 'Ici';

  @override
  String get weatherSource => 'Données météo : Open-Meteo.com (CC BY 4.0)';

  @override
  String get weatherClear => 'Dégagé';

  @override
  String get weatherPartly => 'Partiellement nuageux';

  @override
  String get weatherCloudy => 'Nuageux';

  @override
  String get weatherFog => 'Brouillard';

  @override
  String get weatherDrizzle => 'Bruine';

  @override
  String get weatherRain => 'Pluie';

  @override
  String get weatherSnow => 'Neige';

  @override
  String get weatherShowers => 'Averses';

  @override
  String get weatherStorm => 'Orage';

  @override
  String get cardCar => 'En voiture';

  @override
  String get cardCarDesc =>
      'Cartes, musique et prochaine destination quand tu conduis (Android Auto ou autoradio Bluetooth)';

  @override
  String get carBluetooth => 'Reconnaître l’autoradio Bluetooth';

  @override
  String get carBluetoothDesc =>
      'Facultatif : nécessite l’autorisation Appareils à proximité. Sans elle, seul Android Auto est reconnu.';

  @override
  String get screenTime => 'Temps d’écran';

  @override
  String get screenTimeDesc =>
      'Combien de temps tu as utilisé le téléphone aujourd’hui, comme dans Olauncher. Nécessite l’accès aux données d’utilisation ; les données restent sur le téléphone.';

  @override
  String get screenTimeOff => 'Désactivé';

  @override
  String get screenTimeHome => 'Accueil';

  @override
  String get screenTimeSpace => 'Space';

  @override
  String get screenTimeToday => 'Aujourd’hui';

  @override
  String get screenTimePermission =>
      'Pour afficher le temps d’écran, l’accès aux données d’utilisation est nécessaire. Les données restent sur le téléphone.';

  @override
  String durationHM(int h, int m) {
    return '$h h $m min';
  }

  @override
  String durationM(int m) {
    return '$m min';
  }

  @override
  String get spaceHome => 'Maison';

  @override
  String get spaceWork => 'Travail';

  @override
  String get spaceSchool => 'École';

  @override
  String get spaceWorkOrSchool => 'Travail/École';

  @override
  String get spaceMoving => 'En déplacement';

  @override
  String get spaceListening => 'En écoute';

  @override
  String get spaceTravel => 'En voyage';

  @override
  String get spaceNightOut => 'Soirée';

  @override
  String get spaceExercise => 'Activité physique';

  @override
  String get exerciseSpaceDesc =>
      'Un Space pour la course et la marche rapide, reconnues par le podomètre du téléphone quand tu ouvres le launcher. Aucun service en arrière-plan.';

  @override
  String get spacesPlaces => 'Selon le lieu';

  @override
  String get spacesContext => 'Selon le contexte';

  @override
  String get spacesTime => 'Selon l’heure';

  @override
  String get actionEmail => 'E-mail';

  @override
  String get actionToHome => 'Rentrer';

  @override
  String get actionToWork => 'Aller au travail';

  @override
  String get actionMaps => 'Cartes';

  @override
  String get sectionPlaces => 'Lieux';

  @override
  String get placesEnabled => 'Reconnaître maison et travail';

  @override
  String get placesEnabledDesc =>
      'Les Spaces Maison et Travail/École s’activent tout seuls. Utilise la position précise uniquement quand tu utilises le launcher, et le Wi-Fi comme empreinte chiffrée ; tout reste sur le téléphone.';

  @override
  String get placesPermission =>
      'Pour reconnaître ta maison et ton travail, la position précise est nécessaire, uniquement quand tu utilises le launcher. Les coordonnées et réseaux Wi-Fi restent sur le téléphone et ne sont jamais envoyés.';

  @override
  String get placeHome => 'Maison';

  @override
  String get placeWork => 'Travail/École';

  @override
  String placeRecognized(int percent) {
    return 'Reconnu ($percent %)';
  }

  @override
  String get placeByUser => 'Défini par toi';

  @override
  String get placeLearningHome => 'Apprentissage : il faut quelques nuits';

  @override
  String get placeLearningWork =>
      'Apprentissage : il faut quelques jours ouvrés';

  @override
  String get workLabel => 'Nom du Space de travail';

  @override
  String get workLabelWork => 'Travail';

  @override
  String get workLabelSchool => 'École';

  @override
  String get hereIsHome => 'C’est chez moi';

  @override
  String get hereIsWork => 'C’est mon travail/école';

  @override
  String get notHome => 'Ce n’est pas chez moi';

  @override
  String get notWork => 'Ce n’est pas mon travail/école';

  @override
  String get hereUnknown =>
      'Lieu actuel encore inconnu : reviens après quelques minutes sur le launcher.';

  @override
  String get resetPlaces => 'Réinitialiser les lieux';

  @override
  String get resetPlacesConfirm =>
      'Oublier tous les lieux et échantillons de position ? La maison et le travail seront reconnus à nouveau.';

  @override
  String placesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lieux',
      one: '1 lieu',
      zero: 'Aucun lieu',
    );
    return '$_temp0';
  }

  @override
  String get editHome => 'Modifier les widgets';

  @override
  String homeWidgetsFull(int max) {
    return 'Jusqu’à $max widgets sur l’accueil';
  }

  @override
  String get done => 'Terminé';

  @override
  String widgetRows(int rows) {
    String _temp0 = intl.Intl.pluralLogic(
      rows,
      locale: localeName,
      other: '$rows lignes',
      one: '1 ligne',
    );
    return '$_temp0';
  }

  @override
  String get cardParking => 'Où je suis garé';

  @override
  String get cardParkingDesc =>
      'Quand tu te déconnectes de l’autoradio Bluetooth, enregistre où tu as laissé la voiture. Utilise la position en arrière-plan uniquement à ce moment-là ; elle reste sur le téléphone.';

  @override
  String parkedAt(Object time, Object ago) {
    return 'Garé à $time · $ago';
  }

  @override
  String parkedImprecise(int meters) {
    return 'Position approximative ($meters m)';
  }

  @override
  String get forget => 'Oublier';

  @override
  String agoMinutes(int m) {
    return 'il y a $m min';
  }

  @override
  String agoHours(int h) {
    return 'il y a $h h';
  }

  @override
  String get parkingNeedsBluetooth =>
      'Pour reconnaître la voiture, l’autorisation Appareils à proximité est nécessaire.';

  @override
  String get parkingNeedsPrecise =>
      'Pour enregistrer l’emplacement, la position précise est nécessaire.';

  @override
  String get parkingNeedsBackground =>
      'Pour enregistrer l’emplacement quand tu sors de la voiture (téléphone en poche), la position \"Toujours autoriser\" est nécessaire. Elle n’est utilisée qu’à la déconnexion de l’autoradio.';

  @override
  String get parkingWaiting =>
      'L’emplacement sera enregistré la prochaine fois que tu te déconnecteras de l’autoradio.';

  @override
  String get spaceAutomatic => 'Automatique';

  @override
  String get spaceNow => 'maintenant';

  @override
  String get workLabelAutomatic => 'Automatique';

  @override
  String get workKindLearning =>
      'Après quelques jours, il devine à tes horaires s’il s’agit du travail (matin et après-midi) ou de l’école (le matin seulement).';

  @override
  String workKindDetected(String kind) {
    return 'Détecté à tes horaires : $kind';
  }

  @override
  String get groupLook => 'Apparence et contenu';

  @override
  String get groupBehavior => 'Comportement';

  @override
  String get groupSystem => 'Système';

  @override
  String get stateOn => 'Activé';

  @override
  String get stateOff => 'Désactivé';

  @override
  String cardsActive(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cartes actives',
      one: '1 carte active',
      zero: 'Aucune carte active',
    );
    return '$_temp0';
  }

  @override
  String get parkingBackgroundBlocked =>
      'Android n’affiche plus la demande. Ouvre les paramètres de l’app, puis Autorisations › Position et choisis \"Toujours autoriser\". La position n’est lue que quand tu te déconnectes de l’autoradio.';

  @override
  String get openSettings => 'Ouvrir les paramètres';

  @override
  String get turnOff => 'Désactiver';

  @override
  String get obHowDetox =>
      'Digital detox (dans les paramètres) : bloque les apps qui te distraient, toute la journée ou sur une plage horaire, avec un PIN.';

  @override
  String get notNow => 'Pas maintenant';

  @override
  String get ok => 'OK';

  @override
  String get detoxTitle => 'Digital detox';

  @override
  String get detoxDesc =>
      'Bloque les apps de ton choix, toute la journée ou sur une plage horaire. Quand tu les ouvres, un écran noir apparaît.';

  @override
  String get detoxServiceTitle => 'Activer le service de blocage';

  @override
  String get detoxServiceExplain =>
      'Pour savoir quand tu ouvres une app bloquée, libreGLIDE utilise un service d’accessibilité. Il reçoit uniquement le nom de l’app qui passe au premier plan : il ne lit pas l’écran, n’enregistre rien et ne consomme pas de batterie quand tu ne changes pas d’app.\n\nDans les paramètres qui s’ouvrent, active \"libreGLIDE · Digital detox\". Si Android l’affiche désactivé (\"paramètre restreint\"), ouvre les infos de l’app libreGLIDE, menu ⋮, \"Autoriser les paramètres restreints\".';

  @override
  String get detoxServiceOpen => 'Ouvrir les paramètres';

  @override
  String get detoxServiceOff => 'Service de blocage désactivé';

  @override
  String get detoxServiceOffDesc =>
      'Les apps ne sont bloquées que si tu les ouvres depuis libreGLIDE. Touche pour l’activer.';

  @override
  String get detoxServiceOn => 'Service de blocage activé';

  @override
  String get detoxActiveNow => 'Le blocage est actif maintenant.';

  @override
  String detoxStartsAt(String time) {
    return 'Le blocage commence à $time.';
  }

  @override
  String get detoxPin => 'PIN';

  @override
  String get detoxSetPin => 'Définir le PIN';

  @override
  String get detoxChangePin => 'Changer le PIN';

  @override
  String get detoxPinDesc =>
      'De 8 à 16 caractères. Nécessaire pour débloquer les apps et modifier ces paramètres pendant le detox.';

  @override
  String get detoxPinLabel => 'PIN';

  @override
  String get detoxOldPin => 'PIN actuel';

  @override
  String get detoxNewPin => 'Nouveau PIN';

  @override
  String get detoxConfirmPin => 'Confirmer le PIN';

  @override
  String get detoxPinLength => 'De 8 à 16 caractères.';

  @override
  String get detoxPinMismatch => 'Les deux PIN ne correspondent pas.';

  @override
  String get detoxPinWarning =>
      'Ne le perds pas : il est impossible de le récupérer. Sans le PIN, le seul moyen de sortir du detox est de redémarrer le téléphone en mode sans échec.';

  @override
  String get detoxWrongPin => 'PIN incorrect.';

  @override
  String detoxWait(int seconds) {
    return 'Trop de tentatives. Réessaie dans $seconds s.';
  }

  @override
  String get detoxSchedule => 'Horaires';

  @override
  String get detoxWhen => 'Quand';

  @override
  String get detoxAllDay => 'Toute la journée';

  @override
  String get detoxTimeRange => 'Plage horaire';

  @override
  String get detoxFrom => 'De';

  @override
  String get detoxTo => 'À';

  @override
  String get detoxUnlock => 'Déblocage';

  @override
  String get detoxUnlockTitle => 'Apps bloquées';

  @override
  String get detoxUnlockPin => 'Avec le PIN';

  @override
  String get detoxUnlockNever => 'Jamais';

  @override
  String get detoxUnlockPinDesc =>
      'Avec le PIN, l’app reste ouverte jusqu’à ce que tu la quittes.';

  @override
  String get detoxUnlockNeverDesc =>
      'Aucun déblocage : tu peux seulement revenir à l’accueil.';

  @override
  String get detoxApps => 'Apps';

  @override
  String get detoxLockedApps => 'Apps bloquées';

  @override
  String detoxAppsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count apps',
      one: '1 app',
      zero: 'Aucune app',
    );
    return '$_temp0';
  }

  @override
  String get detoxHide => 'Masquer les apps bloquées';

  @override
  String get detoxHideDesc =>
      'Pendant le detox, elles disparaissent des Collections, de A-Z, de la recherche et du dock. Elles restent séparées des apps masquées : à la fin du detox, elles reviennent à leur place.';

  @override
  String get detoxEmergency =>
      'Si tu bloques Paramètres, il te faudra le PIN ici dans libreGLIDE pour désactiver le detox. Si tu le perds, redémarre en mode sans échec : Android désactive les services d’accessibilité.';

  @override
  String get detoxSystemGroup => 'Système';

  @override
  String get detoxSystemGroupDesc =>
      'Installation et désinstallation, Paramètres, Play Store';

  @override
  String detoxGroupCount(int locked, int total) {
    return '$locked sur $total bloquées';
  }

  @override
  String get frostedGlass => 'Verre dépoli';

  @override
  String get frostedGlassDesc =>
      'Space, Collections et A-Z deviennent translucides sur le fond d’écran flouté. Android gère le flou ; en économie d’énergie, les pages redeviennent opaques.';

  @override
  String get dockStyle => 'Dock';

  @override
  String get homeTabLabel => 'Onglet Accueil';

  @override
  String get homeTabDate => 'Date';

  @override
  String get homeTabWeather => 'Météo';

  @override
  String get homeTabWeatherOff =>
      'Pour la météo, active la carte Météo dans les réglages du Space.';

  @override
  String get dockTray => 'Plateau';

  @override
  String get dockTransparent => 'Transparent';

  @override
  String get homeCorners => 'Coins arrondis sur l’accueil';

  @override
  String get homeCornersDesc =>
      'La barre et le dock encadrent le fond d’écran avec des coins légèrement arrondis.';

  @override
  String get lockPortrait => 'Verrouiller en portrait';

  @override
  String get lockPortraitDesc =>
      'Le launcher reste en portrait même si tu tournes le téléphone. Désactive-le pour suivre la rotation automatique.';

  @override
  String get learnFromUsage => 'Apprendre aussi des apps ouvertes ailleurs';

  @override
  String get learnFromUsageDesc =>
      'Utilise l’historique d’utilisation d’Android (notifications, récents, liens) pour suggérer tout de suite les bonnes apps. Il reste sur le téléphone ; le désactiver l’efface.';

  @override
  String get usageAccessNeeded => 'Autoriser l’accès aux données d’utilisation';

  @override
  String get usageAccessNeededDesc =>
      'Nécessaire pour lire l’historique d’utilisation d’Android.';

  @override
  String launchSourcesNote(int usage) {
    return 'dont $usage depuis l’historique Android';
  }

  @override
  String get weatherTomorrow => 'Demain';

  @override
  String rainChance(int percent) {
    return 'Risque de pluie $percent %';
  }

  @override
  String get actionAlarmTomorrow => 'Réveil de demain';

  @override
  String get actionTimer => 'Minuteur';

  @override
  String get actionFood => 'Où manger';

  @override
  String get foodQuery => 'restaurants';

  @override
  String get cardShowHere => 'Toujours afficher dans ce Space';

  @override
  String get cardHideHere => 'Masquer dans ce Space';

  @override
  String get cardAuto => 'Automatique (comme avant)';

  @override
  String get cardCategory => 'Apps du moment';

  @override
  String get diagnosticsCards => 'Cartes du Space';

  @override
  String get spaceCards => 'Cartes par Space';

  @override
  String get spaceCardsEntryDesc =>
      'Choisis les cartes affichées dans chaque Space';

  @override
  String get spaceCardsDesc =>
      'Automatique suit le moment et ton usage. Toujours et Jamais ne valent que pour ce Space et l’emportent sur tout.';

  @override
  String spaceCardsCustom(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count choix personnels',
      one: '1 choix personnel',
    );
    return '$_temp0';
  }

  @override
  String get cardAutoShort => 'Automatique';

  @override
  String get cardAlways => 'Toujours';

  @override
  String get cardNever => 'Jamais';

  @override
  String get cardDefaultShown => 'Visible par défaut';

  @override
  String get cardDefaultHidden => 'Masquée par défaut';

  @override
  String get manageSpaceCards => 'Gérer les cartes de ce Space…';

  @override
  String unsplashKeyVerified(String suffix) {
    return 'Clé vérifiée · $suffix';
  }
}
