import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_entry.dart';
import '../data/settings.dart';
import '../platform/launcher_bridge.dart';
import 'glide_style.dart';
import 'gestures.dart';
import 'labels.dart';
import '../state/wallpaper_controller.dart';
import 'scope.dart';
import 'settings/widgets_page.dart';
import 'space_cards.dart';
import 'widgets/app_actions.dart';
import 'widgets/app_icon.dart';
import 'widgets/wallpaper_photo.dart';

/// Home (the time-of-day tab): the phone's wallpaper and, at the bottom, the
/// white dock with a single row of 4 apps.
class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.onOpenSettings});

  final VoidCallback onOpenSettings;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with AutomaticKeepAliveClientMixin {
  /// Home widgets edit mode.
  bool _editing = false;

  @override
  bool get wantKeepAlive => true;

  Future<void> _menu() {
    final settings = AppScope.of(context).settings;
    final l = context.l10n;
    final canAdd =
        settings.homeWidgets.length < SettingsController.maxHomeWidgets;
    return showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.widgets_rounded),
              title: Text(l.addWidget),
              subtitle: canAdd
                  ? null
                  : Text(l.homeWidgetsFull(SettingsController.maxHomeWidgets)),
              enabled: canAdd,
              onTap: () {
                Navigator.pop(sheet);
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const WidgetProvidersPage(home: true),
                  ),
                );
              },
            ),
            if (settings.homeWidgets.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.edit_rounded),
                title: Text(l.editHome),
                onTap: () {
                  Navigator.pop(sheet);
                  setState(() => _editing = true);
                },
              ),
            ListTile(
              leading: const Icon(Icons.settings_rounded),
              title: Text(l.settingsTitle),
              onTap: () {
                Navigator.pop(sheet);
                widget.onOpenSettings();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final settings = AppScope.of(context).settings;
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) => _build(context, settings),
    );
  }

  Widget _build(BuildContext context, SettingsController settings) {
    final list = settings.homeWidgets;
    if (list.isEmpty && _editing) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => mounted ? setState(() => _editing = false) : null,
      );
    }
    return Stack(
      children: [
        const Positioned.fill(child: WallpaperPhoto(view: WallpaperView.home)),
        Column(
          children: [
            Expanded(
              // The detector sits ABOVE the widgets: vertical swipes and long
              // press work on widgets too (swiping between pages is handled
              // by the PageView); taps go through to the widget.
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onLongPress: _editing ? null : _menu,
                onTap: _editing ? () => setState(() => _editing = false) : null,
                // Vertical swipes: by default contacts on swipe down and
                // search on swipe up (configurable).
                onVerticalDragEnd: (d) {
                  if (_editing) return;
                  final v = d.primaryVelocity ?? 0;
                  if (v > 300) {
                    runGesture(
                      context,
                      settings.swipeDown,
                      SwipeDirection.down,
                    );
                  }
                  if (v < -300) {
                    runGesture(context, settings.swipeUp, SwipeDirection.up);
                  }
                },
                child: Stack(
                  children: [
                    // Transparent surface: the empty wallpaper area receives
                    // gestures too.
                    const Positioned.fill(
                      child: ColoredBox(color: Colors.transparent),
                    ),
                    // The wallpaper seen through a window with rounded
                    // corners, framed by the bar at the top and the tray at
                    // the bottom. (The shell draws the top corners, below the
                    // fixed bar; these follow the tray.)
                    if (settings.dockStyle == DockStyle.tray &&
                        settings.homeCorners)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: FrameCornersPainter(
                              bottom: solidBarColor(context),
                            ),
                          ),
                        ),
                      ),
                    // Widgets, top to bottom.
                    Positioned(
                      left: 0,
                      right: 0,
                      top: cardGap,
                      child: Column(
                        children: [
                          for (final (i, w) in list.indexed)
                            _HomeWidget(
                              key: ValueKey(w.id),
                              widget: w,
                              editing: _editing,
                              first: i == 0,
                              last: i == list.length - 1,
                            ),
                        ],
                      ),
                    ),
                    const Positioned(
                      left: 8,
                      bottom: 4,
                      child: WallpaperCredit(view: WallpaperView.home),
                    ),
                    if (settings.screenTime == ScreenTimePlace.home)
                      const Positioned(
                        right: cardGap,
                        bottom: cardGap,
                        child: ScreenTimePill(),
                      ),
                    if (_editing)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: cardGap,
                        child: Center(
                          child: FilledButton.icon(
                            onPressed: () => setState(() => _editing = false),
                            icon: const Icon(Icons.check_rounded),
                            label: Text(context.l10n.done),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const _Dock(),
          ],
        ),
      ],
    );
  }
}

