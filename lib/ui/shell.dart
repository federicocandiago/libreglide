import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../core/space.dart';
import '../data/settings.dart';
import '../core/time_context.dart';
import 'all_apps_page.dart';
import 'glide_style.dart';
import 'collections_page.dart';
import 'home_page.dart';
import 'labels.dart';
import 'contacts_page.dart';
import 'gestures.dart';
import 'scope.dart';
import 'search_page.dart';
import 'settings/detox_page.dart';
import 'settings/colors_page.dart';
import 'settings/diagnostics_page.dart';
import 'onboarding_page.dart';
import 'perf_probe.dart';
import 'settings/hidden_page.dart';
import 'settings/legal_pages.dart';
import 'settings/settings_page.dart';
import 'settings/space_cards_page.dart';
import 'space_page.dart';
import 'widgets/rows_icon.dart';

/// Pages, in Glide's order: Space ← Home (time) → Collections → A-Z.
enum LauncherTab { space, home, collections, allApps }

/// Launcher layout: tab bar at the top, Spaces drawer on the left, swipeable
/// pages.
class LauncherShell extends StatefulWidget {
  const LauncherShell({super.key});

  @override
  State<LauncherShell> createState() => _LauncherShellState();
}

class _LauncherShellState extends State<LauncherShell> {
  final _pages = PageController(initialPage: LauncherTab.home.index);
  final _scaffold = GlobalKey<ScaffoldState>();

  /// Incremented on every "go home": pages collapse expanded cards and clear
  /// the search.
  final ValueNotifier<int> _homeSignal = ValueNotifier(0);

  /// Per page: whether the content is scrolled (the bar gets a tint).
  final List<ValueNotifier<bool>> _scrolled = List.generate(
    LauncherTab.values.length,
    (_) => ValueNotifier(false),
  );
  final ValueNotifier<double> _page = ValueNotifier(
    LauncherTab.home.index.toDouble(),
  );
  StreamSubscription<void>? _homeSub;
  StreamSubscription<String>? _openSub;

  @override
  void initState() {
    super.initState();
    _pages.addListener(() => _page.value = _pages.page ?? _page.value);
    // First run: onboarding as a modal over Home.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !AppScope.of(context).settings.onboardingDone) {
        showOnboarding(context, dismissible: false);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _homeSub ??= AppScope.of(context).controller.bridge.homePressed
        .listen((_) => _goHome());
    _openSub ??= AppScope.of(context).controller.bridge.openRequests
        .listen(_open);
    if (_glassListenable == null) {
      final scope = AppScope.of(context);
      _glassListenable = Listenable.merge([
        scope.settings,
        scope.wallpaper,
        _page,
      ])..addListener(_syncGlass);
      _syncGlass();
    }
  }

  // --- Frosted glass ---

  Listenable? _glassListenable;
  bool _glassOn = false;
  double _blur = -1;

  /// System blur only away from Home, and only without the Unsplash Home
  /// photo (which already has its own blurred version behind the pages).
  void _syncGlass() {
    final scope = AppScope.of(context);
    final bridge = scope.controller.bridge;
    final on = scope.settings.frostedGlass;
    if (on != _glassOn) {
      _glassOn = on;
      _blur = -1;
      bridge.setGlass(on);
    }
    final away = (_page.value - LauncherTab.home.index).abs() > 0.5;
    final target = on && away && scope.wallpaper.file == null ? 28.0 : 0.0;
    if (target != _blur) {
      _blur = target;
      bridge.setWindowBlur(target);
    }
  }

  @override
  void dispose() {
    _glassListenable?.removeListener(_syncGlass);
    _homeSub?.cancel();
    _openSub?.cancel();
    _pages.dispose();
    _homeSignal.dispose();
    for (final n in _scrolled) {
      n.dispose();
    }
    _page.dispose();
    super.dispose();
  }

  void _goHome() {
    Navigator.of(context).popUntil((r) => r.isFirst);
    _scaffold.currentState?.closeDrawer();
    FocusManager.instance.primaryFocus?.unfocus();
    _homeSignal.value++;
    goTo(LauncherTab.home);
  }

