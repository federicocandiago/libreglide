/// Stato centrale del launcher: app installate, categorie, icone,
/// contesto corrente, previsioni e Collections.
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

/// Cache delle icone, separata dal controller così solo le icone si
/// ridisegnano quando arrivano.
class IconCache extends ChangeNotifier {
  IconCache(this._bridge);

  final LauncherBridge _bridge;
  final Map<String, AppIcon> _icons = {};
  final Set<String> _pending = {};
  int sizePx = 168;

  AppIcon? operator [](String id) => _icons[id];

  /// Carica le icone mancanti a blocchi, senza bloccare la UI.
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
        debugPrint('libreglide: icone non caricate: $e');
      } finally {
        _pending.removeAll(part);
      }
      notifyListeners();
    }
  }

  /// Dimentica le icone di un pacchetto (dopo un aggiornamento).
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

  /// Card dinamiche dello Space (Agenda, In ascolto).
  final CardsController cards;

  /// Pannello contatti (swipe verso l'alto).
  final ContactsController contacts;

  /// Card Meteo (facoltativa).
  final WeatherController weather;

  /// Luoghi: casa, lavoro, frequenti (facoltativo, posizione precisa).
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

  // region Card dello Space
  final CardAffinity cardAffinity = CardAffinity();
  String? _cardKey;
  Map<SpaceCard, double> _cardScores = const {};

  /// Un tocco su una card: la ricorda con il contesto attuale.
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

  /// Affinità delle card nel contesto attuale. Si ricalcola solo quando il
  /// contesto (o lo Space) cambia: toccare una card non sposta le altre
  /// mentre guardi la pagina.
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
      debugPrint('libreglide: tocchi sulle card non disponibili: $e');
    }
  }
  // endregion

  // region Cronologia di utilizzo di Android
  static const _usageMarker = 'usageImportedUntil';
  bool _importing = false;
  bool _learnFromUsage = true;
  DateTime? _lastImport;

  /// Accesso ai dati di utilizzo (null = non ancora controllato).
  bool? usageAccess;

  /// Aggiunge al predittore le app aperte fuori da libreGLIDE (notifiche,
  /// recenti, link…), lette dalla cronologia di Android: la prima volta le
  /// ultime 2 settimane, poi solo le nuove. Le aperture fatte da libreGLIDE
  /// non vengono contate due volte. Di queste si conoscono solo ora e
  /// giorno: rete, luogo e audio restano sconosciuti.
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
      debugPrint('libreglide: cronologia di utilizzo non disponibile: $e');
    } finally {
      _importing = false;
    }
  }

  /// Dimentica le aperture importate dalla cronologia di Android.
  Future<void> forgetUsage() async {
    await store.deleteSource('usage');
    await store.deleteKv(_usageMarker);
    predictor
      ..clear()
      ..addAll(await store.loadAndPrune(now: _clock()));
    _lastImport = null;
    notifyListeners();
  }

  /// Aperture salvate per origine (`launcher`, `usage`).
  Future<Map<String, int>> launchSources() => store.countBySource();
  // endregion

  // region Digital detox
  /// Le app bloccate sono nascoste adesso (detox acceso, opzione attiva e
  /// dentro l'orario).
  bool detoxHiding = false;
  Timer? _detoxTimer;
  String? _detoxSyncKey;

  /// Allinea la parte nativa (che fa il blocco vero e proprio) e decide se
  /// nascondere le app bloccate; si ripete al prossimo cambio di orario.
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
  // endregion

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
      debugPrint('libreglide: elenco app non disponibile: $e');
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

  /// Ultimi segnali letti dal sistema (rete, cuffie, ricarica).
  Map<String, Object?> _snapshot = const {};

  ContextFeatures _contextNow() => ContextFeatures.at(
    _clock(),
    network: _snapshot['network'] as String?,
    audio: _snapshot['audio'] as String?,
    motion: _snapshot['car'] == true ? 'driving' : null,
    place: _placeFeature(),
  );

  /// Luogo per il predittore: `home`, `work`, `frequent:ID`, `other`, `travel`.
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

  /// In auto: Android Auto o autoradio Bluetooth (con il permesso).
  bool get driving => _snapshot['car'] == true;

  /// Livello della batteria (0–100), se noto.
  int? get batteryLevel => (_snapshot['battery'] as num?)?.toInt();
  bool get charging => _snapshot['charging'] == true;

  /// Non disturbare attivo.
  bool get doNotDisturb => _snapshot['dnd'] == true;

  /// Fuso orario attuale (es. "Europe/Rome").
  String? get timeZone => _snapshot['tz'] as String?;

  /// Scarto dall'UTC del fuso di casa, letto quando si è in viaggio.
  Duration? homeOffset;

  /// Ora di casa, se si è in un altro fuso.
  DateTime? get homeTime {
    final offset = homeOffset;
    if (offset == null) return null;
    final t = _clock().toUtc().add(offset);
    // Ora "di parete" di casa, da mostrare così com'è.
    return DateTime(t.year, t.month, t.day, t.hour, t.minute);
  }

  /// "Ora vivo qui": il fuso attuale diventa quello di casa.
  void setHomeHere() {
    final tz = timeZone;
    if (tz == null) return;
    settings.setHomeTimeZone(tz);
    homeOffset = null;
    notifyListeners();
  }

  /// In viaggio: roaming, o fuso orario diverso da quello di casa (il
  /// primo visto). In futuro anche la città, con i luoghi (M1).
  bool get travelling {
    if (_snapshot['roaming'] == true) return true;
    if (places.farFromHome) return true;
    final tz = _snapshot['tz'] as String?;
    final home = settings.homeTimeZone;
    return tz != null && home != null && tz != home;
  }

  /// Rilegge i segnali dal sistema e aggiorna il contesto.
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
      debugPrint('libreglide: segnali di contesto non disponibili: $e');
    }
    unawaited(places.sample());
    final contextBefore = context.key;
    updateContext();
    // Batteria, Non disturbare, fuso e roaming non cambiano il contesto ma
    // servono alle card dello Space.
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

  /// Ricalcola il contesto; se è cambiato le Collections possono riordinarsi
  /// e la scelta manuale dello Space decade.
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

  /// Spinte iniziali attive adesso, per categoria.
  Map<AppCategory, double> get boosts => activeBoosts(_boosts, _clock());

  /// Raccolte preferite scelte nell'onboarding: partono in cima e ci restano
  /// per le prime settimane, poi lasciano spazio all'uso reale.
  Future<void> setFavoriteCategories(List<AppCategory> categories) async {
    final now = _clock();
    // La prima scelta pesa un filo di più, per mantenere l'ordine scelto.
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

  /// Dock proposto all'inizio: telefono, messaggi, fotocamera, browser
  /// (i primi installati tra i pacchetti noti).
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

  /// Categorie preferite scelte (anche se la spinta è esaurita).
  List<AppCategory> get favoriteCategories => [
    for (final b in _boosts) b.category,
  ];

  /// Completa [packages] fino a [n] con le app delle raccolte spinte, per i
  /// primi giorni in cui le previsioni sono poche.
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

  /// Space scelto a mano dal cassetto; null = quello del contesto.
  SpaceKind? spaceOverride;

  /// Space del contesto: auto, cuffie, viaggio, lavoro, casa, ora.
  SpaceKind get contextSpace => selectSpace(
    slot: context.slot,
    place: places.currentRole,
    driving: driving,
    audio: context.audio,
    travelling: travelling,
  );

  /// Space mostrato: quello scelto a mano o quello del contesto.
  SpaceKind get currentSpace => spaceOverride ?? contextSpace;

  /// Fascia oraria da usare per le card legate all'ora (Buonanotte…).
  Slot get currentSlot => spaceOverride?.slot ?? context.slot;

  void chooseSpace(SpaceKind? kind) {
    spaceOverride = kind == contextSpace ? null : kind;
    notifyListeners();
  }

  // region Lettura
  List<AppEntry> get allApps => _all;

  /// App mostrate: senza le nascoste e, se richiesto, senza quelle di sistema.
  /// App mostrate: senza le nascoste e, se richiesto, senza quelle di
  /// sistema. In cache finché non cambiano app o impostazioni delle app.
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

  /// Avviso dedicato all'elenco delle app (installate, nascoste, categorie):
  /// la pagina A-Z ascolta solo questo, non i cambi di contesto.
  final ValueNotifier<int> appsVersion = ValueNotifier(0);

  /// Previsioni dello Space in cache, per chiave di contesto.
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

  /// L'app di un pacchetto (la prima activity avviabile), se visibile.
  AppEntry? byPackage(String package) => _byPackage[package];

  /// Le [n] app più probabili nello Space corrente (una sola activity per
  /// pacchetto).
  List<AppEntry> suggestions({int n = 5}) {
    visibleApps; // aggiorna le cache
    final byPackage = _visibleByPackage;
    // Stesso contesto, stesse aperture, stessa ora: stessa risposta.
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
    // Space scelto a mano: le previsioni seguono quello Space.
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

  /// Le [n] app più usate nel contesto reale (non nello Space scelto a
  /// mano), per la ricerca globale. Se le previsioni non bastano completa
  /// con le più usate in assoluto e poi con il dock.
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

  /// Punteggi del contesto reale per ordinare i risultati di ricerca.
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
  // endregion

  // region Azioni
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
  // endregion
}
