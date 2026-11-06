/// Impostazioni dell'utente, salvate in shared_preferences
/// (spec-viste-app §6–§8).
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/categories.dart';
import '../core/detox.dart';
import '../core/space.dart';
import '../core/space_profile.dart';
import '../platform/launcher_bridge.dart';

enum ColorSource { system, preset }

enum AllAppsLayout { grid, list }

/// Dove mostrare il tempo di utilizzo.
enum ScreenTimePlace { off, home, space }

/// Azione di uno swipe verticale sulla Home.
enum GestureAction { search, contacts, none }

/// Stile del dock della Home: vassoio pieno (default) o icone sullo sfondo.
enum DockStyle { tray, transparent }

/// Stili della palette esposti all'utente (sottoinsieme di
/// [DynamicSchemeVariant]).
const List<DynamicSchemeVariant> paletteStyles = [
  DynamicSchemeVariant.tonalSpot,
  DynamicSchemeVariant.vibrant,
  DynamicSchemeVariant.expressive,
  DynamicSchemeVariant.neutral,
  DynamicSchemeVariant.monochrome,
];

class SettingsController extends ChangeNotifier {
  SettingsController(this._prefs) {
    _load();
  }

  static Future<SettingsController> load() async =>
      SettingsController(await SharedPreferences.getInstance());

  final SharedPreferences _prefs;

  // Aspetto
  ThemeMode themeMode = ThemeMode.system;
  ColorSource colorSource = ColorSource.system;
  int presetIndex = 0;
  DynamicSchemeVariant paletteStyle = DynamicSchemeVariant.tonalSpot;
  double contrast = 0;
  bool themedIcons = false;

  // App
  AllAppsLayout allAppsLayout = AllAppsLayout.grid;
  bool showSystemApps = true;
  bool fixedCollectionOrder = false;
  Set<String> hiddenApps = {};
  List<String> favorites = [];
  Map<String, AppCategory> categoryOverrides = {};
  List<AppCategory> pinnedCategories = [];
  Set<AppCategory> hiddenCategories = {};

  /// Sfondo contestuale (Unsplash). La chiave è dell'utente e resta sul
  /// telefono.
  bool contextWallpaper = false;
  String? unsplashKey;

  /// Fuso orario di casa (es. "Europe/Rome"): se quello attuale è diverso
  /// l'utente è considerato in viaggio.
  String? homeTimeZone;

  /// "Cambia foto": scarto rispetto alla foto del giorno.
  int wallpaperShuffle = 0;
  String? wallpaperShuffleDay;

  /// Foto in uso (JSON), per non riscaricarla a ogni avvio.
  String? wallpaperState;

  /// Gesti sulla Home: di default ricerca in giù e contatti in su.
  GestureAction swipeDown = GestureAction.contacts;
  GestureAction swipeUp = GestureAction.search;

  /// Ricerca: con una sola app corrispondente la apre da sola.
  bool autoLaunchSingle = true;

  /// Nomi sotto le icone nelle righe delle Collections (di default: no).
  bool collectionLabels = false;

  /// Altre card dello Space.
  bool eveningCard = true;
  bool nextPlaceCard = true;
  bool travelCard = true;
  bool weatherCard = false;

  /// Riconoscimento di casa e lavoro (serve la posizione precisa).
  bool placesEnabled = true;

  /// Etichetta del luogo di lavoro: auto ("Lavoro/Scuola"), lavoro, scuola.
  String workLabel = 'auto';
  ScreenTimePlace screenTime = ScreenTimePlace.off;

  /// Widget Android nello Space, in ordine.
  List<PlacedWidget> widgets = [];

  /// Widget Android sulla Home, sopra il dock (al massimo [maxHomeWidgets]).
  List<PlacedWidget> homeWidgets = [];
  static const maxHomeWidgets = 3;

  /// Altezza di una riga della griglia della Home, in dp.
  static const homeRowHeight = 88.0;
  bool carCard = true;

  /// "Dove ho parcheggiato" (spento di default: usa la posizione in
  /// background).
  bool parkingCard = false;