/// An Android widget on Home, full width from the top. In edit mode a scrim
/// with the controls covers the widget (which would otherwise grab the
/// taps).
class _HomeWidget extends StatelessWidget {
  const _HomeWidget({
    super.key,
    required this.widget,
    required this.editing,
    required this.first,
    required this.last,
  });

  final PlacedWidget widget;
  final bool editing;
  final bool first;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final settings = scope.settings;
    final l = context.l10n;
    const row = SettingsController.homeRowHeight;
    final rows = (widget.height / row).round().clamp(
      SettingsController.minHomeRows,
      SettingsController.maxHomeRows,
    );
    Widget tool(IconData icon, String tip, VoidCallback? onTap) =>
        IconButton.filledTonal(
          tooltip: tip,
          onPressed: onTap,
          icon: Icon(icon),
        );
    return Padding(
      padding: const EdgeInsets.fromLTRB(cardGap, 0, cardGap, cardGap),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(cardRadius),
        child: Stack(
          children: [
            AppWidgetHostView(widget: widget),
            if (editing)
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: 0.55),
                  child: Center(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        tool(
                          Icons.unfold_less_rounded,
                          l.widgetShorter,
                          rows > SettingsController.minHomeRows
                              ? () => settings.resizeWidget(
                                  widget.id,
                                  (rows - 1) * row,
                                  home: true,
                                )
                              : null,
                        ),
                        Text(
                          l.widgetRows(rows),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        tool(
                          Icons.unfold_more_rounded,
                          l.widgetTaller,
                          rows < SettingsController.maxHomeRows
                              ? () => settings.resizeWidget(
                                  widget.id,
                                  (rows + 1) * row,
                                  home: true,
                                )
                              : null,
                        ),
                        tool(
                          Icons.arrow_upward_rounded,
                          l.moveUp,
                          first
                              ? null
                              : () => settings.moveWidget(
                                  widget.id,
                                  -1,
                                  home: true,
                                ),
                        ),
                        tool(
                          Icons.arrow_downward_rounded,
                          l.moveDown,
                          last
                              ? null
                              : () => settings.moveWidget(
                                  widget.id,
                                  1,
                                  home: true,
                                ),
                        ),
                        tool(Icons.delete_outline_rounded, l.remove, () async {
                          await scope.controller.bridge.removeWidget(widget.id);
                          settings.removeWidget(widget.id, home: true);
                        }),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Home dock: 4 slots in an opaque full-width tray that extends below the
/// gesture bar; or (setting) just the icons over the wallpaper, with a light
/// dark gradient to keep them readable.
class _Dock extends StatelessWidget {
  const _Dock();

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final controller = scope.controller;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return ListenableBuilder(
      listenable: Listenable.merge([controller, scope.settings]),
      builder: (context, _) {
        final favorites = controller.favorites;
        final tray = scope.settings.dockStyle == DockStyle.tray;
        // Always 4 slots: the dock apps, then a "+" in each free slot.
        // Long-pressing an app lets the user drag it to another slot.
        final row = Row(
          children: [
            for (var i = 0; i < SettingsController.maxFavorites; i++)
              Expanded(
                child: _DockSlot(
                  index: i,
                  app: i < favorites.length ? favorites[i] : null,
                ),
              ),
          ],
        );
        // Icons centered between the tray edge and the system bar: the space
        // below is the bar's own (gestures or buttons).
        final padding = EdgeInsets.fromLTRB(
          8,
          tray ? 12 : 20,
          8,
          // As before: slightly above the system bar, easier to tap; the
          // tray grows a little and stays balanced.
          bottom > 0 ? bottom + 6 : 12,
        );
        if (tray) {
          return ColoredBox(
            color: solidBarColor(context),
            child: Padding(padding: padding, child: row),
          );
        }
        // Transparent dock: there is a dark gradient underneath, so the
        // system buttons (or the gesture bar) must be light.
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            systemNavigationBarColor: Colors.transparent,
            systemNavigationBarIconBrightness: Brightness.light,
            systemNavigationBarContrastEnforced: false,
          ),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x00000000), Color(0x47000000)],
              ),
            ),
            child: Padding(padding: padding, child: row),
          ),
        );
      },
    );
  }
}

