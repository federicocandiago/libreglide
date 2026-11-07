/// Central launcher state: installed apps, categories, icons, current
/// context, predictions and Collections.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/app_entry.dart';
import '../core/boost.dart';
import '../core/categories.dart';
import '../core/collections.dart';
import '../core/places.dart';
import '../core/predictor.dart';
import '../core/space.dart';
import '../core/space_profile.dart';
import '../core/time_context.dart';
import '../data/launch_store.dart';
import '../data/settings.dart';
import '../platform/launcher_bridge.dart';
import 'cards_controller.dart';
import 'contacts_controller.dart';
import 'places_controller.dart';
import 'weather_controller.dart';

/// Icon cache, kept separate from the controller so that only the icons
/// repaint when they arrive.
class IconCache extends ChangeNotifier {
  IconCache(this._bridge);

  final LauncherBridge _bridge;
  final Map<String, AppIcon> _icons = {};
  final Set<String> _pending = {};
  int sizePx = 168;

  AppIcon? operator [](String id) => _icons[id];

  /// Loads missing icons in chunks, without blocking the UI.
  Future<void> ensure(Iterable<String> ids) async {
    final missing = ids
        .where((id) => !_icons.containsKey(id) && !_pending.contains(id))
        .toList();
    if (missing.isEmpty) return;
    _pending.addAll(missing);
    const chunk = 24;
    for (var i = 0; i < missing.length; i += chunk) {
      final part = missing.sublist(
        i,
        i + chunk > missing.length ? missing.length : i + chunk,
      );
      try {
        _icons.addAll(await _bridge.getIcons(part, sizePx));
      } catch (e) {
        debugPrint('libreglide: icons not loaded: $e');
      } finally {
        _pending.removeAll(part);
      }
      notifyListeners();
    }
  }

  /// Forgets a package's icons (after an update).
  void evictPackage(String package) {
    _icons.removeWhere((id, _) => id.startsWith('$package/'));
  }
}