  /// Onboarding completato.
  bool onboardingDone = false;

  /// Vetro smerigliato: pagine semitrasparenti sullo sfondo sfocato
  /// (spento di default).
  bool frostedGlass = false;

  /// Dock della Home: vassoio pieno che incornicia lo sfondo, o trasparente.
  DockStyle dockStyle = DockStyle.tray;

  /// Angoli appena arrotondati della finestra sullo sfondo della Home.
  bool homeCorners = true;

  /// Impara anche dalle app aperte fuori da libreGLIDE (cronologia di
  /// utilizzo di Android, se l'accesso c'è).
  bool learnFromUsage = true;

  /// Scelte per le card degli Space: "spazio/card" → mostra o nascondi.
  Map<String, CardRule> cardRules = {};

  Map<SpaceCard, CardRule> cardRulesFor(SpaceKind kind) {
    final out = <SpaceCard, CardRule>{};
    final prefix = '${kind.name}/';
    cardRules.forEach((key, rule) {
      if (!key.startsWith(prefix)) return;
      final name = key.substring(prefix.length);
      for (final c in SpaceCard.values) {
        if (c.name == name) out[c] = rule;
      }
    });
    return out;
  }

  /// Digital detox (spento di default). Il PIN non sta qui: lo custodisce
  /// la parte nativa, solo come hash.
  bool detoxEnabled = false;
  bool detoxAllDay = true;
  int detoxStart = 22 * 60;
  int detoxEnd = 7 * 60;

  /// Le app bloccate si possono sbloccare con il PIN (altrimenti mai).
  bool detoxUnlockable = true;

  /// Pacchetti bloccati. Separati dalle app nascoste: spegnendo il detox
  /// tutto torna come prima.
  Set<String> detoxApps = {};

  /// Durante il detox le app bloccate spariscono dal launcher.
  bool detoxHideApps = false;

  DetoxSchedule get detoxSchedule =>
      DetoxSchedule(allDay: detoxAllDay, start: detoxStart, end: detoxEnd);

  /// Card dinamiche dello Space.
  bool agendaCard = true;
  bool mediaCard = true;

  /// App suggerite sopra la barra della ricerca globale: 4 o 8.
  int searchTopApps = 8;

  /// Il banner informativo dello Space è stato chiuso.
  bool infoBannerDismissed = false;

  // Lingua: null = lingua di sistema.
  Locale? locale;

  /// Avviso dedicato all'aspetto (tema, colori, contrasto, lingua, icone a
  /// tema): solo questo ricostruisce la MaterialApp.
  final ValueNotifier<int> appearance = ValueNotifier(0);

  /// Incrementato a ogni modifica che cambia le Collections.
  int collectionsRevision = 0;

  /// Posti del dock: una riga da 4, come chiesto (sempre 4 posti).
  static const maxFavorites = 4;