/// A dock slot: accepts an app dragged from another slot.
class _DockSlot extends StatelessWidget {
  const _DockSlot({required this.index, required this.app});

  final int index;
  final AppEntry? app;

  @override
  Widget build(BuildContext context) {
    final settings = AppScope.of(context).settings;
    final scheme = Theme.of(context).colorScheme;
    return DragTarget<String>(
      onWillAcceptWithDetails: (d) => d.data != app?.id,
      onAcceptWithDetails: (d) => settings.moveFavorite(d.data, index),
      builder: (context, candidates, _) => AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: candidates.isEmpty
              ? Colors.transparent
              : scheme.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(cardRadius),
        ),
        child: app == null ? const _AddTile() : _DockApp(app: app!),
      ),
    );
  }
}

/// Dock app: tap to open; long press to drag it, or to show the app menu if
/// released without moving.
class _DockApp extends StatelessWidget {
  const _DockApp({required this.app});

  final AppEntry app;

  static const _iconSize = 54.0;

  @override
  Widget build(BuildContext context) {
    var travel = Offset.zero;
    final tile = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => launchFrom(context, app),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: AppIconView(app: app, size: _iconSize),
        ),
      ),
    );
    return Semantics(
      button: true,
      label: app.label,
      child: LongPressDraggable<String>(
        data: app.id,
        delay: const Duration(milliseconds: 400),
        dragAnchorStrategy: pointerDragAnchorStrategy,
        onDragStarted: () => travel = Offset.zero,
        onDragUpdate: (d) => travel += d.delta,
        onDragEnd: (d) {
          // Released almost where it was: a long press, not a move.
          if (!d.wasAccepted && travel.distance < 24 && context.mounted) {
            showAppActions(context, app);
          }
        },
        // The dragged icon stays centered under the finger.
        feedback: FractionalTranslation(
          translation: const Offset(-0.5, -0.5),
          child: Material(
            type: MaterialType.transparency,
            child: Transform.scale(
              scale: 1.12,
              child: AppIconView(app: app, size: _iconSize),
            ),
          ),
        ),
        childWhenDragging: Opacity(opacity: 0.25, child: tile),
        child: tile,
      ),
    );
  }
}

/// "+" tile to add an app to the dock.
class _AddTile extends StatelessWidget {
  const _AddTile();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final onPhoto =
        AppScope.of(context).settings.dockStyle == DockStyle.transparent;
    return Tooltip(
      message: context.l10n.addToDock,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => _pickApp(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Center(
            // Free slot: a borderless tonal circle the size of an icon.
            child: Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                // Over the wallpaper: translucent white, readable on any photo.
                color: onPhoto
                    ? Colors.white.withValues(alpha: 0.22)
                    : scheme.onSurface.withValues(alpha: 0.07),
              ),
              child: Icon(
                Icons.add_rounded,
                color: onPhoto ? Colors.white : scheme.onSurfaceVariant,
                size: 26,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _pickApp(BuildContext context) {
  final scope = AppScope.of(context);
  final settings = scope.settings;
  final apps = [
    for (final a in scope.controller.visibleApps)
      if (!settings.isFavorite(a.id)) a,
  ];

  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (sheetContext) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
            child: Text(
              context.l10n.addToDock.toUpperCase(),
              style: capsStyle(context),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              itemCount: apps.length,
              itemBuilder: (context, i) => _PickRow(
                app: apps[i],
                onTap: () {
                  Navigator.pop(sheetContext);
                  settings.setFavorite(apps[i].id, true);
                },
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _PickRow extends StatelessWidget {
  const _PickRow({required this.app, required this.onTap});

  final AppEntry app;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: AppIconView(app: app, size: 40),
    title: Text(app.label),
    onTap: onTap,
  );
}