class LauncherController extends ChangeNotifier {
  LauncherController({
    required this.bridge,
    required this.store,
    required this.settings,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now,
       icons = IconCache(bridge),
       cards = CardsController(bridge, clock: clock),
       contacts = ContactsController(bridge, store, clock: clock),
       weather = WeatherController(bridge, settings, clock: clock),
       places = PlacesController(bridge, store, settings, clock: clock);

  final LauncherBridge bridge;
  final LaunchStore store;
  final SettingsController settings;
  final IconCache icons;

  /// The Space's dynamic cards (Agenda, Now playing).
  final CardsController cards;

  /// Contacts panel (swipe up).
  final ContactsController contacts;

  /// Weather card (optional).
  final WeatherController weather;

  /// Places: home, work, frequent (optional, precise location).
  final PlacesController places;
  final DateTime Function() _clock;

  final AppPredictor predictor = AppPredictor();
  final CollectionsBuilder _collections = CollectionsBuilder();

  List<AppEntry> _all = const [];
  Map<String, CategoryAssignment> _categories = const {};
  late ContextFeatures context = ContextFeatures.at(_clock());
  bool loaded = false;
  int _appsRevision = 0;
  int _lastSettingsRevision = -1;

  final List<StreamSubscription<Object?>> _subs = [];
  Timer? _contextTimer;
  Timer? _refreshDebounce;

  Future<void> init() async {
    predictor.addAll(await store.loadAndPrune(now: _clock()));
    await _loadCardEvents();
    _boosts = await store.loadBoosts();
    await places.load();
    places.addListener(updateContext);
    await refreshContext();
    cards.screenTimeWanted = settings.screenTime != ScreenTimePlace.off;
    cards.parkingWanted = settings.parkingCard;
    unawaited(bridge.setParkingEnabled(settings.parkingCard));
    cards.start();
    weather.start();
    await refreshApps();
    _subs
      ..add(bridge.packagesChanged.listen(_onPackagesChanged))
      ..add(
        bridge.resumed.listen((_) {
          _updateDetox();
          refreshContext();
          importUsage();
        }),
      );
    _contextTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => refreshContext(),
    );
    settings.addListener(_onSettingsChanged);
    _lastSettingsRevision = settings.collectionsRevision;
    _updateDetox();
    _learnFromUsage = settings.learnFromUsage;
    unawaited(importUsage(force: true));
  }

  // --- Space cards ---

  final CardAffinity cardAffinity = CardAffinity();
  String? _cardKey;
  Map<SpaceCard, double> _cardScores = const {};

  /// A tap on a card: records it along with the current context.
  void recordCardUse(SpaceCard card) {
    final now = _clock();
    final features = _contextNow().toMap();
    cardAffinity.add(card, now, features);
    unawaited(
      store.insert(
        LaunchRecord(ts: now, package: card.name, features: features),
        source: 'card',
      ),
    );
  }

  /// Card affinity in the current context. Recomputed only when the context
  /// (or the Space) changes, so tapping a card doesn't move the others while
  /// the user is looking at the page.
  Map<SpaceCard, double> cardScores(SpaceKind kind) {
    final key = '${context.key}|${kind.name}';
    if (key == _cardKey) return _cardScores;
    _cardKey = key;
    final now = _clock();
    final ctx = context.toMap();
    return _cardScores = {
      for (final c in SpaceCard.values)
        if (cardAffinity.affinity(c, now, ctx) case final a when a > 0) c: a,
    };
  }

  Future<void> _loadCardEvents() async {
    try {
      for (final r in await store.loadCardEvents()) {
        final card = SpaceCard.values
            .where((c) => c.name == r.package)
            .firstOrNull;
        if (card != null) cardAffinity.add(card, r.ts, r.features);
      }
    } catch (e) {
      debugPrint('libreglide: card taps unavailable: $e');
    }
  }

  // --- Android usage history ---

  static const _usageMarker = 'usageImportedUntil';
  bool _importing = false;
  bool _learnFromUsage = true;
  DateTime? _lastImport;

  /// Access to usage data (null = not checked yet).
  bool? usageAccess;

  /// Feeds the predictor with apps opened outside libreGLIDE (notifications,
  /// recents, links…), read from Android's usage history: the last 2 weeks
  /// the first time, then only new ones. Launches made from libreGLIDE are
  /// not counted twice. For these only time and day are known: network,
  /// place and audio stay unknown.
  Future<void> importUsage({bool force = false}) async {
    if (_importing || !settings.learnFromUsage) return;
    final now = _clock();
    if (!force &&
        _lastImport != null &&
        now.difference(_lastImport!) < const Duration(minutes: 2)) {
      return;
    }
    _importing = true;
    try {
      usageAccess = await bridge.hasUsageAccess();
      if (!usageAccess!) return;
      final stored = int.tryParse(await store.readKv(_usageMarker) ?? '');
      final since = stored != null
          ? DateTime.fromMillisecondsSinceEpoch(stored)
          : now.subtract(const Duration(days: 14));
      final openings = await bridge.usageOpenings(since);
      final own = await store.launcherTimes(
        since.subtract(const Duration(minutes: 1)),
      );
      final records = <LaunchRecord>[];
      var until = since;
      for (final (package, ts) in openings) {
        if (!ts.isAfter(since)) continue;
        if (ts.isAfter(until)) until = ts;
        final t = ts.millisecondsSinceEpoch;
        final mine = own[package];
        if (mine != null && mine.any((m) => t - m > -3000 && t - m < 15000)) {
          continue;
        }
        final f = ContextFeatures.at(ts);
        records.add(
          LaunchRecord(
            ts: ts,
            package: package,
            features: {'slot': f.slot.name, 'daytype': f.dayType.name},
          ),
        );
      }
      _lastImport = now;
      if (records.isNotEmpty) {
        predictor.addAll(records);
        await store.insertAll(records, 'usage');
        notifyListeners();
      }
      await store.writeKv(_usageMarker, '${until.millisecondsSinceEpoch}');
    } catch (e) {
      debugPrint('libreglide: usage history unavailable: $e');
    } finally {
      _importing = false;
    }
  }

  /// Forgets the launches imported from Android's usage history.
  Future<void> forgetUsage() async {
    await store.deleteSource('usage');
    await store.deleteKv(_usageMarker);
    predictor
      ..clear()
      ..addAll(await store.loadAndPrune(now: _clock()));
    _lastImport = null;
    notifyListeners();
  }

  /// Stored launches by source (`launcher`, `usage`).
  Future<Map<String, int>> launchSources() => store.countBySource();

  // --- Digital detox ---

  /// Blocked apps are currently hidden (detox on, option enabled and within
  /// the schedule).
  bool detoxHiding = false;
  Timer? _detoxTimer;
  String? _detoxSyncKey;

  /// Syncs the native side (which does the actual blocking) and decides
  /// whether to hide blocked apps; reschedules itself for the next schedule
  /// change.
  void _updateDetox() {
    final apps = settings.detoxApps.toList()..sort();
    final key = [
      settings.detoxEnabled,
      settings.detoxAllDay,
      settings.detoxStart,
      settings.detoxEnd,
      settings.detoxUnlockable,
      ...apps,
    ].join('|');
    if (key != _detoxSyncKey) {
      _detoxSyncKey = key;
      unawaited(
        bridge.detoxSync({
          'enabled': settings.detoxEnabled,
          'allDay': settings.detoxAllDay,
          'start': settings.detoxStart,
          'end': settings.detoxEnd,
          'unlockable': settings.detoxUnlockable,
          'packages': apps,
        }),
      );
    }
    final now = _clock();
    final wanted = settings.detoxEnabled && settings.detoxHideApps;
    final hiding = wanted && settings.detoxSchedule.isActiveAt(now);
    _detoxTimer?.cancel();
    final next = wanted ? settings.detoxSchedule.nextChange(now) : null;
    if (next != null) {
      _detoxTimer = Timer(
        next.difference(now) + const Duration(seconds: 1),
        _updateDetox,
      );
    }
    if (hiding != detoxHiding) {
      detoxHiding = hiding;
      appsVersion.value++;
      notifyListeners();
    }
  }

  bool _detoxHidden(AppEntry a) =>
      detoxHiding && settings.detoxApps.contains(a.packageName);

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _contextTimer?.cancel();
    _refreshDebounce?.cancel();
    _detoxTimer?.cancel();
    cards.dispose();
    weather.dispose();
    places.removeListener(updateContext);
    places.dispose();
    settings.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    _updateDetox();
    if (settings.learnFromUsage != _learnFromUsage) {
      _learnFromUsage = settings.learnFromUsage;
      unawaited(_learnFromUsage ? importUsage(force: true) : forgetUsage());
    }
    if (settings.parkingCard != cards.parkingWanted) {
      cards.parkingWanted = settings.parkingCard;
      bridge.setParkingEnabled(settings.parkingCard);
      cards.refreshParking();
    }
    final wanted = settings.screenTime != ScreenTimePlace.off;
    if (wanted != cards.screenTimeWanted) {
      cards.screenTimeWanted = wanted;
      cards.refreshScreenTime();
    }
    if (settings.collectionsRevision != _lastSettingsRevision) {
      _lastSettingsRevision = settings.collectionsRevision;
      _categories = _categorizeAll(_all);
      appsVersion.value++;
      notifyListeners();
    }
  }