  /// Development command: opens a screen by name.
  void _open(String target) {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).popUntil((r) => r.isFirst);
    _scaffold.currentState?.closeDrawer();
    void push(Widget page) =>
        Navigator.of(context)
            .push(MaterialPageRoute<void>(builder: (_) => page));
    switch (target) {
      case 'home':
        goTo(LauncherTab.home);
      case 'space':
        goTo(LauncherTab.space);
      case 'collections':
        goTo(LauncherTab.collections);
      case 'az':
        goTo(LauncherTab.allApps);
      case 'search':
        showGlobalSearch(context);
      case 'contacts':
        showContactsPanel(context);
      case 'drawer':
        _scaffold.currentState?.openDrawer();
      case 'settings':
        push(const SettingsPage());
      case 'colors':
        push(const ColorsPage());
      case 'hidden':
        push(const HiddenPage());
      case 'diagnostics':
        push(const DiagnosticsPage());
      case 'theme:light':
        AppScope.of(context).settings.setThemeMode(ThemeMode.light);
      case 'theme:dark':
        AppScope.of(context).settings.setThemeMode(ThemeMode.dark);
      case 'theme:system':
        AppScope.of(context).settings.setThemeMode(ThemeMode.system);
      case 'about':
        push(const AboutPage());
      case final String t when t.startsWith('settings:'):
        final page = settingsSubPageFor(context, t.substring(9));
        if (page != null) push(page);
      case 'spacecards':
        push(const SpaceCardsListPage());
      case final String t when t.startsWith('spacecards:'):
        final kind = SpaceKind.values
            .where((k) => k.name == t.substring(11))
            .firstOrNull;
        if (kind != null) push(SpaceCardsPage(kind: kind));
      case final String t when t.startsWith('space:'):
        // Like picking a Space from the drawer ("auto" = automatic).
        final name = t.substring(6);
        AppScope.of(context).controller.chooseSpace(
          SpaceKind.values.where((k) => k.name == name).firstOrNull,
        );
        goTo(LauncherTab.space);
      case final String t when t.startsWith('lang:'):
        final code = t.substring(5);
        AppScope.of(context).settings
            .setLocale(code == 'system' ? null : Locale(code));
      case 'corners:on':
        AppScope.of(context).settings.setHomeCorners(true);
      case 'corners:off':
        AppScope.of(context).settings.setHomeCorners(false);
      case 'dock:tray':
        AppScope.of(context).settings.setDockStyle(DockStyle.tray);
      case 'dock:transparent':
        AppScope.of(context).settings.setDockStyle(DockStyle.transparent);
      case 'glass:on':
        AppScope.of(context).settings.setFrostedGlass(true);
      case 'glass:off':
        AppScope.of(context).settings.setFrostedGlass(false);
      case 'perf:start':
        PerfProbe.start();
      case final String t when t.startsWith('perf:report'):
        PerfProbe.report(t.length > 12 ? t.substring(12) : '');
      case 'detox':
        openDetox(context);
      case 'detox:lock':
        AppScope.of(context).controller.bridge.detoxPreview();
      case 'detox:apps':
        // With detox on, still go through the PIN.
        AppScope.of(context).settings.detoxEnabled
            ? openDetox(context)
            : push(const DetoxAppsPage());
      case 'privacy':
        push(const PrivacyPolicyPage());
      case 'licenses':
        push(const OpenSourcePage());
      case 'onboarding':
        showOnboarding(context);
    }
  }

  void goTo(LauncherTab tab) {
    if (!_pages.hasClients) return;
    if ((_pages.page ?? -1).round() == tab.index) return;
    _pages.animateToPage(
      tab.index,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void _openSettings() =>
      Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (_) => const SettingsPage()));

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goHome();
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: (dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
            .copyWith(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: Colors.transparent,
              systemNavigationBarContrastEnforced: false,
            ),
        child: Scaffold(
          key: _scaffold,
          backgroundColor: Colors.transparent,
          resizeToAvoidBottomInset: false,
          drawerScrimColor: Colors.black54,
          drawer: SpacesDrawer(
            onSelect: (kind) {
              _scaffold.currentState?.closeDrawer();
              AppScope.of(context).controller.chooseSpace(kind);
              goTo(LauncherTab.space);
            },
            onSettings: () {
              _scaffold.currentState?.closeDrawer();
              _openSettings();
            },
          ),
          body: _GlassPhoto(
            child: Column(
              children: [
                _TabBar(
                  page: _page,
                  scrolled: _scrolled,
                  onTab: goTo,
                  onMenu: () => _scaffold.currentState?.openDrawer(),
                ),
                Expanded(
                  child: _HomeFrame(
                    page: _page,
                    child: _GlassLayer(
                      child: PageView(
                        controller: _pages,
                        children: [
                          _ScrollWatch(
                            scrolled: _scrolled[0],
                            child: const SpacePage(),
                          ),
                          HomePage(onOpenSettings: _openSettings),
                          _ScrollWatch(
                            scrolled: _scrolled[2],
                            child: _PageBackground(
                              child: CollectionsPage(homeSignal: _homeSignal),
                            ),
                          ),
                          _ScrollWatch(
                            scrolled: _scrolled[3],
                            child: _PageBackground(
                              card: true,
                              child: AllAppsPage(homeSignal: _homeSignal),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tab bar: stripes (drawer), Space, time, Collections, A-Z.
class _TabBar extends StatelessWidget {
  const _TabBar({
    required this.page,
    required this.scrolled,
    required this.onTab,
    required this.onMenu,
  });

  final ValueNotifier<double> page;
  final List<ValueNotifier<bool>> scrolled;
  final ValueChanged<LauncherTab> onTab;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    final c = GlideColors.of(context);
    final controller = AppScope.of(context).controller;
    final l = context.l10n;
    final top = MediaQuery.paddingOf(context).top;

    return GestureDetector(
      // Swipe down on the bar: same as on Home.
      onVerticalDragEnd: (d) {
        if ((d.primaryVelocity ?? 0) > 300) {
          runGesture(
            context,
            AppScope.of(context).settings.swipeDown,
            SwipeDirection.down,
          );
        }
      },
      child: _BarSurface(
        page: page,
        scrolled: scrolled,
        child: Container(
          padding: EdgeInsets.only(top: top),
          height: top + tabBarHeight,
          child: Row(
            children: [
              SizedBox(
                width: 36,
                child: InkWell(
                  onTap: onMenu,
                  child: Tooltip(
                    message: l.spacesTitle,
                    child: const Center(child: _SpaceStripes()),
                  ),
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final tabWidth = constraints.maxWidth / 4;
                    return Stack(
                      children: [
                        Row(
                          children: [
                            _Tab(
                              tooltip: l.tabSpace,
                              onTap: () => onTab(LauncherTab.space),
                              child: ListenableBuilder(
                                listenable: controller,
                                builder: (context, _) {
                                  final kind = controller.currentSpace;
                                  // Make the Space change noticeable: the
                                  // new icon rotates and scales in.
                                  return AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 450),
                                    switchInCurve: Curves.easeOutBack,
                                    transitionBuilder: (child, anim) =>
                                        RotationTransition(
                                          turns: Tween(
                                            begin: -0.25,
                                            end: 0.0,
                                          ).animate(anim),
                                          child: ScaleTransition(
                                            scale: anim,
                                            child: child,
                                          ),
                                        ),
                                    child: Icon(
                                      spaceIcon(kind),
                                      key: ValueKey(kind),
                                      color: c.spaceKind(kind),
                                      size: 26,
                                    ),
                                  );
                                },
                              ),
                            ),
                            _Tab(
                              tooltip: l.pageHome,
                              onTap: () => onTab(LauncherTab.home),
                              child: _Tinted(
                                page: page,
                                index: LauncherTab.home.index,
                                from: Theme.of(context).colorScheme.onSurface,
                                builder: (color) => _TabLabel(color: color),
                              ),
                            ),
                            _Tab(
                              tooltip: l.tabCollections,
                              onTap: () => onTab(LauncherTab.collections),
                              child: _Tinted(
                                page: page,
                                index: LauncherTab.collections.index,
                                from: c.muted,
                                // Rows, like the full-width Collection cards.
                                builder: (color) =>
                                    RowsIcon(color: color, size: 26),
                              ),
                            ),
                            _Tab(
                              tooltip: l.tabAllApps,
                              onTap: () => onTab(LauncherTab.allApps),
                              child: _Tinted(
                                page: page,
                                index: LauncherTab.allApps.index,
                                from: c.muted,
                                builder: (color) => Icon(
                                  Icons.sort_by_alpha_rounded,
                                  color: color,
                                  size: 24,
                                ),
                              ),
                            ),
                          ],
                        ),
                        // Indicator under the active tab, follows the scroll.
                        ValueListenableBuilder<double>(
                          valueListenable: page,
                          builder: (context, p, _) => Positioned(
                            left: p * tabWidth + tabWidth * 0.2,
                            width: tabWidth * 0.6,
                            bottom: 0,
                            height: 3,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: c.accent,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tints the active tab with the accent color, blending while scrolling.
class _Tinted extends StatelessWidget {
  const _Tinted({
    required this.page,
    required this.index,
    required this.from,
    required this.builder,
  });

  final ValueNotifier<double> page;
  final int index;
  final Color from;
  final Widget Function(Color) builder;

  @override
  Widget build(BuildContext context) {
    final accent = GlideColors.of(context).accent;
    return ValueListenableBuilder<double>(
      valueListenable: page,
      builder: (context, p, _) {
        final t = (1 - (p - index).abs()).clamp(0.0, 1.0);
        return builder(Color.lerp(from, accent, t)!);
      },
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.child, required this.onTap, required this.tooltip});

  final Widget child;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        child: Center(child: child),
      ),
    ),
  );
}

/// The three colored stripes that open the Spaces drawer.
class _SpaceStripes extends StatelessWidget {
  const _SpaceStripes();

  @override
  Widget build(BuildContext context) {
    final c = GlideColors.of(context);
    final colors = [
      c.space(Slot.morning),
      c.space(Slot.afternoon),
      c.space(Slot.evening),
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (i, color) in colors.indexed)
          Container(
            // Thin, staggered stripes with muted colors: noticeable without
            // drawing the eye.
            width: 12.0 - i * 2,
            height: 2,
            margin: const EdgeInsets.symmetric(vertical: 1.5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
      ],
    );
  }
}

/// Label of the Home tab: today's date in the short local format, or the
/// local weather (icon and degrees) when chosen in settings and the Weather
/// card is on. Falls back to the date while there is no forecast.
class _TabLabel extends StatefulWidget {
  const _TabLabel({required this.color});

  final Color color;

  @override
  State<_TabLabel> createState() => _TabLabelState();
}

class _TabLabelState extends State<_TabLabel> {
  Timer? _midnight;

  @override
  void initState() {
    super.initState();
    _schedule();
  }

  /// Refreshes the date right after midnight.
  void _schedule() {
    final now = DateTime.now();
    final next = DateTime(now.year, now.month, now.day + 1, 0, 0, 5);
    _midnight = Timer(next.difference(now), () {
      if (!mounted) return;
      // The date is read in build; this only triggers the rebuild.
      setState(() {});
      _schedule();
    });
  }

  @override
  void dispose() {
    _midnight?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final weather = scope.controller.weather;
    return ListenableBuilder(
      listenable: Listenable.merge([scope.settings, weather]),
      builder: (context, _) {
        final w = weather.weather;
        final showWeather =
            scope.settings.homeTabLabel == HomeTabLabel.weather &&
            scope.settings.weatherCard &&
            w != null;
        final style = TextStyle(
          fontSize: 21,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
          color: widget.color,
        );
        final textScaler = MediaQuery.textScalerOf(context)
            .clamp(maxScaleFactor: maxLabelScale);
        final Widget label;
        if (showWeather) {
          label = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                weatherIcon(w.kind, isDay: w.isDay),
                color: widget.color,
                size: 22,
              ),
              const SizedBox(width: 4),
              Text(
                degrees(w.temperature),
                textScaler: textScaler,
                style: style,
              ),
            ],
          );
        } else {
          final locale = Localizations.localeOf(context).toLanguageTag();
          label = Text(
            DateFormat.MMMd(locale).format(DateTime.now()),
            textScaler: textScaler,
            style: style,
          );
        }
        // Long dates in some languages: shrink rather than overflow.
        return FittedBox(fit: BoxFit.scaleDown, child: label);
      },
    );
  }
}

/// Spaces drawer: dark, entries with colored icon and name.
class SpacesDrawer extends StatelessWidget {
  const SpacesDrawer({
    super.key,
    required this.onSelect,
    required this.onSettings,
  });

  /// Chosen Space; null = automatic (follows the context).
  final ValueChanged<SpaceKind?> onSelect;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final c = GlideColors.of(context);
    final scope = AppScope.of(context);
    final controller = scope.controller;
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    // Drawer row: icon in a circle of the Space's color, name, tinted pill
    // selection (Android 17), "now" badge on the context Space.
    Widget row({
      required IconData icon,
      required Color color,
      required String label,
      required VoidCallback onTap,
      bool selected = false,
      String? badge,
    }) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: Material(
        color: selected ? color.withValues(alpha: 0.16) : Colors.transparent,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 52,
            child: Row(
              children: [
                const SizedBox(width: 10),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: selected ? 1 : 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: selected
                        ? (ThemeData.estimateBrightnessForColor(color) ==
                                  Brightness.dark
                              ? Colors.white
                              : Colors.black87)
                        : color,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
                if (badge != null)
                  Container(
                    margin: const EdgeInsets.only(right: 14),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badge,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSecondaryContainer,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    Widget group(String title, List<Widget> rows) => Padding(
      padding: const EdgeInsets.fromLTRB(cardGap, 0, cardGap, cardGap),
      child: FlatCard(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(cardPadding, 14, 16, 6),
                child: Text(title.toUpperCase(), style: capsStyle(context)),
              ),
              ...rows,
            ],
          ),
        ),
      ),
    );

    return Drawer(
      backgroundColor: c.page,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(
          right: Radius.circular(sheetRadius),
        ),
      ),
      width: 304,
      child: SafeArea(
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            final current = controller.currentSpace;
            final automatic = controller.spaceOverride == null;
            final auto = controller.contextSpace;
            Widget spaceRow(SpaceKind kind) => row(
              icon: spaceIcon(kind),
              color: c.spaceKind(kind),
              label: spaceLabel(l, kind, workKind: scope.controller.workKind),
              selected: !automatic && current == kind,
              badge: kind == auto ? l.spaceNow : null,
              onTap: () => onSelect(kind),
            );
            return ListView(
              padding: const EdgeInsets.only(top: 12, bottom: 16),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
                  child: Text(
                    l.spacesTitle.toUpperCase(),
                    style: thinTitleStyle(color: scheme.onSurface, size: 22),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    cardGap,
                    0,
                    cardGap,
                    cardGap,
                  ),
                  child: FlatCard(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        children: [
                          row(
                            icon: Icons.auto_awesome_rounded,
                            color: c.accent,
                            label: l.spaceAutomatic,
                            selected: automatic,
                            badge: automatic
                                ? spaceLabel(
                                    l,
                                    auto,
                                    workKind: scope.controller.workKind,
                                  )
                                : null,
                            onTap: () => onSelect(null),
                          ),
                          row(
                            icon: Icons.settings_rounded,
                            color: scheme.onSurfaceVariant,
                            label: l.settingsTitle,
                            onTap: onSettings,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                group(l.spacesPlaces, [
                  for (final kind in [SpaceKind.home, SpaceKind.work])
                    spaceRow(kind),
                ]),
                group(l.spacesContext, [
                  for (final kind in [
                    SpaceKind.moving,
                    SpaceKind.exercise,
                    SpaceKind.listening,
                    SpaceKind.travel,
                    SpaceKind.nightOut,
                  ])
                    spaceRow(kind),
                ]),
                group(l.spacesTime, [
                  for (final slot in Slot.values)
                    spaceRow(SpaceKind.ofSlot(slot)),
                ]),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Frosted-glass pages (if enabled): placed under the [Glass] context, which
/// makes backgrounds and cards translucent.
class _GlassLayer extends StatelessWidget {
  const _GlassLayer({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([
        scope.settings.appearance,
        scope.wallpaper,
        scope.controller.bridge.blurAvailable,
      ]),
      child: child,
      builder: (context, child) {
        if (!scope.settings.frostedGlass) return child!;
        return Glass(level: _glassLevel(scope), child: child!);
      },
    );
  }
}

int _glassLevel(AppScope scope) =>
    scope.wallpaper.file != null || scope.controller.bridge.blurAvailable.value
    ? 1
    : 2;

/// With glass and the Unsplash Home photo, its blurred version sits
/// behind everything (bar included). The blur comes for free: decoded at
/// 32 px and upscaled.
class _GlassPhoto extends StatelessWidget {
  const _GlassPhoto({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([
        scope.settings.appearance,
        scope.wallpaper,
      ]),
      child: child,
      builder: (context, child) {
        final file = scope.wallpaper.file;
        if (!scope.settings.frostedGlass || file == null) return child!;
        return Stack(
          fit: StackFit.expand,
          children: [
            Image.file(
              file,
              fit: BoxFit.cover,
              cacheWidth: 32,
              filterQuality: FilterQuality.high,
              gaplessPlayback: true,
              errorBuilder: (_, _, _) => const SizedBox.expand(),
            ),
            child!,
          ],
        );
      },
    );
  }
}

/// Page background, resolved inside the glass context (if enabled).
class _PageBackground extends StatelessWidget {
  const _PageBackground({required this.child, this.card = false});

  final Widget child;
  final bool card;

  @override
  Widget build(BuildContext context) {
    final c = GlideColors.of(context);
    return ColoredBox(color: card ? c.card : c.page, child: child);
  }
}

/// Reports whether the page is scrolled vertically (for the bar tint).
class _ScrollWatch extends StatelessWidget {
  const _ScrollWatch({required this.scrolled, required this.child});

  final ValueNotifier<bool> scrolled;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n.metrics.axis == Axis.vertical && n.depth == 0) {
            scrolled.value = n.metrics.extentBefore > 4;
          }
          return false;
        },
        child: child,
      );
}

/// Tab bar background. Opaque on Home; with glass it fades to glass while
/// swiping towards the other pages, following the finger. When the page below
/// is scrolled it takes an accent-colored tint, like Android 17's bars.
class _BarSurface extends StatelessWidget {
  const _BarSurface({
    required this.page,
    required this.scrolled,
    required this.child,
  });

  final ValueNotifier<double> page;
  final List<ValueNotifier<bool>> scrolled;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    final solid = GlideColors.of(context).card;
    return ListenableBuilder(
      listenable: Listenable.merge([
        page,
        ...scrolled,
        scope.settings.appearance,
        scope.wallpaper,
        scope.controller.bridge.blurAvailable,
      ]),
      child: child,
      builder: (context, child) {
        final p = page.value;
        final index = p.round().clamp(0, scrolled.length - 1);
        var base = solid;
        if (scope.settings.frostedGlass) {
          final glass = GlideColors.glassCard(scheme, _glassLevel(scope));
          final away = (p - LauncherTab.home.index).abs().clamp(0.0, 1.0);
          base = Color.lerp(solid, glass, away)!;
        }
        return TweenAnimationBuilder<double>(
          tween: Tween(end: scrolled[index].value ? 1 : 0),
          duration: const Duration(milliseconds: 220),
          child: child,
          builder: (context, t, child) => Material(
            color: Color.alphaBlend(
              scheme.primary.withValues(alpha: 0.08 * t),
              base,
            ),
            child: child,
          ),
        );
      },
    );
  }
}

/// Top corners of the window over the Home wallpaper, below the bar: they
/// stay fixed with the bar and fade out when leaving Home (if they scrolled
/// with the page, corner wedges would be seen moving under a fixed bar).
class _HomeFrame extends StatelessWidget {
  const _HomeFrame({required this.page, required this.child});

  final ValueNotifier<double> page;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final color = solidBarColor(context);
    final settings = AppScope.of(context).settings;
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        IgnorePointer(
          child: ListenableBuilder(
            listenable: Listenable.merge([page, settings]),
            builder: (context, _) {
              if (!settings.homeCorners) return const SizedBox.expand();
              final away = (page.value - LauncherTab.home.index).abs().clamp(
                0.0,
                1.0,
              );
              return CustomPaint(
                painter: FrameCornersPainter(
                  top: color.withValues(alpha: color.a * (1 - away)),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
