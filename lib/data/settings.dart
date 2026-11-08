/// User settings, stored in shared_preferences
/// (spec-viste-app §6–§8).
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/categories.dart';
import '../core/detox.dart';
import '../core/space.dart';
import '../core/space_profile.dart';
import '../core/wallpaper_moment.dart';
import '../platform/launcher_bridge.dart';

enum ColorSource { system, preset }

enum AllAppsLayout { grid, list }

/// Where to show screen time.
enum ScreenTimePlace { off, home, space }

/// Action of a vertical swipe on the Home.
enum GestureAction { search, contacts, none }

/// Home dock style: solid tray (default) or icons on the wallpaper.
enum DockStyle { tray, transparent }

/// What the Home tab in the top bar shows: today's short date (default) or
/// the local weather (only with the Weather card on).
enum HomeTabLabel { date, weather }

/// Palette styles offered to the user (a subset of
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

  // --- Appearance ---
  ThemeMode themeMode = ThemeMode.system;
  ColorSource colorSource = ColorSource.system;
  int presetIndex = 0;
  DynamicSchemeVariant paletteStyle = DynamicSchemeVariant.tonalSpot;
  double contrast = 0;
  bool themedIcons = false;

  // --- Apps ---
  AllAppsLayout allAppsLayout = AllAppsLayout.grid;
  bool showSystemApps = true;
  bool fixedCollectionOrder = false;
  Set<String> hiddenApps = {};
  List<String> favorites = [];
  Map<String, AppCategory> categoryOverrides = {};
  List<AppCategory> pinnedCategories = [];
  Set<AppCategory> hiddenCategories = {};

  /// Unsplash wallpapers. The key is the user's own and stays on the phone.
  /// Daily: a new photo on Home every day. Contextual: a photo that follows
  /// the moment, in the Space header only.
  bool dailyWallpaper = false;
  bool contextWallpaper = false;
  WallpaperStyle wallpaperStyle = WallpaperStyle.none;

  /// Slight blur of the photo behind the Space date card, for legibility.
  bool spaceHeaderBlur = true;
  String? unsplashKey;

  /// Home time zone (e.g. "Europe/Rome"): if the current one differs, the
  /// user is considered to be travelling.
  String? homeTimeZone;

  /// "Change photo" (contextual): offset from the photo of the day.
  int wallpaperShuffle = 0;
  String? wallpaperShuffleDay;

  /// "Change today's photo" (daily): how many times it was used today.
  int dailyShuffle = 0;
  String? dailyShuffleDay;

  /// Photos in use (JSON), so they aren't downloaded again on every start.
  String? wallpaperState;
  String? dailyWallpaperState;

  /// Home gestures: by default contacts on swipe down, search on swipe up.
  GestureAction swipeDown = GestureAction.contacts;
  GestureAction swipeUp = GestureAction.search;

  /// Search: when only one app matches, launch it automatically.
  bool autoLaunchSingle = true;

  /// Labels under the icons in the Collections rows (off by default).
  bool collectionLabels = false;

  /// Other Space cards.
  bool eveningCard = true;
  bool nextPlaceCard = true;
  bool travelCard = true;
  bool weatherCard = false;

  /// Exercise Space from the step counter (needs the "Physical activity"
  /// permission).
  bool exerciseSpace = false;

  /// Home and work recognition (requires precise location).
  bool placesEnabled = true;

  /// Label of the work place: auto ("Work/School"), work, school.
  String workLabel = 'auto';
  ScreenTimePlace screenTime = ScreenTimePlace.off;

  /// Android widgets in the Space, in order.
  List<PlacedWidget> widgets = [];

  /// Android widgets on the Home, above the dock (at most [maxHomeWidgets]).
  List<PlacedWidget> homeWidgets = [];
  static const maxHomeWidgets = 3;

  /// Height of a Home grid row, in dp.
  static const homeRowHeight = 88.0;

  /// Height range of a Home widget, in rows.
  static const minHomeRows = 1;
  static const maxHomeRows = 4;
  bool carCard = true;

  /// "Where I parked" (off by default: it uses background location).
  bool parkingCard = false;

  /// Onboarding completed.
  bool onboardingDone = false;

  /// Frosted glass: translucent pages over the blurred wallpaper (off by
  /// default).
  bool frostedGlass = false;

  /// Home dock: solid tray framing the wallpaper, or transparent.
  DockStyle dockStyle = DockStyle.tray;
  HomeTabLabel homeTabLabel = HomeTabLabel.date;

  /// Slightly rounded window corners over the Home wallpaper.
  /// Keep the launcher in portrait instead of following the phone's
  /// rotation (on by default).
  bool lockPortrait = true;

  bool homeCorners = true;

  /// Also learn from apps opened outside libreGLIDE (Android usage history,
  /// if access is granted).
  bool learnFromUsage = true;

  /// Choices for the Space cards: "space/card" → show or hide.
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

  /// Digital detox (off by default). The PIN isn't stored here: the native
  /// side keeps it, only as a hash.
  bool detoxEnabled = false;
  bool detoxAllDay = true;
  int detoxStart = 22 * 60;
  int detoxEnd = 7 * 60;

  /// Blocked apps can be unlocked with the PIN (otherwise never).
  bool detoxUnlockable = true;

  /// Blocked packages. Kept separate from hidden apps: turning detox off
  /// restores everything as it was.
  Set<String> detoxApps = {};

  /// During detox, blocked apps disappear from the launcher.
  bool detoxHideApps = false;

  DetoxSchedule get detoxSchedule =>
      DetoxSchedule(allDay: detoxAllDay, start: detoxStart, end: detoxEnd);

  /// Dynamic Space cards.
  bool agendaCard = true;
  bool mediaCard = true;

  /// Suggested apps above the global search bar: 4 or 8.
  int searchTopApps = 8;

  /// The Space info banner has been dismissed.
  bool infoBannerDismissed = false;

  /// Language: null = system language.
  Locale? locale;

  /// Notifier dedicated to appearance (theme, colors, contrast, language,
  /// themed icons): only this one rebuilds the MaterialApp.
  final ValueNotifier<int> appearance = ValueNotifier(0);

  /// Incremented on every change that affects the Collections.
  int collectionsRevision = 0;

  /// Dock slots: a single row of 4 (always 4 slots).
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
    exerciseSpace = p.getBool('exerciseSpace') ?? false;
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
    lockPortrait = p.getBool('lockPortrait') ?? true;
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
    homeTabLabel =
        HomeTabLabel.values.elementAtOrNull(p.getInt('homeTabLabel') ?? 0) ??
        HomeTabLabel.date;
    detoxEnabled = p.getBool('detoxEnabled') ?? false;
    detoxAllDay = p.getBool('detoxAllDay') ?? true;
    detoxStart = p.getInt('detoxStart') ?? 22 * 60;
    detoxEnd = p.getInt('detoxEnd') ?? 7 * 60;
    detoxUnlockable = p.getBool('detoxUnlockable') ?? true;
    detoxApps = (p.getStringList('detoxApps') ?? const []).toSet();
    detoxHideApps = p.getBool('detoxHideApps') ?? false;
    contextWallpaper = p.getBool('contextWallpaper') ?? false;
    // Before 1.2 the contextual photo was also the Home wallpaper: keep Home
    // as it was for whoever had it on.
    dailyWallpaper = p.getBool('dailyWallpaper') ?? contextWallpaper;
    wallpaperStyle = WallpaperStyle.byName(p.getString('wallpaperStyle'));
    spaceHeaderBlur = p.getBool('spaceHeaderBlur') ?? true;
    unsplashKey = p.getString('unsplashKey');
    homeTimeZone = p.getString('homeTimeZone');
    wallpaperShuffle = p.getInt('wallpaperShuffle') ?? 0;
    wallpaperShuffleDay = p.getString('wallpaperShuffleDay');
    wallpaperState = p.getString('wallpaperState');
    dailyWallpaperState = p.getString('dailyWallpaperState');
    dailyShuffle = p.getInt('dailyShuffle') ?? 0;
    dailyShuffleDay = p.getString('dailyShuffleDay');
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

  // region Appearance
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

  // region Apps
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

  /// Moves a dock app to slot [index] (drag and drop).
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

  void setDailyWallpaper(bool v) {
    dailyWallpaper = v;
    _prefs.setBool('dailyWallpaper', v);
    _changed();
  }

  void setSpaceHeaderBlur(bool v) {
    spaceHeaderBlur = v;
    _prefs.setBool('spaceHeaderBlur', v);
    _changed();
  }

  void setWallpaperStyle(WallpaperStyle v) {
    wallpaperStyle = v;
    _prefs.setString('wallpaperStyle', v.name);
    _changed();
  }

  void setUnsplashKey(String? key) {
    final k = key?.trim();
    unsplashKey = (k == null || k.isEmpty) ? null : k;
    if (unsplashKey == null) {
      _prefs.remove('unsplashKey');
      contextWallpaper = false;
      dailyWallpaper = false;
      _prefs
        ..setBool('contextWallpaper', false)
        ..setBool('dailyWallpaper', false);
    } else {
      _prefs.setString('unsplashKey', unsplashKey!);
    }
    _changed();
  }

  void setHomeTimeZone(String tz) {
    homeTimeZone = tz;
    _prefs.setString('homeTimeZone', tz);
  }

  /// Switches to the next photo for today.
  void nextWallpaper(String today) {
    wallpaperShuffle = wallpaperShuffleDay == today ? wallpaperShuffle + 1 : 1;
    wallpaperShuffleDay = today;
    _prefs
      ..setInt('wallpaperShuffle', wallpaperShuffle)
      ..setString('wallpaperShuffleDay', today);
    _changed();
  }

  /// Photo offset for [today] (0 if "Change photo" wasn't used today).
  int shuffleFor(String today) =>
      wallpaperShuffleDay == today ? wallpaperShuffle : 0;

  /// Switches to another daily photo for [today].
  void nextDailyWallpaper(String today) {
    dailyShuffle = dailyShuffleDay == today ? dailyShuffle + 1 : 1;
    dailyShuffleDay = today;
    _prefs
      ..setInt('dailyShuffle', dailyShuffle)
      ..setString('dailyShuffleDay', today);
    _changed();
  }

  /// Daily photo changes for [today] (0 if not used today).
  int dailyShuffleFor(String today) =>
      dailyShuffleDay == today ? dailyShuffle : 0;

  void saveWallpaperState(String? json) {
    wallpaperState = json;
    _saveOrRemove('wallpaperState', json);
  }

  void saveDailyWallpaperState(String? json) {
    dailyWallpaperState = json;
    _saveOrRemove('dailyWallpaperState', json);
  }

  void _saveOrRemove(String key, String? value) {
    if (value == null) {
      _prefs.remove(key);
    } else {
      _prefs.setString(key, value);
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

  /// Widgets of the Home (above the dock) or of the Space.
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

  void setExerciseSpace(bool v) {
    exerciseSpace = v;
    _prefs.setBool('exerciseSpace', v);
    _changed();
  }

  /// Always shows or hides a card in a Space (null = as decided by the
  /// profile and usage).
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

  void setLockPortrait(bool v) {
    lockPortrait = v;
    _prefs.setBool('lockPortrait', v);
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

  void setHomeTabLabel(HomeTabLabel v) {
    homeTabLabel = v;
    _prefs.setInt('homeTabLabel', v.index);
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

  /// Blocks or unblocks several apps at once (a whole group).
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