  void _load() {
    final p = _prefs;
    themeMode =
        ThemeMode.values.elementAtOrNull(p.getInt('themeMode') ?? 0) ??
        ThemeMode.system;
    colorSource =
        ColorSource.values.elementAtOrNull(p.getInt('colorSource') ?? 0) ??
        ColorSource.system;
    presetIndex = p.getInt('presetIndex') ?? 0;
    final style = p.getString('paletteStyle');
    paletteStyle = paletteStyles.firstWhere(
      (v) => v.name == style,
      orElse: () => DynamicSchemeVariant.tonalSpot,
    );
    contrast = p.getDouble('contrast') ?? 0;
    themedIcons = p.getBool('themedIcons') ?? false;

    allAppsLayout =
        AllAppsLayout.values.elementAtOrNull(p.getInt('allAppsLayout') ?? 0) ??
        AllAppsLayout.grid;
    showSystemApps = p.getBool('showSystemApps') ?? true;
    fixedCollectionOrder = p.getBool('fixedCollectionOrder') ?? false;
    hiddenApps = (p.getStringList('hiddenApps') ?? const []).toSet();
    favorites = (p.getStringList('favorites') ?? [])
        .take(maxFavorites)
        .toList();
    final overrides = p.getString('categoryOverrides');
    if (overrides != null) {
      final decoded = jsonDecode(overrides) as Map<String, dynamic>;
      categoryOverrides = {
        for (final e in decoded.entries)
          e.key: ?AppCategory.tryParse(e.value as String?),
      };
    }
    pinnedCategories = [
      for (final n in p.getStringList('pinnedCategories') ?? const [])
        ?AppCategory.tryParse(n),
    ];
    hiddenCategories = {
      for (final n in p.getStringList('hiddenCategories') ?? const [])
        ?AppCategory.tryParse(n),
    };
    infoBannerDismissed = p.getBool('infoBannerDismissed') ?? false;
    onboardingDone = p.getBool('onboardingDone') ?? false;
    swipeDown =
        GestureAction.values.elementAtOrNull(p.getInt('swipeDown') ?? 1) ??
        GestureAction.contacts;
    swipeUp =
        GestureAction.values.elementAtOrNull(p.getInt('swipeUp') ?? 0) ??
        GestureAction.search;
    collectionLabels = p.getBool('collectionLabels') ?? false;
    autoLaunchSingle = p.getBool('autoLaunchSingle') ?? true;
    eveningCard = p.getBool('eveningCard') ?? true;
    nextPlaceCard = p.getBool('nextPlaceCard') ?? true;
    travelCard = p.getBool('travelCard') ?? true;
    weatherCard = p.getBool('weatherCard') ?? false;
    placesEnabled = p.getBool('placesEnabled') ?? true;
    workLabel = p.getString('workLabel') ?? 'auto';
    screenTime =
        ScreenTimePlace.values.elementAtOrNull(p.getInt('screenTime') ?? 0) ??
        ScreenTimePlace.off;
    final w = p.getString('widgets');
    if (w != null) {
      widgets = [
        for (final e in jsonDecode(w) as List<dynamic>)
          PlacedWidget.fromJson(e as Map<String, dynamic>),
      ];
    }
    final hw = p.getString('homeWidgets');
    if (hw != null) {
      homeWidgets = [
        for (final e in jsonDecode(hw) as List<dynamic>)
          PlacedWidget.fromJson(e as Map<String, dynamic>),
      ];
    }
    carCard = p.getBool('carCard') ?? true;
    parkingCard = p.getBool('parkingCard') ?? false;
    frostedGlass = p.getBool('frostedGlass') ?? false;
    homeCorners = p.getBool('homeCorners') ?? true;
    learnFromUsage = p.getBool('learnFromUsage') ?? true;
    cardRules = {};
    for (final item in p.getStringList('cardRules') ?? const <String>[]) {
      final parts = item.split('=');
      if (parts.length != 2) continue;
      for (final r in CardRule.values) {
        if (r.name == parts[1]) cardRules[parts[0]] = r;
      }
    }
    dockStyle =
        DockStyle.values.elementAtOrNull(p.getInt('dockStyle') ?? 0) ??
        DockStyle.tray;
    detoxEnabled = p.getBool('detoxEnabled') ?? false;
    detoxAllDay = p.getBool('detoxAllDay') ?? true;
    detoxStart = p.getInt('detoxStart') ?? 22 * 60;
    detoxEnd = p.getInt('detoxEnd') ?? 7 * 60;
    detoxUnlockable = p.getBool('detoxUnlockable') ?? true;
    detoxApps = (p.getStringList('detoxApps') ?? const []).toSet();
    detoxHideApps = p.getBool('detoxHideApps') ?? false;
    contextWallpaper = p.getBool('contextWallpaper') ?? false;
    unsplashKey = p.getString('unsplashKey');
    homeTimeZone = p.getString('homeTimeZone');
    wallpaperShuffle = p.getInt('wallpaperShuffle') ?? 0;
    wallpaperShuffleDay = p.getString('wallpaperShuffleDay');
    wallpaperState = p.getString('wallpaperState');
    agendaCard = p.getBool('agendaCard') ?? true;
    mediaCard = p.getBool('mediaCard') ?? true;
    searchTopApps = p.getInt('searchTopApps') == 4 ? 4 : 8;
    final lang = p.getString('locale');
    locale = lang == null ? null : Locale(lang);
  }