  void _onPackagesChanged(String? package) {
    if (package != null) icons.evictPackage(package);
    _refreshDebounce?.cancel();
    _refreshDebounce = Timer(
      const Duration(milliseconds: 400),
      () => refreshApps(),
    );
  }

  Future<void> refreshApps() async {
    try {
      final apps = await bridge.getApps();
      apps.sort((a, b) => a.sortKey.compareTo(b.sortKey));
      _all = apps;
      _byId = {for (final a in apps) a.id: a};
      _byPackage = {};
      for (final a in apps) {
        _byPackage.putIfAbsent(a.packageName, () => a);
      }
      _categories = _categorizeAll(apps);
      _appsRevision++;
      appsVersion.value++;
    } catch (e) {
      debugPrint('libreglide: app list unavailable: $e');
    }
    loaded = true;
    notifyListeners();
    unawaited(icons.ensure(_all.map((a) => a.id)));
  }

  Map<String, CategoryAssignment> _categorizeAll(List<AppEntry> apps) => {
    for (final a in apps)
      a.id: categorize(
        packageName: a.packageName,
        label: a.label,
        isSystem: a.isSystem,
        manifestCategory: a.manifestCategory,
        userOverride: settings.categoryOverrides[a.packageName],
      ),
  };

  /// Latest signals read from the system (network, headphones, charging).
  Map<String, Object?> _snapshot = const {};

  ContextFeatures _contextNow() => ContextFeatures.at(
    _clock(),
    network: _snapshot['network'] as String?,
    audio: _snapshot['audio'] as String?,
    motion: _snapshot['car'] == true ? 'driving' : null,
    place: _placeFeature(),
  );

  /// Place for the predictor: `home`, `work`, `frequent:ID`, `other`, `travel`.
  String? _placeFeature() {
    if (travelling) return 'travel';
    final p = places.current;
    if (p == null) return null;
    return switch (p.effectiveRole) {
      PlaceRole.home => 'home',
      PlaceRole.work => 'work',
      PlaceRole.frequent => 'frequent:${p.id}',
      PlaceRole.none => 'other',
    };
  }

