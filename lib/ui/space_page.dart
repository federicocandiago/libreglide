import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/time_context.dart';
import '../core/agenda.dart';
import '../core/space.dart';
import '../core/space_profile.dart';
import '../data/settings.dart';
import 'glide_style.dart';
import 'labels.dart';
import '../state/wallpaper_controller.dart';
import 'scope.dart';
import 'settings/space_cards_page.dart';
import 'space_cards.dart';
import 'widgets/app_icon.dart';
import 'widgets/wallpaper_photo.dart';

/// Current Space: date over the wallpaper, colored strip with the Space name,
/// action and app cards.
class SpacePage extends StatefulWidget {
  const SpacePage({super.key});

  @override
  State<SpacePage> createState() => _SpacePageState();
}

class _SpacePageState extends State<SpacePage>
    with AutomaticKeepAliveClientMixin {
  DateTime? _nextAlarm;
  bool? _isDefaultHome;
  StreamSubscription<void>? _resumeSub;

  @override
  bool get wantKeepAlive => true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_resumeSub == null) {
      final bridge = AppScope.of(context).controller.bridge;
      _resumeSub = bridge.resumed.listen((_) => _refresh());
      _refresh();
    }
  }

  @override
  void dispose() {
    _resumeSub?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    final bridge = AppScope.of(context).controller.bridge;
    try {
      final alarm = await bridge.nextAlarm();
      final isDefault = await bridge.isDefaultHome();
      if (!mounted) return;
      setState(() {
        _nextAlarm = alarm;
        _isDefaultHome = isDefault;
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final scope = AppScope.of(context);
    final controller = scope.controller;
    final settings = scope.settings;
    final c = GlideColors.of(context);
    final l = context.l10n;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return ListenableBuilder(
      listenable: Listenable.merge([
        controller,
        settings,
        controller.cards,
        controller.weather,
        controller.places,
      ]),
      builder: (context, _) {
        final kind = controller.currentSpace;
        final apps = controller.suggestions();
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _DateHeader(kind: kind)),
            SliverFillRemaining(
              hasScrollBody: false,
              child: ColoredBox(
                color: c.page,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(0, 0, 0, bottom + cardGap),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: cardGap),
                      if (!_evening(context, kind))
                        _padded(_ActionsCard(actions: _actionsFor(kind))),
                      ..._cards(
                        context,
                        kind,
                        appsCard: (FlatCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              CapsHeader(
                                icon: spaceIcon(kind),
                                label: l.nowAppsHeader,
                              ),
                              if (apps.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    14,
                                    0,
                                    14,
                                    16,
                                  ),
                                  child: Text(
                                    l.learningHint,
                                    style: TextStyle(color: c.muted),
                                  ),
                                )
                              else
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    8,
                                    0,
                                    8,
                                    6,
                                  ),
                                  child: Row(
                                    children: [
                                      for (final app in apps)
                                        Expanded(
                                          child: AppTile(
                                            app: app,
                                            // Names as in the Collections.
                                            showLabel:
                                                settings.collectionLabels,
                                          ),
                                        ),
                                      for (var i = apps.length; i < 5; i++)
                                        const Expanded(child: SizedBox()),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        )),
                      ),
                      if (_isDefaultHome == false)
                        _padded(
                          _Banner(
                            icon: Icons.home_rounded,
                            text: l.notDefaultBanner,
                            action: l.setAction,
                            onAction: controller.bridge.requestDefaultHome,
                          ),
                        ),
                      if (!settings.infoBannerDismissed)
                        _padded(
                          _Banner(
                            text: l.infoBanner,
                            onAction: settings.dismissInfoBanner,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// The Space's quick actions, from its profile (as in Glide, each Space has
  /// its own).
  List<(IconData, String, VoidCallback)> _actionsFor(SpaceKind kind) {
    final controller = AppScope.of(context).controller;
    final bridge = controller.bridge;
    final l = context.l10n;
    final home = controller.places.home;
    final work = controller.places.work;
    final out = <(IconData, String, VoidCallback)>[
      for (final a in profileFor(kind, workKind: controller.workKind).actions)
        ...switch (a) {
          QuickAction.alarm => [
            (Icons.alarm_rounded, l.actionAlarm, bridge.openAlarms),
          ],
          QuickAction.alarmTomorrow => [
            (Icons.alarm_add_rounded, l.actionAlarmTomorrow, bridge.openAlarms),
          ],
          QuickAction.dnd => [
            (
              Icons.do_not_disturb_on_outlined,
              l.actionDnd,
              bridge.openDoNotDisturb,
            ),
          ],
          QuickAction.newEvent => [
            (Icons.event_rounded, l.newEvent, bridge.newEvent),
          ],
          QuickAction.email => [
            (
              Icons.mail_rounded,
              l.actionEmail,
              () => bridge.openUrl('mailto:'),
            ),
          ],
          QuickAction.maps => [
            (Icons.map_rounded, l.actionMaps, () => bridge.navigateTo('')),
          ],
          QuickAction.toHome => [
            if (home != null)
              (
                Icons.home_rounded,
                l.actionToHome,
                () => bridge.navigateTo('${home.lat},${home.lon}'),
              ),
          ],
          QuickAction.toWork => [
            if (work != null)
              (
                Icons.work_rounded,
                l.actionToWork,
                () => bridge.navigateTo('${work.lat},${work.lon}'),
              ),
          ],
          QuickAction.timer => [
            (Icons.timer_outlined, l.actionTimer, bridge.openTimers),
          ],
          QuickAction.food => [
            (
              Icons.restaurant_rounded,
              l.actionFood,
              () => bridge.navigateTo(l.foodQuery),
            ),
          ],
        },
    ];
    // Without known places, "To home/work" give way to maps.
    if (out.isEmpty) {
      out.add((Icons.map_rounded, l.actionMaps, () => bridge.navigateTo('')));
    }
    return out;
  }

  /// In the evening and at night, the Good night card replaces the alarm.
  /// The Good night card replaces the quick actions in the evening, but not
  /// in the Spaces where you are out and about: there the actions (such as
  /// "Navigate home") matter more than the alarm for tomorrow.
  bool _evening(BuildContext context, SpaceKind kind) {
    const outAndAbout = {
      SpaceKind.nightOut,
      SpaceKind.moving,
      SpaceKind.exercise,
      SpaceKind.travel,
    };
    if (outAndAbout.contains(kind)) return false;
    final scope = AppScope.of(context);
    final slot = scope.controller.currentSlot;
    return scope.settings.eveningCard &&
        (slot == Slot.evening || slot == Slot.night);
  }

  /// The Space's cards: those that currently have something to show, ordered
  /// by the moment's profile, by usage (cards tapped in this context move up,
  /// and appear even where the profile doesn't include them) and by the
  /// "Hide / Always show here" choices.
  List<Widget> _cards(
    BuildContext context,
    SpaceKind kind, {
    required Widget appsCard,
  }) {
    final scope = AppScope.of(context);
    final settings = scope.settings;
    final controller = scope.controller;
    final cards = controller.cards;
    final profile = profileFor(kind, workKind: controller.workKind);
    // The real situation, or the one of the Space picked in the drawer.
    final situation = controller.situation;
    final headphones = situation.listening;
    final destination = settings.nextPlaceCard && cards.events != null
        ? nextDestination(DateTime.now(), cards.events!)
        : null;
    final parking = cards.parking;
    // At home or at work the car is usually right there: the saved spot is
    // not shown (the permission request still is).
    final showParking =
        settings.parkingCard &&
        !situation.driving &&
        (cards.parkingMissing.isNotEmpty ||
            (!situation.atHomeOrWork &&
                parking != null &&
                DateTime.now().difference(parking.at) <
                    const Duration(hours: 24)));
    final driving = settings.carCard && situation.driving;
    final rules = settings.cardRulesFor(kind);
    final agenda = cards.eventsLoaded ? cards.agenda() : null;
    // Empty agenda: only where the profile wants it (in the morning) or the
    // user pinned it here; without permission it stays, to ask for it.
    final showAgenda =
        settings.agendaCard &&
        cards.eventsLoaded &&
        (agenda == null ||
            agenda.events.isNotEmpty ||
            profile.agendaWhenEmpty ||
            rules[SpaceCard.agenda] == CardRule.show);
    final category = profile.category;

    final available = <SpaceCard, Widget>{
      if (driving) SpaceCard.car: CarCard(destination: destination),
      if (showParking) SpaceCard.parking: const ParkingCard(),
      if (_evening(context, kind))
        SpaceCard.evening: EveningCard(nextAlarm: _nextAlarm)
      else if (_nextAlarm != null)
        SpaceCard.alarm: _AlarmCard(time: _nextAlarm!),
      if (settings.mediaCard)
        if (cards.media != null)
          SpaceCard.media: MediaCard(media: cards.media)
        else if (!cards.mediaAccess && headphones)
          SpaceCard.media: const MediaCard(media: null),
      if (settings.travelCard && controller.travelling)
        SpaceCard.travel: const TravelCard(),
      if (destination != null && !driving)
        SpaceCard.nextPlace: NextPlaceCard(event: destination),
      if (showAgenda) SpaceCard.agenda: const AgendaCard(),
      if (settings.weatherCard)
        SpaceCard.weather: WeatherCard(tomorrow: profile.weatherTomorrow),
      SpaceCard.apps: appsCard,
      if (category != null && CategoryAppsCard.hasApps(controller, category))
        SpaceCard.category: CategoryAppsCard(category: category),
      if (settings.screenTime == ScreenTimePlace.space)
        SpaceCard.screenTime: const ScreenTimeCard(),
      if (settings.placesEnabled && controller.places.permission == false)
        SpaceCard.placesInvite: const PlacesInviteCard(),
    };
    final order = arrangeCards(
      profile: profile,
      available: available.keys,
      affinity: controller.cardScores(kind),
      usedHere: controller.cardUsedHere(kind),
      rules: rules,
    );
    final invite = order.remove(SpaceCard.placesInvite);
    return [
      for (final card in order)
        _padded(_CardShell(card: card, kind: kind, child: available[card]!)),
      // Android widgets stay at the bottom, in the chosen order.
      for (final w in settings.widgets) _padded(AppWidgetCard(widget: w)),
      if (invite) _padded(available[SpaceCard.placesInvite]!),
    ];
  }

  Widget _padded(Widget child) => Padding(
    padding: const EdgeInsets.fromLTRB(cardGap, 0, cardGap, cardGap),
    child: child,
  );
}

/// Day and date, centered over the phone's wallpaper.
class _DateHeader extends StatelessWidget {
  const _DateHeader({required this.kind});

  /// Current Space, shown in a pill above the day.
  final SpaceKind kind;

  static const double cardHeight = 168;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final now = DateTime.now();
    final c = GlideColors.of(context);
    const shadow = [Shadow(blurRadius: 10, color: Colors.black54)];
    // The page is opaque around the card: the wallpaper (or photo) shows only
    // inside it, so the date stays distinct while scrolling or changing
    // page.
    return CustomPaint(
      painter: _HolePainter(color: c.page),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(cardGap, cardGap, cardGap, 0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(cardRadius),
          child: SizedBox(
            height: cardHeight,
            child: Stack(
              children: [
                const Positioned.fill(
                  child: WallpaperPhoto(view: WallpaperView.space),
                ),
                // Light scrim to keep the date readable on any wallpaper.
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: Color(0x22000000)),
                  ),
                ),
                Positioned.fill(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _SpacePill(kind: kind),
                      const SizedBox(height: 12),
                      Text(
                        toBeginningOfSentenceCase(
                          DateFormat.EEEE(locale).format(now),
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w500,
                          shadows: shadow,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat.yMMMMd(locale).format(now),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w400,
                          shadows: shadow,
                        ),
                      ),
                    ],
                  ),
                ),
                const Positioned(
                  left: 4,
                  bottom: 0,
                  child: WallpaperCredit(view: WallpaperView.space),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints [color] over the whole area except a rounded rectangle (the date
/// card), through which the phone's wallpaper shows.
class _HolePainter extends CustomPainter {
  const _HolePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final outer = Path()..addRect(Offset.zero & size);
    final hole = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(cardGap, cardGap, size.width - cardGap, size.height),
          const Radius.circular(cardRadius),
        ),
      );
    canvas.drawPath(
      Path.combine(PathOperation.difference, outer, hole),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_HolePainter old) => old.color != color;
}

/// Pill with the current Space's color, icon and name; color and text
/// cross-fade when the Space changes.
class _SpacePill extends StatelessWidget {
  const _SpacePill({required this.kind});

  final SpaceKind kind;

  @override
  Widget build(BuildContext context) {
    final workKind = AppScope.of(context).controller.workKind;
    final color = GlideColors.of(context).spaceKind(kind);
    final onColor =
        ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white
        : Colors.black87;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.fromLTRB(12, 6, 16, 6),
      decoration: ShapeDecoration(
        color: color.withValues(alpha: 0.92),
        shape: const StadiumBorder(),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Row(
          key: ValueKey(kind),
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(spaceIcon(kind), color: onColor, size: 18),
            const SizedBox(width: 8),
            Text(
              spaceLabel(context.l10n, kind, workKind: workKind).toUpperCase(),
              maxLines: 1,
              textScaler: MediaQuery.textScalerOf(context)
                  .clamp(maxScaleFactor: maxLabelScale),
              style: TextStyle(
                color: onColor,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionsCard extends StatelessWidget {
  const _ActionsCard({required this.actions});

  /// (icon, label, action), side by side and separated by thin lines.
  final List<(IconData, String, VoidCallback)> actions;

  @override
  Widget build(BuildContext context) {
    final c = GlideColors.of(context);
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return FlatCard(
      child: Row(
        children: [
          for (final (i, (icon, label, onTap)) in actions.indexed) ...[
            if (i > 0) Container(width: 0.8, height: 60, color: c.hairline),
            Expanded(
              child: InkWell(
                onTap: onTap,
                child: SizedBox(
                  height: 60,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 22, color: onSurface),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AlarmCard extends StatelessWidget {
  const _AlarmCard({required this.time});

  final DateTime time;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final c = GlideColors.of(context);
    return FlatCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CapsHeader(icon: Icons.alarm_rounded, label: context.l10n.nextAlarm),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  DateFormat.Hm(locale).format(time),
                  style: TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.w400,
                    height: 1,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    toBeginningOfSentenceCase(
                      DateFormat.MMMEd(locale).format(time),
                    ),
                    style: TextStyle(color: c.muted, fontSize: 15),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Accent-colored banner with a button (check mark or text action).
class _Banner extends StatelessWidget {
  const _Banner({
    required this.text,
    required this.onAction,
    this.icon,
    this.action,
  });

  final String text;
  final VoidCallback onAction;
  final IconData? icon;
  final String? action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.primary,
      borderRadius: BorderRadius.circular(cardRadius),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(cardPadding, 16, 12, 16),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: scheme.onPrimary),
              const SizedBox(width: 14),
            ],
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: scheme.onPrimary,
                  fontSize: 15,
                  height: 1.35,
                ),
              ),
            ),
            const SizedBox(width: 12),
            if (action != null)
              TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(foregroundColor: scheme.onPrimary),
                child: Text(action!.toUpperCase()),
              )
            else
              IconButton(
                onPressed: onAction,
                color: scheme.onPrimary,
                iconSize: 34,
                icon: const Icon(Icons.check_circle_outline_rounded),
              ),
          ],
        ),
      ),
    );
  }
}

/// Wrapper for a Space card: counts taps (to learn which cards are useful at
/// which moment) and, on long press, offers "Hide in this Space" and "Always
/// show in this Space".
class _CardShell extends StatefulWidget {
  const _CardShell({
    required this.card,
    required this.kind,
    required this.child,
  });

  final SpaceCard card;
  final SpaceKind kind;
  final Widget child;

  @override
  State<_CardShell> createState() => _CardShellState();
}

class _CardShellState extends State<_CardShell> {
  Offset? _down;
  DateTime? _downAt;

  void _up(PointerUpEvent e) {
    final down = _down;
    final at = _downAt;
    _down = null;
    if (down == null || at == null) return;
    // A tap, not a scroll or a long press.
    if ((e.position - down).distance > 18) return;
    if (DateTime.now().difference(at) > const Duration(milliseconds: 600)) {
      return;
    }
    AppScope.of(context).controller.recordCardUse(widget.card, widget.kind);
  }

  Future<void> _menu() {
    final settings = AppScope.of(context).settings;
    final l = context.l10n;
    final rule = settings.cardRulesFor(widget.kind)[widget.card];
    final space = spaceLabel(
      l,
      widget.kind,
      workKind: AppScope.of(context).controller.workKind,
    );
    return showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (sheet) {
        void set(CardRule? r) {
          Navigator.pop(sheet);
          settings.setCardRule(widget.kind, widget.card, r);
        }

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
                child: Text(
                  '${spaceCardLabel(l, widget.card)} · $space'.toUpperCase(),
                  style: capsStyle(context),
                ),
              ),
              if (rule != CardRule.show)
                ListTile(
                  leading: const Icon(Icons.push_pin_outlined),
                  title: Text(l.cardShowHere),
                  onTap: () => set(CardRule.show),
                ),
              if (rule != CardRule.hide)
                ListTile(
                  leading: const Icon(Icons.visibility_off_outlined),
                  title: Text(l.cardHideHere),
                  onTap: () => set(CardRule.hide),
                ),
              if (rule != null)
                ListTile(
                  leading: const Icon(Icons.auto_awesome_rounded),
                  title: Text(l.cardAuto),
                  onTap: () => set(null),
                ),
              const Divider(indent: 24, endIndent: 24),
              ListTile(
                leading: const Icon(Icons.tune_rounded),
                title: Text(l.manageSpaceCards),
                onTap: () {
                  Navigator.pop(sheet);
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => SpaceCardsPage(kind: widget.kind),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: (e) {
      _down = e.position;
      _downAt = DateTime.now();
    },
    onPointerUp: _up,
    onPointerCancel: (_) => _down = null,
    child: GestureDetector(onLongPress: _menu, child: widget.child),
  );
}