  void _changed({bool collections = false, bool look = false}) {
    if (collections) collectionsRevision++;
    if (look) appearance.value++;
    notifyListeners();
  }

  // region Aspetto
  void setThemeMode(ThemeMode v) {
    themeMode = v;
    _prefs.setInt('themeMode', v.index);
    _changed(look: true);
  }

  void setColorSource(ColorSource v) {
    colorSource = v;
    _prefs.setInt('colorSource', v.index);
    _changed(look: true);
  }

  void setPreset(int index) {
    presetIndex = index;
    colorSource = ColorSource.preset;
    _prefs
      ..setInt('presetIndex', index)
      ..setInt('colorSource', ColorSource.preset.index);
    _changed(look: true);
  }

  void setPaletteStyle(DynamicSchemeVariant v) {
    paletteStyle = v;
    _prefs.setString('paletteStyle', v.name);
    _changed(look: true);
  }

  void setContrast(double v) {
    contrast = v;
    _prefs.setDouble('contrast', v);
    _changed(look: true);
  }

  void setThemedIcons(bool v) {
    themedIcons = v;
    _prefs.setBool('themedIcons', v);
    _changed(look: true);
  }
  // endregion

  // region App
  void setAllAppsLayout(AllAppsLayout v) {
    allAppsLayout = v;
    _prefs.setInt('allAppsLayout', v.index);
    _changed();
  }

  void setShowSystemApps(bool v) {
    showSystemApps = v;
    _prefs.setBool('showSystemApps', v);
    _changed(collections: true);
  }

  void setFixedCollectionOrder(bool v) {
    fixedCollectionOrder = v;
    _prefs.setBool('fixedCollectionOrder', v);
    _changed(collections: true);
  }

  void setHidden(String appId, bool hidden) {
    hidden ? hiddenApps.add(appId) : hiddenApps.remove(appId);
    if (hidden) favorites.remove(appId);
    _prefs
      ..setStringList('hiddenApps', hiddenApps.toList())
      ..setStringList('favorites', favorites);
    _changed(collections: true);
  }

  bool isFavorite(String appId) => favorites.contains(appId);

  bool get favoritesFull => favorites.length >= maxFavorites;

  /// Sposta un'app del dock nel posto [index] (trascinamento).
  void moveFavorite(String appId, int index) {
    final from = favorites.indexOf(appId);
    if (from < 0) return;
    favorites.removeAt(from);
    favorites.insert(index.clamp(0, favorites.length), appId);
    _prefs.setStringList('favorites', favorites);
    _changed();
  }

  void setFavorite(String appId, bool favorite) {
    if (favorite) {
      if (favorites.contains(appId) || favoritesFull) return;
      favorites.add(appId);
    } else {
      favorites.remove(appId);
    }
    _prefs.setStringList('favorites', favorites);
    _changed();
  }

  void setCategoryOverride(String package, AppCategory? category) {
    if (category == null) {
      categoryOverrides.remove(package);
    } else {
      categoryOverrides[package] = category;
    }
    _prefs.setString(
      'categoryOverrides',
      jsonEncode({
        for (final e in categoryOverrides.entries) e.key: e.value.name,
      }),
    );
    _changed(collections: true);
  }

  void setPinned(AppCategory c, bool pinned) {
    pinnedCategories.remove(c);
    if (pinned) pinnedCategories.add(c);
    _prefs.setStringList('pinnedCategories', [
      for (final c in pinnedCategories) c.name,
    ]);
    _changed(collections: true);
  }

  void setCategoryHidden(AppCategory c, bool hidden) {
    hidden ? hiddenCategories.add(c) : hiddenCategories.remove(c);
    if (hidden) pinnedCategories.remove(c);
    _prefs
      ..setStringList('hiddenCategories', [
        for (final c in hiddenCategories) c.name,
      ])
      ..setStringList('pinnedCategories', [
        for (final c in pinnedCategories) c.name,
      ]);
    _changed(collections: true);
  }
  // endregion