  /// Driving: Android Auto or a Bluetooth car stereo (with the permission).
  bool get driving => _snapshot['car'] == true;

  /// Battery level (0–100), if known.
  int? get batteryLevel => (_snapshot['battery'] as num?)?.toInt();
  bool get charging => _snapshot['charging'] == true;

  /// Do Not Disturb is on.
  bool get doNotDisturb => _snapshot['dnd'] == true;

  /// Current time zone (e.g. "Europe/Rome").
  String? get timeZone => _snapshot['tz'] as String?;

  /// UTC offset of the home time zone, read while travelling.
  Duration? homeOffset;

  /// Home time, when in a different time zone.
  DateTime? get homeTime {
    final offset = homeOffset;
    if (offset == null) return null;
    final t = _clock().toUtc().add(offset);
    // Home wall-clock time, to be shown as is.
    return DateTime(t.year, t.month, t.day, t.hour, t.minute);
  }

  /// "I live here now": the current time zone becomes the home one.
  void setHomeHere() {
    final tz = timeZone;
    if (tz == null) return;
    settings.setHomeTimeZone(tz);
    homeOffset = null;
    notifyListeners();
  }

  /// Travelling: roaming, far from home, or a time zone different from the
  /// home one (the first one seen). In the future also the city, via places
  /// (M1).
  bool get travelling {
    if (_snapshot['roaming'] == true) return true;
    if (places.farFromHome) return true;
    final tz = _snapshot['tz'] as String?;
    final home = settings.homeTimeZone;
    return tz != null && home != null && tz != home;
  }

  /// Re-reads the system signals and updates the context.
  Future<void> refreshContext() async {
    final before = _signature();
    try {
      _snapshot = await bridge.contextSnapshot();
      final tz = _snapshot['tz'] as String?;
      if (tz != null && settings.homeTimeZone == null) {
        settings.setHomeTimeZone(tz);
      }
      final home = settings.homeTimeZone;
      homeOffset = (home != null && tz != null && tz != home)
          ? await bridge.timeZoneOffset(home)
          : null;
    } catch (e) {
      debugPrint('libreglide: context signals unavailable: $e');
    }
    unawaited(places.sample());
    final contextBefore = context.key;
    updateContext();
    // Battery, Do Not Disturb, time zone and roaming don't change the
    // context, but the Space cards need them.
    if (context.key == contextBefore && _signature() != before) {
      notifyListeners();
    }
  }

  String _signature() {
    final level = (_snapshot['battery'] as num?)?.toInt();
    return [
      level == null ? '-' : '${level ~/ 10}',
      _snapshot['charging'],
      _snapshot['dnd'],
      _snapshot['tz'],
      _snapshot['roaming'],
      homeOffset?.inMinutes,
    ].join('|');
  }

  /// Recomputes the context; if it changed, Collections may reorder and the
  /// manual Space choice is dropped.
  void updateContext() {
    final next = _contextNow();
    if (next.key != context.key) {
      context = next;
      spaceOverride = null;
      notifyListeners();
    }
  }

  List<CategoryBoost> _boosts = const [];
  bool _forceCollections = false;

  /// Initial boosts active right now, per category.
  Map<AppCategory, double> get boosts => activeBoosts(_boosts, _clock());

  /// Favorite collections picked during onboarding: they start at the top
  /// and stay there for the first weeks, then give way to actual usage.
  Future<void> setFavoriteCategories(List<AppCategory> categories) async {
    final now = _clock();
    // Earlier picks weigh slightly more, to preserve the chosen order.
    _boosts = [
      for (final (i, c) in categories.indexed)
        CategoryBoost(
          category: c,
          created: now,
          weight: initialBoost - i * 0.1,
        ),
    ];
    await store.replaceBoosts(_boosts);
    _forceCollections = true;
    notifyListeners();
  }

  /// Initially suggested dock: phone, messages, camera, browser (the first
  /// installed among the known packages).
  List<AppEntry> suggestedDock() {
    const groups = [
      [
        'com.google.android.dialer',
        'com.samsung.android.dialer',
        'com.android.dialer',
      ],
      [
        'com.google.android.apps.messaging',
        'com.samsung.android.messaging',
        'com.android.messaging',
        'org.thoughtcrime.securesms',
        'com.whatsapp',
      ],
      [
        'com.google.android.GoogleCamera',
        'com.sec.android.app.camera',
        'com.android.camera2',
        'com.android.camera',
      ],
      [
        'com.android.chrome',
        'org.mozilla.firefox',
        'org.mozilla.fenix',
        'com.brave.browser',
        'com.duckduckgo.mobile.android',
        'com.sec.android.app.sbrowser',
        'com.microsoft.emmx',
      ],
    ];
    return [
      for (final g in groups)
        ?g.map(byPackage).firstWhere((a) => a != null, orElse: () => null),
    ];
  }

  /// Chosen favorite categories (even if their boost has expired).
  List<AppCategory> get favoriteCategories => [
    for (final b in _boosts) b.category,
  ];

  /// Fills [packages] up to [n] with apps from the boosted collections, for
  /// the first days when predictions are scarce.
  List<String> _fillFromBoosted(
    List<String> packages,
    int n,
    Set<String> candidates,
  ) {
    if (packages.length >= n) return [...packages];
    final out = [...packages];
    final active = boosts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final habit = predictor.habit(now: _clock());
    for (final entry in active) {
      final apps =
          [
            for (final a in visibleApps)
              if (categoryOf(a) == entry.key &&
                  candidates.contains(a.packageName) &&
                  !out.contains(a.packageName))
                a,
          ]..sort((a, b) {
            final h = (habit[b.packageName] ?? 0).compareTo(
              habit[a.packageName] ?? 0,
            );
            return h != 0 ? h : a.sortKey.compareTo(b.sortKey);
          });
      for (final a in apps) {
        if (out.length >= n) return out;
        out.add(a.packageName);
      }
    }
    return out;
  }

  /// Space picked manually from the drawer; null = the context one.
  SpaceKind? spaceOverride;

  /// Context Space: car, headphones, travel, work, home, time of day.
  SpaceKind get contextSpace => selectSpace(
    slot: context.slot,
    place: places.currentRole,
    driving: driving,
    audio: context.audio,
    travelling: travelling,
  );

  /// Displayed Space: the manually picked one or the context one.
  SpaceKind get currentSpace => spaceOverride ?? contextSpace;

  /// Time slot to use for time-bound cards (Good night…).
  Slot get currentSlot => spaceOverride?.slot ?? context.slot;

  void chooseSpace(SpaceKind? kind) {
    spaceOverride = kind == contextSpace ? null : kind;
    notifyListeners();
  }

  // --- Queries ---

  List<AppEntry> get allApps => _all;

  /// Displayed apps: without hidden ones and, if requested, without system
  /// apps. Cached until the apps or app settings change.
  List<AppEntry> get visibleApps {
    final key =
        (_appsRevision * 100000 + settings.collectionsRevision) * 2 +
        (detoxHiding ? 1 : 0);
    if (key != _visibleKey) {
      _visibleKey = key;
      _visible = List.unmodifiable([
        for (final a in _all)
          if (!settings.hiddenApps.contains(a.id) &&
              (settings.showSystemApps || !a.isSystem) &&
              !_detoxHidden(a))
            a,
      ]);
      _visibleCategories = {for (final a in _visible) a.id: categoryOf(a)};
      _visibleByPackage = {};
      for (final a in _visible) {
        _visibleByPackage.putIfAbsent(a.packageName, () => a);
      }
    }
    return _visible;
  }

  int _visibleKey = -1;
  List<AppEntry> _visible = const [];
  Map<String, AppCategory> _visibleCategories = const {};
  Map<String, AppEntry> _visibleByPackage = const {};
  Map<String, AppEntry> _byId = const {};
  Map<String, AppEntry> _byPackage = {};

  /// Notifier dedicated to the app list (installed, hidden, categories): the
  /// A-Z page listens only to this, not to context changes.
  final ValueNotifier<int> appsVersion = ValueNotifier(0);

  /// Cached Space predictions, keyed by context.
  String? _suggestionsKey;
  List<AppEntry> _suggestions = const [];

  AppEntry? byId(String id) => _byId[id];

  AppCategory categoryOf(AppEntry app) =>
      _categories[app.id]?.category ?? AppCategory.other;

  CategorySource? categorySourceOf(AppEntry app) => _categories[app.id]?.source;

  List<AppEntry> get favorites => [
    for (final id in settings.favorites)
      if (byId(id) case final a? when !_detoxHidden(a)) a,
  ];

  Map<String, double> _scores() {
    final visible = visibleApps;
    return predictor.scores(
      context.toMap(),
      now: _clock(),
      candidates: {for (final a in visible) a.packageName},
    );
  }

  /// The app for a package (its first launchable activity), hidden apps
  /// included: callers use it for labels and icons of any installed package.
  AppEntry? byPackage(String package) => _byPackage[package];