  void setSearchTopApps(int n) {
    searchTopApps = n == 4 ? 4 : 8;
    _prefs.setInt('searchTopApps', searchTopApps);
    _changed();
  }

  void setAgendaCard(bool v) {
    agendaCard = v;
    _prefs.setBool('agendaCard', v);
    _changed();
  }

  void setMediaCard(bool v) {
    mediaCard = v;
    _prefs.setBool('mediaCard', v);
    _changed();
  }

  void setContextWallpaper(bool v) {
    contextWallpaper = v;
    _prefs.setBool('contextWallpaper', v);
    _changed();
  }

  void setUnsplashKey(String? key) {
    final k = key?.trim();
    unsplashKey = (k == null || k.isEmpty) ? null : k;
    if (unsplashKey == null) {
      _prefs.remove('unsplashKey');
      contextWallpaper = false;
      _prefs.setBool('contextWallpaper', false);
    } else {
      _prefs.setString('unsplashKey', unsplashKey!);
    }
    _changed();
  }

  void setHomeTimeZone(String tz) {
    homeTimeZone = tz;
    _prefs.setString('homeTimeZone', tz);
  }

  /// Passa alla foto successiva per oggi.
  void nextWallpaper(String today) {
    wallpaperShuffle = wallpaperShuffleDay == today ? wallpaperShuffle + 1 : 1;
    wallpaperShuffleDay = today;
    _prefs
      ..setInt('wallpaperShuffle', wallpaperShuffle)
      ..setString('wallpaperShuffleDay', today);
    _changed();
  }

  /// Scarto della foto per [today] (0 se "Cambia foto" non è stato usato oggi).
  int shuffleFor(String today) =>
      wallpaperShuffleDay == today ? wallpaperShuffle : 0;

  void saveWallpaperState(String? json) {
    wallpaperState = json;
    if (json == null) {
      _prefs.remove('wallpaperState');
    } else {
      _prefs.setString('wallpaperState', json);
    }
  }

  void setSwipeDown(GestureAction v) {
    swipeDown = v;
    _prefs.setInt('swipeDown', v.index);
    _changed();
  }

  void setSwipeUp(GestureAction v) {
    swipeUp = v;
    _prefs.setInt('swipeUp', v.index);
    _changed();
  }

  void setAutoLaunchSingle(bool v) {
    autoLaunchSingle = v;
    _prefs.setBool('autoLaunchSingle', v);
    _changed();
  }

  void setCollectionLabels(bool v) {
    collectionLabels = v;
    _prefs.setBool('collectionLabels', v);
    _changed();
  }

  void setEveningCard(bool v) {
    eveningCard = v;
    _prefs.setBool('eveningCard', v);
    _changed();
  }

  void setNextPlaceCard(bool v) {
    nextPlaceCard = v;
    _prefs.setBool('nextPlaceCard', v);
    _changed();
  }

  /// Widget della Home (sopra il dock) o dello Space.
  List<PlacedWidget> widgetsFor({required bool home}) =>
      home ? homeWidgets : widgets;

  void _saveWidgets() {
    _prefs
      ..setString('widgets', jsonEncode([for (final w in widgets) w.toJson()]))
      ..setString(
        'homeWidgets',
        jsonEncode([for (final w in homeWidgets) w.toJson()]),
      );
    _changed();
  }

  void _update(bool home, List<PlacedWidget> list) {
    if (home) {
      homeWidgets = list;
    } else {
      widgets = list;
    }
    _saveWidgets();
  }

  void addWidget(PlacedWidget w, {bool home = false}) =>
      _update(home, [...widgetsFor(home: home), w]);

  void removeWidget(int id, {bool home = false}) => _update(home, [
    for (final w in widgetsFor(home: home))
      if (w.id != id) w,
  ]);

  void resizeWidget(int id, double height, {bool home = false}) =>
      _update(home, [
        for (final w in widgetsFor(home: home))
          w.id == id ? w.withHeight(height) : w,
      ]);

  void moveWidget(int id, int delta, {bool home = false}) {
    final list = [...widgetsFor(home: home)];
    final i = list.indexWhere((w) => w.id == id);
    final j = i + delta;
    if (i < 0 || j < 0 || j >= list.length) return;
    list.insert(j, list.removeAt(i));
    _update(home, list);
  }

  void setScreenTime(ScreenTimePlace v) {
    screenTime = v;
    _prefs.setInt('screenTime', v.index);
    _changed();
  }

  void setPlacesEnabled(bool v) {
    placesEnabled = v;
    _prefs.setBool('placesEnabled', v);
    _changed();
  }

  void setWorkLabel(String v) {
    workLabel = v;
    _prefs.setString('workLabel', v);
    _changed();
  }

  void setWeatherCard(bool v) {
    weatherCard = v;
    _prefs.setBool('weatherCard', v);
    _changed();
  }

  /// Mostra sempre o nasconde una card in uno Space (null = come deciso
  /// dal profilo e dall'uso).
  void setCardRule(SpaceKind kind, SpaceCard card, CardRule? rule) {
    final key = '${kind.name}/${card.name}';
    rule == null ? cardRules.remove(key) : cardRules[key] = rule;
    _prefs.setStringList('cardRules', [
      for (final e in cardRules.entries) '${e.key}=${e.value.name}',
    ]);
    _changed();
  }

  void setLearnFromUsage(bool v) {
    learnFromUsage = v;
    _prefs.setBool('learnFromUsage', v);
    _changed();
  }

  void setHomeCorners(bool v) {
    homeCorners = v;
    _prefs.setBool('homeCorners', v);
    _changed();
  }

  void setDockStyle(DockStyle v) {
    dockStyle = v;
    _prefs.setInt('dockStyle', v.index);
    _changed();
  }

  void setFrostedGlass(bool v) {
    frostedGlass = v;
    _prefs.setBool('frostedGlass', v);
    _changed(look: true);
  }

  // region Digital detox
  void setDetoxEnabled(bool v) {
    detoxEnabled = v;
    _prefs.setBool('detoxEnabled', v);
    _changed(collections: true);
  }

  void setDetoxSchedule({bool? allDay, int? start, int? end}) {
    if (allDay != null) {
      detoxAllDay = allDay;
      _prefs.setBool('detoxAllDay', allDay);
    }
    if (start != null) {
      detoxStart = start;
      _prefs.setInt('detoxStart', start);
    }
    if (end != null) {
      detoxEnd = end;
      _prefs.setInt('detoxEnd', end);
    }
    _changed(collections: true);
  }

  void setDetoxUnlockable(bool v) {
    detoxUnlockable = v;
    _prefs.setBool('detoxUnlockable', v);
    _changed();
  }

  /// Blocca o sblocca più app insieme (un gruppo intero).
  void setDetoxApps(Iterable<String> packages, bool locked) {
    locked ? detoxApps.addAll(packages) : detoxApps.removeAll(packages);
    _prefs.setStringList('detoxApps', detoxApps.toList());
    _changed(collections: true);
  }

  void setDetoxHideApps(bool v) {
    detoxHideApps = v;
    _prefs.setBool('detoxHideApps', v);
    _changed(collections: true);
  }
  // endregion

  void setParkingCard(bool v) {
    parkingCard = v;
    _prefs.setBool('parkingCard', v);
    _changed();
  }

  void setCarCard(bool v) {
    carCard = v;
    _prefs.setBool('carCard', v);
    _changed();
  }

  void setTravelCard(bool v) {
    travelCard = v;
    _prefs.setBool('travelCard', v);
    _changed();
  }

  void setOnboardingDone(bool v) {
    onboardingDone = v;
    _prefs.setBool('onboardingDone', v);
    _changed();
  }

  void dismissInfoBanner() {
    infoBannerDismissed = true;
    _prefs.setBool('infoBannerDismissed', true);
    _changed();
  }

  void setLocale(Locale? v) {
    locale = v;
    if (v == null) {
      _prefs.remove('locale');
    } else {
      _prefs.setString('locale', v.languageCode);
    }
    _changed(look: true);
  }
}