  /// The [n] most likely apps in the current Space (one activity per
  /// package).
  List<AppEntry> suggestions({int n = 5}) {
    visibleApps; // refreshes the caches
    final byPackage = _visibleByPackage;
    // Same context, same launches, same hour: same answer.
    final key = [
      context.key,
      spaceOverride?.name,
      predictor.totalLaunches,
      _visibleKey,
      boosts.keys.map((c) => c.name).join(','),
      n,
      _clock().hour,
    ].join('|');
    if (key == _suggestionsKey) return _suggestions;
    final features = context.toMap();
    // Manually picked Space: predictions follow that Space.
    switch (spaceOverride) {
      case null:
        break;
      case final SpaceKind k when k.slot != null:
        features['slot'] = k.slot!.name;
      case SpaceKind.home:
        features['place'] = 'home';
      case SpaceKind.work:
        features['place'] = 'work';
      case SpaceKind.travel:
        features['place'] = 'travel';
      case SpaceKind.moving:
        features['motion'] = 'driving';
      case SpaceKind.listening:
        features['audio'] = 'headphones';
      default:
        break;
    }
    final top = predictor.top(
      features,
      n: n,
      now: _clock(),
      candidates: byPackage.keys.toSet(),
    );
    final filled = _fillFromBoosted(top, n, byPackage.keys.toSet());
    _suggestionsKey = key;
    return _suggestions = [for (final p in filled) byPackage[p]!];
  }

  /// The [n] most used apps in the actual context (not the manually picked
  /// Space), for global search. If predictions fall short, fills up with the
  /// overall most used apps, then the boosted collections, then the dock.
  List<AppEntry> topForSearch(int n) {
    final byPackage = <String, AppEntry>{};
    for (final a in visibleApps) {
      byPackage.putIfAbsent(a.packageName, () => a);
    }
    final candidates = byPackage.keys.toSet();
    final out = <String>[
      ...predictor.top(
        context.toMap(),
        n: n,
        now: _clock(),
        candidates: candidates,
      ),
    ];
    if (out.length < n) {
      final habit =
          predictor
              .habit(now: _clock())
              .entries
              .where((e) => candidates.contains(e.key) && !out.contains(e.key))
              .toList()
            ..sort((a, b) => b.value.compareTo(a.value));
      out.addAll(habit.take(n - out.length).map((e) => e.key));
    }
    final boosted = _fillFromBoosted(out, n, candidates);
    out
      ..clear()
      ..addAll(boosted);
    for (final f in favorites) {
      if (out.length >= n) break;
      if (!out.contains(f.packageName)) out.add(f.packageName);
    }
    return [for (final p in out.take(n)) ?byPackage[p]];
  }

  /// Scores for the actual context, used to rank search results.
  Map<String, double> searchScores() =>
      predictor.scores(context.toMap(), now: _clock());

  List<CollectionGroup> get collections {
    final visible = visibleApps;
    return _collections.build(
      apps: visible,
      categoryOf: _visibleCategories,
      scores: _scores,
      contextKey: context.key,
      revision: _appsRevision * 100000 + settings.collectionsRevision,
      totalLaunches: predictor.totalLaunches,
      fixedOrder: settings.fixedCollectionOrder,
      pinned: settings.pinnedCategories,
      hidden: settings.hiddenCategories,
      boosts: boosts,
      force: _consumeForce(),
    );
  }

  bool _consumeForce() {
    final f = _forceCollections;
    _forceCollections = false;
    return f;
  }

  List<FeatureContribution> explain(AppEntry app) =>
      predictor.explain(app.packageName, context.toMap(), now: _clock());

  // --- Actions ---

  Future<void> launch(AppEntry app, {List<int>? bounds}) async {
    final now = _clock();
    final ctx = _contextNow();
    final record = LaunchRecord(
      ts: now,
      package: app.packageName,
      features: ctx.toMap(),
    );
    predictor.add(record);
    unawaited(store.insert(record));
    final ok = await bridge.launch(app.id, bounds: bounds);
    if (!ok) unawaited(refreshApps());
  }

  Future<void> openAppInfo(AppEntry app) => bridge.openAppInfo(app.id);

  Future<void> uninstall(AppEntry app) => bridge.uninstall(app.packageName);

  Future<void> clearHistory() async {
    await store.clear();
    predictor.clear();
    cardAffinity.clear();
    _cardKey = null;
    notifyListeners();
  }
}
